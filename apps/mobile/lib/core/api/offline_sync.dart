import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../storage/hive_storage.dart';

enum SyncItemStatus {
  pending,
  processing,
  completed,
  failed,
}

class OfflineSyncManager {
  final DioClient dioClient;
  final HiveStorage hiveStorage;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  OfflineSyncManager({required this.dioClient, required this.hiveStorage});

  /// Starts listening to connectivity changes and triggers sync when online
  void startListening() {
    _connectivitySubscription = dioClient.connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncQueue();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Iterates and replays cached offline actions securely
  Future<void> syncQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final queue = hiveStorage.getQueueItems();
    if (queue.isEmpty) {
      _isSyncing = false;
      return;
    }

    for (final item in queue) {
      final itemId = item['id']?.toString() ?? '';
      final retryCount = (item['retryCount'] as num?)?.toInt() ?? 0;

      // Poison pill eviction: if an item repeatedly fails 10 times, discard it
      // to avoid permanent queue blocking and resource exhaustion.
      if (retryCount >= 10) {
        await hiveStorage.removeQueueItem(itemId);
        continue;
      }
      
      // Implement Exponential Backoff: delay retry if item failed previously
      if (retryCount > 0) {
        final backoffMs = min(1000 * pow(2, retryCount).toInt(), 30000); // max 30s
        final itemAgeMs = DateTime.now().millisecondsSinceEpoch - (item['timestamp'] as num).toInt();
        if (itemAgeMs < backoffMs) {
          continue; // skip this run, retry next connection tick
        }
      }

      final idempotencyKey = item['idempotencyKey']?.toString() ?? itemId;
      if (idempotencyKey.isNotEmpty &&
          hiveStorage.isIdempotencyKeyCompleted(idempotencyKey)) {
        await hiveStorage.removeQueueItem(itemId);
        continue;
      }

      final success = await _processQueueItem(itemId, item);
      if (success) {
        if (idempotencyKey.isNotEmpty) {
          await hiveStorage.markIdempotencyKeyCompleted(idempotencyKey);
        }
        await hiveStorage.removeQueueItem(itemId);
      } else {
        await hiveStorage.incrementRetryCount(itemId);
        // STRICT FIFO ORDERING: Stop flushing the remaining queue on network/server failure
        // so later actions (e.g. Round 2 result or second match) never execute before earlier actions!
        break;
      }
    }

    _isSyncing = false;
  }

  /// Processes individual transaction with conflict resolution, /sync/queue envelope support, and replay safety
  Future<bool> _processQueueItem(String itemId, Map<String, dynamic> item) async {
    final String endpoint = item['endpoint']?.toString() ?? '/sync/queue';
    final String method = item['method']?.toString().toUpperCase() ?? 'POST';
    final String actionType = item['actionType']?.toString() ?? 'GENERIC_MUTATION';
    final Map<String, dynamic> rawPayload = Map<String, dynamic>.from(item['payload'] ?? {});
    final String idempotencyKey = item['idempotencyKey']?.toString() ?? itemId;

    // Idempotency and Replay Protection: pass item ID as request header/key
    rawPayload['idempotencyKey'] = idempotencyKey;
    rawPayload['offlineTimestamp'] = item['timestamp'];

    final Map<String, dynamic> requestBody = endpoint == '/sync/queue'
        ? <String, dynamic>{
            'idempotencyKey': idempotencyKey,
            'actionType': actionType,
            'payload': rawPayload,
          }
        : rawPayload;

    try {
      Response response;
      if (method == 'POST') {
        response = await dioClient.dio.post(
          endpoint,
          data: requestBody,
          options: Options(headers: {'X-Idempotency-Key': idempotencyKey}),
        );
      } else if (method == 'PUT') {
        response = await dioClient.dio.put(
          endpoint,
          data: requestBody,
          options: Options(headers: {'X-Idempotency-Key': idempotencyKey}),
        );
      } else if (method == 'PATCH') {
        response = await dioClient.dio.patch(
          endpoint,
          data: requestBody,
          options: Options(headers: {'X-Idempotency-Key': idempotencyKey}),
        );
      } else {
        response = await dioClient.dio.delete(
          endpoint,
          data: requestBody,
          options: Options(headers: {'X-Idempotency-Key': idempotencyKey}),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        return true;
      }

      // Conflict Resolution: if item already created or modified on server, resolve gracefully
      if (response.statusCode == 409) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      int? statusCode = e.response?.statusCode;
      if (e.error is ApiException) {
        statusCode = (e.error as ApiException).status;
      }

      // Fallback to unified /sync/queue endpoint if direct route returned 404/405
      if (endpoint != '/sync/queue' && (statusCode == 404 || statusCode == 405)) {
        try {
          final fallbackRes = await dioClient.dio.post(
            '/sync/queue',
            data: <String, dynamic>{
              'idempotencyKey': idempotencyKey,
              'actionType': actionType,
              'payload': rawPayload,
            },
            options: Options(headers: {'X-Idempotency-Key': idempotencyKey}),
          );
          if (fallbackRes.statusCode == 200 ||
              fallbackRes.statusCode == 201 ||
              fallbackRes.statusCode == 202 ||
              fallbackRes.statusCode == 409) {
            return true;
          }
        } catch (_) {}
      }

      // In case of client validation failure (400), unprocessable payload (422), or processed duplicate (409),
      // drop the item from the queue so unrecoverable mutations don't choke sync.
      if (statusCode != null &&
          (statusCode == 400 || statusCode == 422 || statusCode == 409)) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

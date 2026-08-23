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
      
      // Implement Exponential Backoff: delay retry if item failed previously
      if (retryCount > 0) {
        final backoffMs = min(1000 * pow(2, retryCount).toInt(), 30000); // max 30s
        final itemAgeMs = DateTime.now().millisecondsSinceEpoch - (item['timestamp'] as num).toInt();
        if (itemAgeMs < backoffMs) {
          continue; // skip this run, retry next connection tick
        }
      }

      final success = await _processQueueItem(itemId, item);
      if (success) {
        await hiveStorage.removeQueueItem(itemId);
      } else {
        await hiveStorage.incrementRetryCount(itemId);
      }
    }

    _isSyncing = false;
  }

  /// Processes individual transaction with conflict resolution and replay safety
  Future<bool> _processQueueItem(String itemId, Map<String, dynamic> item) async {
    final String endpoint = item['endpoint']?.toString() ?? '';
    final String method = item['method']?.toString() ?? 'POST';
    final Map<String, dynamic> payload = Map<String, dynamic>.from(item['payload'] ?? {});

    // Idempotency and Replay Protection: pass item ID as request header/key
    payload['idempotencyKey'] = itemId;
    payload['offlineTimestamp'] = item['timestamp'];

    try {
      Response response;
      if (method == 'POST') {
        response = await dioClient.dio.post(
          endpoint,
          data: payload,
          options: Options(headers: {'X-Idempotency-Key': itemId}),
        );
      } else if (method == 'PUT') {
        response = await dioClient.dio.put(
          endpoint,
          data: payload,
          options: Options(headers: {'X-Idempotency-Key': itemId}),
        );
      } else {
        response = await dioClient.dio.delete(
          endpoint,
          data: payload,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      
      // Conflict Resolution: if item already created or modified on server, resolve gracefully
      if (response.statusCode == 409) {
        // Resolve conflict gracefully (e.g. server data takes precedence or local is merged)
        return true; // resolve queue block
      }
      return false;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        final apiEx = e.error as ApiException;
        // In case of validation or semantic rejection, drop item to avoid deadlock block
        if (apiEx.status == 400 || apiEx.status == 422 || apiEx.status == 409) {
          return true; // Resolved (discard bad offline input state safely)
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

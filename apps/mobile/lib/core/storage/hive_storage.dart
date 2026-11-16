import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static const String _syncQueueBoxName = 'offline_sync_queue';
  static const String _cacheBoxName = 'local_data_cache';

  bool _isInitialized = false;
  late final Box<Map<dynamic, dynamic>> _syncQueueBox;
  late final Box<dynamic> _cacheBox;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _syncQueueBox = await Hive.openBox<Map<dynamic, dynamic>>(_syncQueueBoxName);
    _cacheBox = await Hive.openBox<dynamic>(_cacheBoxName);
    _isInitialized = true;
  }

  // Cache Operations
  Future<void> cacheData(String key, dynamic value) async {
    await _cacheBox.put(key, value);
  }

  dynamic getCachedData(String key) {
    return _cacheBox.get(key);
  }

  Future<void> evictCache(String key) async {
    await _cacheBox.delete(key);
  }

  /// Alias for evictCache for backward-compatibility with repository calls
  Future<void> deleteCachedData(String key) async {
    await evictCache(key);
  }

  /// Evicts all cached entries whose string keys start with [prefix].
  /// Used for targeted cache invalidation across admin mutations,
  /// session teardown, and role switching.
  Future<void> evictByPrefix(String prefix) async {
    final keysToDelete = <dynamic>[];
    for (final key in _cacheBox.keys) {
      if (key is String && key.startsWith(prefix)) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await _cacheBox.delete(key);
    }
  }

  Future<void> clearAllCaches() async {
    await _cacheBox.clear();
  }

  int _sequenceCounter = 0;
  static const String _completedIdempotencyCacheKey =
      'completed_sync_idempotency_keys_v1';
  final Set<String> _completedIdempotencyKeys = <String>{};

  static const Set<String> _coalescibleActionTypes = <String>{
    'SAVE_TOURNAMENT_DRAFT',
    'UPDATE_RELEASED_TOURNAMENT',
    'UPDATE_SPECTATOR_GATE_CONFIG',
  };

  Set<String> _loadCompletedIdempotencyKeys() {
    if (_completedIdempotencyKeys.isNotEmpty) {
      return _completedIdempotencyKeys;
    }
    if (!_isInitialized) return _completedIdempotencyKeys;
    try {
      final raw = _cacheBox.get(_completedIdempotencyCacheKey);
      if (raw is List) {
        _completedIdempotencyKeys.addAll(raw.map((e) => e.toString()));
      }
    } catch (_) {}
    return _completedIdempotencyKeys;
  }

  Future<void> markIdempotencyKeyCompleted(String idempotencyKey) async {
    if (idempotencyKey.trim().isEmpty) return;
    final set = _loadCompletedIdempotencyKeys();
    set.add(idempotencyKey.trim());
    if (_isInitialized) {
      try {
        await _cacheBox.put(_completedIdempotencyCacheKey, set.toList());
      } catch (_) {}
    }
  }

  bool isIdempotencyKeyCompleted(String idempotencyKey) {
    if (idempotencyKey.trim().isEmpty) return false;
    return _loadCompletedIdempotencyKeys().contains(idempotencyKey.trim());
  }

  // Sync Queue Operations (Strict Chronological FIFO + Idempotency Deduplication)
  Future<Map<String, dynamic>> enqueueAction({
    required String actionType,
    required String endpoint,
    required Map<String, dynamic> payload,
    required String method,
    String? idempotencyKey,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _sequenceCounter++;
    final resolvedIdempotencyKey = (idempotencyKey ??
            payload['idempotencyKey']?.toString() ??
            'idem_${actionType}_${timestamp}_$_sequenceCounter')
        .trim();

    // 1. Guard against already-completed non-coalescible idempotency keys
    if (!_coalescibleActionTypes.contains(actionType) &&
        isIdempotencyKeyCompleted(resolvedIdempotencyKey)) {
      return <String, dynamic>{
        'id': 'dedup_completed_$resolvedIdempotencyKey',
        'idempotencyKey': resolvedIdempotencyKey,
        'actionType': actionType,
        'endpoint': endpoint,
        'payload': payload,
        'method': method,
        'timestamp': timestamp,
        'sequence': _sequenceCounter,
        'retryCount': 0,
        'alreadyCompleted': true,
      };
    }

    // 2. Check if an item with the same idempotencyKey is already queued in the outbox
    if (_isInitialized) {
      for (final key in _syncQueueBox.keys) {
        final existing = _syncQueueBox.get(key);
        if (existing != null &&
            existing['idempotencyKey']?.toString() == resolvedIdempotencyKey) {
          final existingMap = Map<String, dynamic>.from(existing);
          if (_coalescibleActionTypes.contains(actionType)) {
            final updatedItem = <String, dynamic>{
              ...existingMap,
              'payload': {
                ...payload,
                'idempotencyKey': resolvedIdempotencyKey,
              },
            };
            await _syncQueueBox.put(existingMap['id'], updatedItem);
            return updatedItem;
          }
          // Non-coalescible action (e.g. referee result, athlete apply): return existing FIFO item without duplicating
          return existingMap;
        }
      }
    }

    final queueItem = <String, dynamic>{
      'id': '${actionType}_${timestamp}_$_sequenceCounter',
      'idempotencyKey': resolvedIdempotencyKey,
      'actionType': actionType,
      'endpoint': endpoint,
      'payload': {
        ...payload,
        'idempotencyKey': resolvedIdempotencyKey,
      },
      'method': method,
      'timestamp': timestamp,
      'sequence': _sequenceCounter,
      'retryCount': 0,
    };
    if (_isInitialized) {
      await _syncQueueBox.put(queueItem['id'], queueItem);
    }
    return queueItem;
  }

  List<Map<String, dynamic>> getQueueItems() {
    if (!_isInitialized) return const <Map<String, dynamic>>[];
    return _syncQueueBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) {
        final cmp = (a['timestamp'] as num).compareTo(b['timestamp'] as num);
        if (cmp != 0) return cmp;
        return ((a['sequence'] as num?) ?? 0).compareTo((b['sequence'] as num?) ?? 0);
      });
  }

  int getPendingQueueCount() {
    if (!_isInitialized) return 0;
    return _syncQueueBox.length;
  }

  Future<void> removeQueueItem(String id) async {
    if (!_isInitialized) return;
    await _syncQueueBox.delete(id);
  }

  Future<void> incrementRetryCount(String id) async {
    if (!_isInitialized) return;
    final item = _syncQueueBox.get(id);
    if (item != null) {
      final updated = Map<dynamic, dynamic>.from(item);
      updated['retryCount'] = ((updated['retryCount'] as num?)?.toInt() ?? 0) + 1;
      await _syncQueueBox.put(id, updated);
    }
  }

  Future<void> clearQueue() async {
    if (!_isInitialized) return;
    await _syncQueueBox.clear();
  }
}

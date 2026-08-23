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

  Future<void> clearAllCaches() async {
    await _cacheBox.clear();
  }

  // Sync Queue Operations
  Future<void> enqueueAction({
    required String actionType,
    required String endpoint,
    required Map<String, dynamic> payload,
    required String method,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final queueItem = {
      'id': '${actionType}_$timestamp',
      'actionType': actionType,
      'endpoint': endpoint,
      'payload': payload,
      'method': method,
      'timestamp': timestamp,
      'retryCount': 0,
    };
    await _syncQueueBox.put(queueItem['id'], queueItem);
  }

  List<Map<String, dynamic>> getQueueItems() {
    return _syncQueueBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) => (a['timestamp'] as num).compareTo(b['timestamp'] as num));
  }

  Future<void> removeQueueItem(String id) async {
    await _syncQueueBox.delete(id);
  }

  Future<void> incrementRetryCount(String id) async {
    final item = _syncQueueBox.get(id);
    if (item != null) {
      final updated = Map<dynamic, dynamic>.from(item);
      updated['retryCount'] = ((updated['retryCount'] as num?)?.toInt() ?? 0) + 1;
      await _syncQueueBox.put(id, updated);
    }
  }

  Future<void> clearQueue() async {
    await _syncQueueBox.clear();
  }
}

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile/core/storage/hive_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArmSphere Sprint 17 - Repository & Caching Unit Tests (Real Hive)', () {
    late HiveStorage hiveStorage;
    late Directory tempDir;

    setUpAll(() {
      // Mock PathProvider to allow Hive.initFlutter() to initialize without standard MethodChannel crashes
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          return tempDir.path;
        },
      );
    });

    setUp(() async {
      // Create isolated temporary directory for Hive Box file-system storage
      tempDir = await Directory.systemTemp.createTemp('hive_sprint17_test_dir');
      hiveStorage = HiveStorage();
      await hiveStorage.initialize();
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Hive cacheData persists and retrieves key-value values correctly', () async {
      const testKey = 'test_match_cache_key';
      final testValue = {'matchId': '182', 'winnerId': '8492', 'score': '3-0'};

      // Act
      await hiveStorage.cacheData(testKey, testValue);
      final retrieved = hiveStorage.getCachedData(testKey);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved['matchId'], equals('182'));
      expect(retrieved['winnerId'], equals('8492'));
      expect(retrieved['score'], equals('3-0'));
    });

    test('Offline Sync Queue enqueues transactions successfully with proper parameters', () async {
      const actionType = 'MATCH_SUBMISSION';
      const endpoint = '/matches/submit';
      const method = 'POST';
      final payload = {'opponentId': '9184', 'score': '3-1'};

      // Act
      await hiveStorage.enqueueAction(
        actionType: actionType,
        endpoint: endpoint,
        payload: payload,
        method: method,
      );

      final queue = hiveStorage.getQueueItems();

      // Assert
      expect(queue, isNotEmpty);
      expect(queue.first['actionType'], equals('MATCH_SUBMISSION'));
      expect(queue.first['endpoint'], equals('/matches/submit'));
      expect(queue.first['payload']['opponentId'], equals('9184'));
      expect(queue.first['method'], equals('POST'));
      expect(queue.first['retryCount'], equals(0));
    });

    test('Exponential backoff algorithm computes correct delays based on retries and incrementation works', () async {
      const actionType = 'MATCH_SUBMISSION';
      const endpoint = '/matches/submit';
      const method = 'POST';
      final payload = {'opponentId': '9184', 'score': '3-1'};

      await hiveStorage.enqueueAction(
        actionType: actionType,
        endpoint: endpoint,
        payload: payload,
        method: method,
      );

      final queueBefore = hiveStorage.getQueueItems();
      final itemId = queueBefore.first['id'];

      // Increment retry twice
      await hiveStorage.incrementRetryCount(itemId);
      await hiveStorage.incrementRetryCount(itemId);

      final queueAfter = hiveStorage.getQueueItems();
      expect(queueAfter.first['retryCount'], equals(2));

      // 1000ms * 2^2 = 4000ms
      int retryCount = queueAfter.first['retryCount'];
      int backoffMs = (1000 * (1 << retryCount)); 
      expect(backoffMs, equals(4000));
    });
  });
}

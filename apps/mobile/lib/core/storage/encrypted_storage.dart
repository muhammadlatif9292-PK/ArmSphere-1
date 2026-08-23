import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'secure_storage.dart';

class EncryptedStorage {
  final SecureStorage secureStorage;

  // Table names as boxes
  static const String boxUsers = 'encrypted_users';
  static const String boxAthleteProfiles = 'encrypted_athlete_profiles';
  static const String boxMatches = 'encrypted_matches';
  static const String boxTournaments = 'encrypted_tournaments';
  static const String boxNotifications = 'encrypted_notifications';
  static const String boxPendingActions = 'encrypted_pending_actions';
  static const String boxRankingsCache = 'encrypted_rankings_cache';

  // Current database schema version for migrations
  static const int currentSchemaVersion = 2;

  EncryptedStorage({required this.secureStorage});

  /// Initializes encrypted Hive boxes with secure encryption keys
  Future<void> initialize() async {
    await Hive.initFlutter();

    // 1. Fetch or generate a secure AES 256-bit cipher key
    final encryptionKey = await _getOrCreateEncryptionKey();

    // 2. Open all encrypted boxes with AES-256 cypher
    final cipher = HiveAesCipher(encryptionKey);
    await Hive.openBox<String>(boxUsers, encryptionCipher: cipher);
    await Hive.openBox<String>(boxAthleteProfiles, encryptionCipher: cipher);
    await Hive.openBox<String>(boxMatches, encryptionCipher: cipher);
    await Hive.openBox<String>(boxTournaments, encryptionCipher: cipher);
    await Hive.openBox<String>(boxNotifications, encryptionCipher: cipher);
    await Hive.openBox<String>(boxPendingActions, encryptionCipher: cipher);
    await Hive.openBox<String>(boxRankingsCache, encryptionCipher: cipher);

    // 3. Execute migrations if needed
    await _runSchemaMigrations();

    // 4. Run automatic cleanup of expired cached items
    await runAutomaticCleanup();
  }

  /// Fetches existing encryption key from Keychain/Keystore, or generates and
  /// persists a new robust 256-bit key on first run.
  Future<List<int>> _getOrCreateEncryptionKey() async {
    final savedKeyB64 = await secureStorage.getHiveEncryptionKey();
    if (savedKeyB64 != null) {
      return base64Decode(savedKeyB64);
    }

    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    await secureStorage.setHiveEncryptionKey(base64Encode(keyBytes));
    return keyBytes;
  }

  /// Runs database migrations between schema versions
  Future<void> _runSchemaMigrations() async {
    final metaBox = await Hive.openBox<int>('db_metadata');
    final lastVersion = metaBox.get('schema_version', defaultValue: 1) ?? 1;

    if (lastVersion < currentSchemaVersion) {
      if (lastVersion == 1) {
        // Migration 1 -> 2: Clear outdated caches or map structured changes
        await Hive.box<String>(boxRankingsCache).clear();
      }
      await metaBox.put('schema_version', currentSchemaVersion);
    }
  }

  /// Auto-clears cache items older than 30 days to limit space usage
  Future<void> runAutomaticCleanup() async {
    final matchBox = Hive.box<String>(boxMatches);
    final notificationBox = Hive.box<String>(boxNotifications);

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    // Filter and delete old logs or notifications
    await _cleanupBoxKeys(matchBox, thirtyDaysAgo);
    await _cleanupBoxKeys(notificationBox, thirtyDaysAgo);
  }

  Future<void> _cleanupBoxKeys(Box<String> box, int expiryTimestamp) async {
    final keysToDelete = <String>[];
    for (final key in box.keys) {
      final valStr = box.get(key);
      if (valStr != null) {
        try {
          final data = jsonDecode(valStr);
          final timestamp = data['timestamp'] as num?;
          if (timestamp != null && timestamp.toInt() < expiryTimestamp) {
            keysToDelete.add(key.toString());
          }
        } catch (_) {}
      }
    }
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  // Generic Read/Write operations for encrypted tables
  Future<void> save(String boxName, String key, Map<String, dynamic> data) async {
    final box = Hive.box<String>(boxName);
    data['cachedAt'] = DateTime.now().millisecondsSinceEpoch;
    await box.put(key, jsonEncode(data));
  }

  Map<String, dynamic>? get(String boxName, String key) {
    final box = Hive.box<String>(boxName);
    final str = box.get(key);
    if (str == null) return null;
    return Map<String, dynamic>.from(jsonDecode(str));
  }

  Future<void> evict(String boxName, String key) async {
    final box = Hive.box<String>(boxName);
    await box.delete(key);
  }

  Future<void> clearTable(String boxName) async {
    final box = Hive.box<String>(boxName);
    await box.clear();
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _biometricsEnabledKey = 'biometrics_enabled';
  static const String _sessionUserKey = 'session_user_data';
  static const String _hiveEncryptionKeyName = 'hive_encryption_key';

  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // Handle Android auto-backup BadPaddingException (Keystore key lost but encrypted prefs restored)
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      await _storage.write(key: key, value: value);
    }
  }

  Future<void> setHiveEncryptionKey(String base64Key) async {
    await _safeWrite(_hiveEncryptionKeyName, base64Key);
  }

  Future<String?> getHiveEncryptionKey() async {
    return await _safeRead(_hiveEncryptionKeyName);
  }

  Future<void> setAccessToken(String token) async {
    await _safeWrite(_accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    return await _safeRead(_accessTokenKey);
  }

  Future<void> setRefreshToken(String token) async {
    await _safeWrite(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return await _safeRead(_refreshTokenKey);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _safeWrite(_biometricsEnabledKey, enabled.toString());
  }

  Future<bool> getBiometricsEnabled() async {
    final value = await _safeRead(_biometricsEnabledKey);
    return value == 'true';
  }

  Future<void> setSessionUserData(String jsonStr) async {
    await _safeWrite(_sessionUserKey, jsonStr);
  }

  Future<String?> getSessionUserData() async {
    return await _safeRead(_sessionUserKey);
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _sessionUserKey);
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

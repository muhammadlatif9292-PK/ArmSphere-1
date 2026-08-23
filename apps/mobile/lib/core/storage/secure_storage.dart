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

  Future<void> setHiveEncryptionKey(String base64Key) async {
    await _storage.write(key: _hiveEncryptionKeyName, value: base64Key);
  }

  Future<String?> getHiveEncryptionKey() async {
    return await _storage.read(key: _hiveEncryptionKeyName);
  }

  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsEnabledKey, value: enabled.toString());
  }

  Future<bool> getBiometricsEnabled() async {
    final value = await _storage.read(key: _biometricsEnabledKey);
    return value == 'true';
  }

  Future<void> setSessionUserData(String jsonStr) async {
    await _storage.write(key: _sessionUserKey, value: jsonStr);
  }

  Future<String?> getSessionUserData() async {
    return await _storage.read(key: _sessionUserKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _sessionUserKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

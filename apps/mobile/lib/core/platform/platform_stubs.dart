/// Platform-specific stub implementations for web build.
///
/// These stubs provide minimal implementations for native-only packages so
/// the Flutter analyzer does not fail when compiling to web.

class FlutterSecureStorage {
  const FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {}
  Future<String?> read({required String key}) async => null;
  Future<void> delete({required String key}) async {}
  Future<void> deleteAll() async {}
}

// Provide a default stub instance used by other modules during web analysis.
const FlutterSecureStorage secureStorageStub = FlutterSecureStorage();

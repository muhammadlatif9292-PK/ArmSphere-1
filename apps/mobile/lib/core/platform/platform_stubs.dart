/// Platform-specific stub implementations for web build.
///
/// These stubs provide no-op or fallback implementations for native-only
/// packages when compiling to web.
library;

class FlutterSecureStorage {
  const FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {}

  Future<String?> read({required String key}) async => null;

  Future<void> delete({required String key}) async {}

  Future<void> deleteAll() async {}
}

const secureStorageStub = FlutterSecureStorage();


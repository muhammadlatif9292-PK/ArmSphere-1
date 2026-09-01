/// Platform-specific stub implementations for web build.
///
/// These stubs provide no-op or fallback implementations for native-only
/// packages when compiling to web.

// Stub for flutter_secure_storage
const secureStorageStub = _SecureStorageStub();
const FlutterSecureStorage _SecureStorageStub() = _SecureStorageStubImpl();

class _SecureStorageStubImpl implements FlutterSecureStorage {
  const _SecureStorageStubImpl();

  @override
  Future<void> write({required String key, required String value}) async {
    // Web: Use localStorage for demo persistence (not secure in production)
    if (dart.library.html) {
      final window = html.window as dynamic;
      window.localStorage?.setItem(key, value);
    }
  }

  @override
  Future<String?> read({required String key}) async {
    // Web: Retrieve from localStorage
    if (dart.library.html) {
      final window = html.window as dynamic;
      return window.localStorage?.getItem(key);
    }
    return null;
  }

  @override
  Future<void> delete({required String key}) async {
    if (dart.library.html) {
      final window = html.window as dynamic;
      window.localStorage?.removeItem(key);
    }
  }

  @override
  Future<void> deleteAll() async {
    if (dart.library.html) {
      final window = html.window as dynamic;
      window.localStorage?.clear();
    }
  }
}

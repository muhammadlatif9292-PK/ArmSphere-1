/// Platform-specific stub implementations for web build.
///
/// These stubs provide no-op or fallback implementations for native-only
/// packages when compiling to web.

import 'dart:html' as html;

class FlutterSecureStorage {
  const FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    html.window.localStorage[key] = value;
  }

  Future<String?> read({required String key}) async {
    return html.window.localStorage[key];
  }

  Future<void> delete({required String key}) async {
    html.window.localStorage.remove(key);
  }

  Future<void> deleteAll() async {
    html.window.localStorage.clear();
  }
}

const secureStorageStub = FlutterSecureStorage();


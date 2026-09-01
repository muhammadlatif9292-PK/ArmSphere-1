/// Stub for webview_flutter package.
///
/// WebView is native-only. On web, throw an error to prevent runtime crashes.

class _WebViewStub {
  static throwUnsupportedError() {
    throw UnsupportedError(
      'WebView is not supported in web build. '
      'This feature is mobile-only. Consider using iframe or external URLs for web.',
    );
  }
}

// Re-export as webview_flutter to maintain original API surface
// (but throw on all usage)
export 'dart:ui' show BoxFit, Color, EdgeInsets, SizedBox;
export 'dart:ui' show BoxFit, AlignmentGeometry, Alignment;

// Export standard widget exports
export 'package:flutter/material.dart' show WebViewWidget;

// Stub the WebViewController class
class WebViewController {
  WebViewController._();

  factory WebViewController() => throwUnsupportedError();

  Future<void> loadRequest(Uri url) => throwUnsupportedError();
  Future<void> loadUrl(String url) => throwUnsupportedError();
  Future<void> loadHtmlString(String html, {String? baseUrl}) => throwUnsupportedError();

  Future<bool> canGoBack() => throwUnsupportedError();
  Future<bool> canGoForward() => throwUnsupportedError();
  Future<void> goBack() => throwUnsupportedError();
  Future<void> goForward() => throwUnsupportedError();
  Future<void> reload() => throwUnsupportedError();
  Future<void> clearCache() => throwUnsupportedError();
  Future<void> clearHistory() => throwUnsupportedError();

  Future<NavigationHistory?> getNavigationHistory() => throwUnsupportedError();

  // Standard setters
  setJavaScriptMode(JavaScriptMode mode) => throwUnsupportedError();
  setBackgroundColor(Color color) => throwUnsupportedError();
  setNavigationDelegate(NavigationDelegate delegate) => throwUnsupportedError();
}

// Stub JavaScriptMode enum
enum JavaScriptMode { unrestricted, disabled }

// Stub NavigationDelegate
class NavigationDelegate {
  NavigationDelegate._();

  factory NavigationDelegate({
    required void Function(NavigationAction action) onNavigationRequest,
    required void Function(int progress) onProgress,
    required void Function(WebResourceError error) onWebResourceError,
    required void Function(String url) onPageStarted,
    required void Function(String url) onPageFinished,
  }) = _NavigationDelegateImpl;

  static const empty = NavigationDelegate._();
}

class _NavigationDelegateImpl extends NavigationDelegate {
  final void Function(NavigationAction action) onNavigationRequest;
  final void Function(int progress) onProgress;
  final void Function(WebResourceError error) onWebResourceError;
  final void Function(String url) onPageStarted;
  final void Function(String url) onPageFinished;

  _NavigationDelegateImpl({
    required this.onNavigationRequest,
    required this.onProgress,
    required this.onWebResourceError,
    required this.onPageStarted,
    required this.onPageFinished,
  });
}

// Stub NavigationAction
class NavigationAction {
  NavigationAction._();
  Uri get url => Uri.parse('');
  String get method => 'GET';
  NavigationDestination get destination => NavigationDestination.unknown;
}

// Stub NavigationDestination
class NavigationDestination {
  NavigationDestination._();
  static const unknown = NavigationDestination._();
}

// Stub WebResourceError
class WebResourceError {
  WebResourceError._();
  String get description => 'WebView error';
  int get errorCode => -1;
}

/// Stub for webview_flutter package.
///
/// WebView is native-only. On web, throw an error to prevent runtime crashes.
library;

import 'package:flutter/material.dart';

Never throwUnsupportedError() {
  throw UnsupportedError(
    'WebView is not supported in web build. '
    'This feature is mobile-only. Consider using iframe or external URLs for web.',
  );
}

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

  Future<NavigationHistory> getNavigationHistory() => throwUnsupportedError();

  // Standard setters
  Future<void> setJavaScriptMode(JavaScriptMode mode) => throwUnsupportedError();
  Future<void> setBackgroundColor(Color color) => throwUnsupportedError();
  Future<void> setNavigationDelegate(NavigationDelegate delegate) => throwUnsupportedError();
}

class WebViewWidget extends StatelessWidget {
  const WebViewWidget({super.key, required this.controller});

  final WebViewController controller;

  @override
  Widget build(BuildContext context) => throwUnsupportedError();
}

class NavigationHistory {
  const NavigationHistory();
}

// Stub JavaScriptMode enum
enum JavaScriptMode { unrestricted, disabled }

// Stub NavigationDelegate
class NavigationDelegate {
  const NavigationDelegate({
    this.onNavigationRequest,
    this.onProgress,
    this.onWebResourceError,
    this.onPageStarted,
    this.onPageFinished,
  });

  final void Function(NavigationAction action)? onNavigationRequest;
  final void Function(int progress)? onProgress;
  final void Function(WebResourceError error)? onWebResourceError;
  final void Function(String url)? onPageStarted;
  final void Function(String url)? onPageFinished;

  static const empty = NavigationDelegate();
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
  const NavigationDestination._();
  static const unknown = NavigationDestination._();
}

// Stub WebResourceError
class WebResourceError {
  WebResourceError._();
  String get description => 'WebView error';
  int get errorCode => -1;
}

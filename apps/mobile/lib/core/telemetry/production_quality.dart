import 'dart:async';
import 'package:flutter/foundation.dart';

class CrashlyticsTelemetry {
  static Future<void> logException(dynamic exception, StackTrace? stack) async {
    // Write telemetry details to local console
    if (kDebugMode) {
      print('[Telemetry - Crashlytics] Exception logged: $exception');
      if (stack != null) {
        print(stack.toString());
      }
    }
  }

  static Future<void> setCustomKey(String key, String value) async {
    if (kDebugMode) {
      print('[Telemetry - Crashlytics] Context key [$key]: $value');
    }
  }
}

class AnalyticsTelemetry {
  static Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (kDebugMode) {
      print('[Telemetry - Analytics] Logged event "$name" with parameters: $parameters');
    }
  }

  static Future<void> setUserProperty(String name, String value) async {
    if (kDebugMode) {
      print('[Telemetry - Analytics] Set user property "$name" to "$value"');
    }
  }
}

class PerformanceTelemetry {
  static Map<String, Stopwatch> activeTraces = {};

  static void startTrace(String name) {
    final stopwatch = Stopwatch()..start();
    activeTraces[name] = stopwatch;
    if (kDebugMode) {
      print('[Telemetry - Performance] Started trace "$name"');
    }
  }

  static void stopTrace(String name) {
    final stopwatch = activeTraces.remove(name);
    if (stopwatch != null) {
      stopwatch.stop();
      if (kDebugMode) {
        print('[Telemetry - Performance] Stopped trace "$name" after ${stopwatch.elapsedMilliseconds}ms');
      }
    }
  }
}

/// Stub for local_auth package.
///
/// Biometrics (fingerprint/face) are native-only. On web, this stub
/// provides no-op methods that always return false/false.

import 'package:flutter/foundation.dart';

class _LocalAuthStub {
  static bool get isSupported => false;
}

const LocalAuth _localAuthStub = _LocalAuthStub();
const LocalAuth localAuthStub = _LocalAuthStub();

class LocalAuth {
  const LocalAuth();

  // Always returns false on web
  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) {
      debugPrint('LocalAuth: Biometrics are not supported on web');
      return false;
    }
    throw UnsupportedError('LocalAuth is only available on native platforms');
  }

  // Always returns false on web
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) {
      debugPrint('LocalAuth: No biometrics available on web');
      return [];
    }
    throw UnsupportedError('LocalAuth is only available on native platforms');
  }

  // Always returns false on web
  Future<bool> isDeviceSecure() async {
    if (kIsWeb) {
      debugPrint('LocalAuth: Device security not available on web');
      return false;
    }
    throw UnsupportedError('LocalAuth is only available on native platforms');
  }

  // Always returns false on web
  Future<bool> authenticate({
    String? localizedReason,
    bool stickyAuth = false,
    BorderSideOption? sensitiveAction,
    NativeAuthenticationOptions? options,
  }) async {
    if (kIsWeb) {
      debugPrint('LocalAuth: Authentication is not supported on web');
      return false;
    }
    throw UnsupportedError('LocalAuth is only available on native platforms');
  }
}

enum BiometricType { face, fingerprint, bodyScan }

enum BorderSideOption { showCancel, sensitive }

class NativeAuthenticationOptions {
  NativeAuthenticationOptions({
    this.useErrorDialogs = true,
    this.stickyAuth = false,
    this.biometricOnly = false,
    this.sensorFrameRate,
  });

  final bool useErrorDialogs;
  final bool stickyAuth;
  final bool biometricOnly;
  final int? sensorFrameRate;
}

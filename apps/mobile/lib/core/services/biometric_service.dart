import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../storage/secure_storage.dart';

/// Hardware and enrollment state of biometric authentication on the device.
enum BiometricCapability {
  /// Biometric hardware is present and active, and the user has enrolled
  /// credentials (fingerprint, face, etc.) in device settings.
  available,

  /// Device hardware supports biometrics or screen security, but no
  /// biometric credentials have been enrolled by the user in system settings.
  notEnrolled,

  /// Device lacks biometric hardware, is running on an unsupported platform
  /// (e.g. web), or biometrics are permanently disabled.
  unsupported,
}

/// Structured outcome of a biometric authentication attempt.
enum BiometricAuthStatus {
  /// User successfully verified their biometric identity or device PIN.
  success,

  /// Authentication failed (e.g. mismatch or unrecognized fingerprint/face).
  failed,

  /// User dismissed, canceled, or backed out of the system biometric dialog.
  canceled,

  /// No biometrics enrolled in device settings.
  notEnrolled,

  /// Biometrics not supported on device or platform.
  unsupported,

  /// Biometrics locked out due to too many failed attempts; requires PIN/password.
  lockedOut,
}

/// Encapsulates the result and user-facing diagnostic message from an authentication attempt.
class BiometricAuthResult {
  final BiometricAuthStatus status;
  final String? message;

  const BiometricAuthResult({
    required this.status,
    this.message,
  });

  bool get isSuccess => status == BiometricAuthStatus.success;

  @override
  String toString() => 'BiometricAuthResult(status: $status, message: $message)';
}

/// Safe, production-grade biometric service wrapping [LocalAuthentication].
///
/// Provides zero dead-end guarantees:
/// 1. Accurately distinguishes unsupported hardware from lack of user enrollment.
/// 2. Never throws unhandled [PlatformException] or [MissingPluginException].
/// 3. Supports system-level device PIN/Passcode fallback as well as standard app password fallback.
class BiometricService {
  final LocalAuthentication _localAuth;
  final SecureStorage _secureStorage;

  BiometricService({
    LocalAuthentication? localAuth,
    SecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? SecureStorage();

  /// Evaluates device hardware and enrollment capability.
  /// Safely catches platform exceptions so unsupported or corrupt environments never crash.
  Future<BiometricCapability> getCapability() async {
    if (kIsWeb) {
      return BiometricCapability.unsupported;
    }

    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return BiometricCapability.unsupported;
      }

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        return BiometricCapability.unsupported;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return BiometricCapability.notEnrolled;
      }

      return BiometricCapability.available;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet ||
          (e.message != null && e.message!.toLowerCase().contains('not enrolled'))) {
        return BiometricCapability.notEnrolled;
      }
      return BiometricCapability.unsupported;
    } catch (_) {
      return BiometricCapability.unsupported;
    }
  }

  /// Lists specific enrolled biometric types (e.g. face, fingerprint, iris).
  Future<List<BiometricType>> getEnrolledBiometrics() async {
    if (kIsWeb) return const [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Returns true ONLY IF biometric unlock is supported and enrolled on the device
  /// AND the user has enabled biometric unlock in settings.
  Future<bool> isBiometricUnlockAvailable() async {
    try {
      final isEnabled = await _secureStorage.getBiometricsEnabled();
      if (!isEnabled) return false;

      final capability = await getCapability();
      return capability == BiometricCapability.available;
    } catch (_) {
      return false;
    }
  }

  /// Reads the user's stored biometric unlock toggle state from secure storage.
  Future<bool> isBiometricsEnabled() async {
    try {
      return await _secureStorage.getBiometricsEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Enables or disables biometric unlock in preferences.
  ///
  /// When enabling:
  /// - Verifies that device hardware is supported and enrolled.
  /// - If [requireVerification] is true (default), prompts biometric verification
  ///   immediately to confirm authorization before updating the setting.
  Future<bool> setBiometricsEnabled(
    bool enabled, {
    bool requireVerification = true,
    String? localizedReason,
  }) async {
    if (!enabled) {
      await _secureStorage.setBiometricsEnabled(false);
      return true;
    }

    final capability = await getCapability();
    if (capability != BiometricCapability.available) {
      return false;
    }

    if (requireVerification) {
      final result = await authenticate(
        localizedReason: localizedReason ??
            'Authenticate with Face ID or Fingerprint to enable Biometric Unlock',
        allowDeviceCredentials: false,
      );
      if (!result.isSuccess) {
        return false;
      }
    }

    await _secureStorage.setBiometricsEnabled(true);
    return true;
  }

  /// Safely invokes biometric authentication.
  ///
  /// - [localizedReason]: Explanation displayed in the system biometric prompt.
  /// - [allowDeviceCredentials]: When true, allows fallback to device PIN / Pattern /
  ///   Passcode if biometrics fail or are not recognized.
  ///
  /// Returns a structured [BiometricAuthResult] rather than throwing errors.
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool allowDeviceCredentials = true,
  }) async {
    final capability = await getCapability();

    if (capability == BiometricCapability.unsupported) {
      return const BiometricAuthResult(
        status: BiometricAuthStatus.unsupported,
        message: 'Biometrics are not supported on this device.',
      );
    }

    if (capability == BiometricCapability.notEnrolled) {
      return const BiometricAuthResult(
        status: BiometricAuthStatus.notEnrolled,
        message: 'No biometric credentials enrolled in system settings.',
      );
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: !allowDeviceCredentials,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );

      if (didAuthenticate) {
        return const BiometricAuthResult(status: BiometricAuthStatus.success);
      } else {
        return const BiometricAuthResult(
          status: BiometricAuthStatus.canceled,
          message: 'Authentication was canceled or dismissed.',
        );
      }
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return const BiometricAuthResult(
            status: BiometricAuthStatus.unsupported,
            message: 'Biometrics are currently unavailable on this device.',
          );
        case auth_error.notEnrolled:
        case auth_error.passcodeNotSet:
          return const BiometricAuthResult(
            status: BiometricAuthStatus.notEnrolled,
            message: 'No biometric credentials or device passcodes are configured.',
          );
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return const BiometricAuthResult(
            status: BiometricAuthStatus.lockedOut,
            message:
                'Biometrics are temporarily locked out due to too many attempts. Please use your account password.',
          );
        default:
          final lower = (e.message ?? '').toLowerCase();
          if (lower.contains('cancel') ||
              lower.contains('user canceled') ||
              lower.contains('dismissed')) {
            return const BiometricAuthResult(
              status: BiometricAuthStatus.canceled,
              message: 'Authentication was canceled by user.',
            );
          }
          return BiometricAuthResult(
            status: BiometricAuthStatus.failed,
            message: e.message ?? 'Biometric authentication failed.',
          );
      }
    } catch (e) {
      return BiometricAuthResult(
        status: BiometricAuthStatus.failed,
        message: e.toString(),
      );
    }
  }
}

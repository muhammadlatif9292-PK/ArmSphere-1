import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/services/biometric_service.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}
class MockSecureStorage extends Mock implements SecureStorage {}
class FakeAuthenticationOptions extends Fake implements AuthenticationOptions {}

void main() {
  late MockLocalAuthentication mockLocalAuth;
  late MockSecureStorage mockSecureStorage;
  late BiometricService biometricService;

  setUpAll(() {
    registerFallbackValue(FakeAuthenticationOptions());
  });

  setUp(() {
    mockLocalAuth = MockLocalAuthentication();
    mockSecureStorage = MockSecureStorage();
    biometricService = BiometricService(
      localAuth: mockLocalAuth,
      secureStorage: mockSecureStorage,
    );
  });

  group('BiometricService - Hardware & Enrollment Capability', () {
    test('returns unsupported when isDeviceSupported() returns false', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final capability = await biometricService.getCapability();
      expect(capability, equals(BiometricCapability.unsupported));
      verify(() => mockLocalAuth.isDeviceSupported()).called(1);
      verifyNever(() => mockLocalAuth.canCheckBiometrics);
    });

    test('returns unsupported when canCheckBiometrics returns false', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

      final capability = await biometricService.getCapability();
      expect(capability, equals(BiometricCapability.unsupported));
    });

    test('returns notEnrolled when availableBiometrics is empty', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

      final capability = await biometricService.getCapability();
      expect(capability, equals(BiometricCapability.notEnrolled));
    });

    test('returns available when biometrics are enrolled and supported', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint, BiometricType.face]);

      final capability = await biometricService.getCapability();
      expect(capability, equals(BiometricCapability.available));
    });

    test('returns notEnrolled on PlatformException with notEnrolled code', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenThrow(PlatformException(code: auth_error.notEnrolled, message: 'No fingerprints enrolled'));

      final capability = await biometricService.getCapability();
      expect(capability, equals(BiometricCapability.notEnrolled));
    });

    test('returns notEnrolled on PlatformException with passcodeNotSet code', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenThrow(PlatformException(code: auth_error.passcodeNotSet, message: 'No passcode set'));

      final capability = await biometricService.getCapability();
      expect(capability, equals(BiometricCapability.notEnrolled));
    });

    test('safely returns unsupported on unexpected exception', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenThrow(Exception('Hardware sensor bus disconnected'));

      final capability = await biometricService.getCapability();
      expect(capability, equals(BiometricCapability.unsupported));
    });
  });

  group('BiometricService - Preference & Availability State', () {
    test('isBiometricUnlockAvailable returns false if user has disabled biometrics in settings', () async {
      when(() => mockSecureStorage.getBiometricsEnabled()).thenAnswer((_) async => false);

      final available = await biometricService.isBiometricUnlockAvailable();
      expect(available, isFalse);
      verifyNever(() => mockLocalAuth.isDeviceSupported());
    });

    test('isBiometricUnlockAvailable returns false if enabled but capability is notEnrolled', () async {
      when(() => mockSecureStorage.getBiometricsEnabled()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

      final available = await biometricService.isBiometricUnlockAvailable();
      expect(available, isFalse);
    });

    test('isBiometricUnlockAvailable returns true when enabled in settings AND enrolled on device', () async {
      when(() => mockSecureStorage.getBiometricsEnabled()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      final available = await biometricService.isBiometricUnlockAvailable();
      expect(available, isTrue);
    });

    test('setBiometricsEnabled(false) clears preference in secure storage without prompting auth', () async {
      when(() => mockSecureStorage.setBiometricsEnabled(false)).thenAnswer((_) async {});

      final success = await biometricService.setBiometricsEnabled(false);
      expect(success, isTrue);
      verify(() => mockSecureStorage.setBiometricsEnabled(false)).called(1);
      verifyNever(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          ));
    });

    test('setBiometricsEnabled(true) returns false if device capability is unsupported', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final success = await biometricService.setBiometricsEnabled(true);
      expect(success, isFalse);
      verifyNever(() => mockSecureStorage.setBiometricsEnabled(true));
    });

    test('setBiometricsEnabled(true) prompts biometric verification and persists on success', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => true);
      when(() => mockSecureStorage.setBiometricsEnabled(true)).thenAnswer((_) async {});

      final success = await biometricService.setBiometricsEnabled(true);
      expect(success, isTrue);
      verify(() => mockSecureStorage.setBiometricsEnabled(true)).called(1);
    });

    test('setBiometricsEnabled(true) does NOT persist if user cancels prompt', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => false);

      final success = await biometricService.setBiometricsEnabled(true);
      expect(success, isFalse);
      verifyNever(() => mockSecureStorage.setBiometricsEnabled(true));
    });
  });

  group('BiometricService - Safe Authentication & Error Resilience', () {
    test('returns unsupported status if device is unsupported without invoking localAuth', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await biometricService.authenticate(localizedReason: 'Test');
      expect(result.status, equals(BiometricAuthStatus.unsupported));
      expect(result.isSuccess, isFalse);
      verifyNever(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          ));
    });

    test('returns notEnrolled status if no biometrics enrolled without invoking localAuth', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

      final result = await biometricService.authenticate(localizedReason: 'Test');
      expect(result.status, equals(BiometricAuthStatus.notEnrolled));
      expect(result.isSuccess, isFalse);
    });

    test('returns success when biometric authentication matches', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => true);

      final result = await biometricService.authenticate(localizedReason: 'Test');
      expect(result.status, equals(BiometricAuthStatus.success));
      expect(result.isSuccess, isTrue);
    });

    test('returns canceled when user dismisses prompt', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => false);

      final result = await biometricService.authenticate(localizedReason: 'Test');
      expect(result.status, equals(BiometricAuthStatus.canceled));
      expect(result.isSuccess, isFalse);
    });

    test('handles lockedOut PlatformException gracefully with informative message', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenThrow(PlatformException(code: auth_error.lockedOut, message: 'Too many attempts'));

      final result = await biometricService.authenticate(localizedReason: 'Test');
      expect(result.status, equals(BiometricAuthStatus.lockedOut));
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('locked out'));
    });

    test('handles general PlatformException without crashing', () async {
      when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenThrow(PlatformException(code: 'HardwareError', message: 'Sensor communication error'));

      final result = await biometricService.authenticate(localizedReason: 'Test');
      expect(result.status, equals(BiometricAuthStatus.failed));
      expect(result.isSuccess, isFalse);
      expect(result.message, equals('Sensor communication error'));
    });
  });
}

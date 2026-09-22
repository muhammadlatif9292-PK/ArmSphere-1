import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/api/dio_client.dart';

class MockSecureStorage extends Mock implements SecureStorage {}
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('DioClient - Production Endpoint Fail-Safe & Host Allowlist', () {
    test('Debug/Development Mode: falls back to default staging URL when no URL supplied', () {
      final url = DioClient.resolveBaseUrl(isRelease: false, rawUrl: '');
      expect(url, equals(DioClient.defaultStagingUrl));
      expect(url, equals('https://armsphere2.netlify.app'));
    });

    test('Debug/Development Mode: uses custom dev/emulator URL when explicitly provided', () {
      final url = DioClient.resolveBaseUrl(isRelease: false, rawUrl: 'http://10.0.2.2:3000');
      expect(url, equals('http://10.0.2.2:3000'));
    });

    test('Release Mode: throws StateError when API_BASE_URL is missing/empty', () {
      expect(
        () => DioClient.resolveBaseUrl(isRelease: true, rawUrl: ''),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('FATAL [PRODUCTION FAIL-SAFE]: API_BASE_URL is not configured'),
          ),
        ),
      );
    });

    test('Release Mode: throws StateError when API_BASE_URL is malformed', () {
      expect(
        () => DioClient.resolveBaseUrl(isRelease: true, rawUrl: 'not-a-valid-url'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('is invalid'),
          ),
        ),
      );
    });

    test('Release Mode: successfully resolves valid production host (exact)', () {
      const prodUrl = 'https://armsphere-api-gateway.armsphere.workers.dev';
      final resolved = DioClient.resolveBaseUrl(isRelease: true, rawUrl: prodUrl);
      expect(resolved, equals(prodUrl));
    });

    test('Release Mode: successfully resolves and normalizes valid production host with trailing slash', () {
      final resolved = DioClient.resolveBaseUrl(isRelease: true, rawUrl: 'https://armsphere-api-gateway.armsphere.workers.dev/');
      expect(resolved, equals('https://armsphere-api-gateway.armsphere.workers.dev'));
    });

    test('Release Mode: throws StateError when wrong HTTPS host is provided', () {
      expect(
        () => DioClient.resolveBaseUrl(isRelease: true, rawUrl: 'https://evil-example.com'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Release build cannot connect to non-production endpoint'),
              contains('Production API host must be exactly "armsphere-api-gateway.armsphere.workers.dev"'),
            ),
          ),
        ),
      );
    });

    test('Release Mode: throws StateError when HTTP production-looking host is provided', () {
      expect(
        () => DioClient.resolveBaseUrl(isRelease: true, rawUrl: 'http://armsphere-api-gateway.armsphere.workers.dev'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Production API must use HTTPS'),
          ),
        ),
      );
    });

    test('Release Mode: throws StateError when staging host is provided', () {
      expect(
        () => DioClient.resolveBaseUrl(isRelease: true, rawUrl: 'https://armsphere2.netlify.app'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Release build cannot connect to non-production endpoint'),
          ),
        ),
      );
    });

    test('Release Mode: throws StateError when localhost is provided', () {
      expect(
        () => DioClient.resolveBaseUrl(isRelease: true, rawUrl: 'http://localhost:3000'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Release build cannot connect to non-production endpoint'),
          ),
        ),
      );
    });

    test('Release Mode: throws StateError when emulator/local host is provided', () {
      expect(
        () => DioClient.resolveBaseUrl(isRelease: true, rawUrl: 'http://10.0.2.2:3000'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Release build cannot connect to non-production endpoint'),
          ),
        ),
      );
    });

    test('Release Mode: DioClient constructor throws StateError when explicit wrong-host bypass is attempted', () {
      expect(
        () => DioClient(
          secureStorage: MockSecureStorage(),
          connectivity: MockConnectivity(),
          baseUrl: 'https://evil-example.com',
          isRelease: true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Production API host must be exactly "armsphere-api-gateway.armsphere.workers.dev"'),
          ),
        ),
      );
    });

    test('Release Mode: DioClient constructor throws StateError when explicit staging bypass is attempted', () {
      expect(
        () => DioClient(
          secureStorage: MockSecureStorage(),
          connectivity: MockConnectivity(),
          baseUrl: 'https://armsphere2.netlify.app',
          isRelease: true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Release build cannot connect to non-production endpoint'),
          ),
        ),
      );
    });

    test('Release Mode: DioClient constructor throws StateError when explicit localhost bypass is attempted', () {
      expect(
        () => DioClient(
          secureStorage: MockSecureStorage(),
          connectivity: MockConnectivity(),
          baseUrl: 'http://localhost:3000',
          isRelease: true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Release build cannot connect to non-production endpoint'),
          ),
        ),
      );
    });
  });
}

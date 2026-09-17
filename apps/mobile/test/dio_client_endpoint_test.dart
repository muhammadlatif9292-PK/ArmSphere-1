import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/dio_client.dart';

void main() {
  group('DioClient - Production Endpoint Fail-Safe', () {
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

    test('Release Mode: throws StateError when API_BASE_URL points to Netlify staging', () {
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

    test('Release Mode: throws StateError when API_BASE_URL points to localhost', () {
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

    test('Release Mode: successfully resolves when valid production URL is explicitly provided', () {
      const prodUrl = 'https://api.armsphere.com';
      final resolved = DioClient.resolveBaseUrl(isRelease: true, rawUrl: prodUrl);
      expect(resolved, equals(prodUrl));
    });
  });
}

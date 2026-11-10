import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/api/dio_client.dart';
import 'package:mobile/core/utils/error_formatter.dart';

void main() {
  group('AppErrorFormatter Unit Tests', () {
    test('formats null as generic fallback message', () {
      expect(
        AppErrorFormatter.format(null),
        equals('An unexpected error occurred. Please try again.'),
      );
    });

    test('formats ApiException with detail correctly', () {
      final apiEx = ApiException(
        type: 'auth:conflict',
        title: 'Conflict',
        status: 409,
        detail: 'A user with this username already exists.',
      );
      expect(
        AppErrorFormatter.format(apiEx),
        equals('A user with this username already exists.'),
      );
    });

    test('formats ApiException with invalidParams field errors correctly', () {
      final apiEx = ApiException(
        type: 'about:blank',
        title: 'Validation Failed',
        status: 400,
        detail: 'The request payload failed validation.',
        invalidParams: {'dateOfBirth': 'Invalid date format for Date of Birth'},
      );
      expect(
        AppErrorFormatter.format(apiEx),
        equals('Invalid date format for Date of Birth'),
      );
    });

    test('ApiException.fromResponse extracts errors map into invalidParams', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/athletes'),
        statusCode: 400,
        data: {
          'title': 'Validation Failed',
          'detail': 'The request payload failed validation.',
          'errors': {'dateOfBirth': 'Invalid date format for Date of Birth'},
        },
      );
      final apiEx = ApiException.fromResponse(response);
      expect(apiEx.invalidParams, isNotNull);
      expect(apiEx.invalidParams!['dateOfBirth'], equals('Invalid date format for Date of Birth'));
      expect(AppErrorFormatter.format(apiEx), equals('Invalid date format for Date of Birth'));
    });

    test('formats OfflineException correctly', () {
      final offlineEx = OfflineException('No internet connection active.');
      expect(
        AppErrorFormatter.format(offlineEx),
        equals('No internet connection active.'),
      );
    });

    test('formats DioException receiveTimeout into user-friendly message', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        type: DioExceptionType.receiveTimeout,
      );
      expect(
        AppErrorFormatter.format(dioEx),
        equals('Server took too long to respond. Please check your connection and try again.'),
      );
    });

    test('formats DioException connectionTimeout into user-friendly message', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        AppErrorFormatter.format(dioEx),
        equals('Connection timed out. Please check your internet connection and try again.'),
      );
    });

    test('formats DioException connectionError into user-friendly message', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/tournaments'),
        type: DioExceptionType.connectionError,
      );
      expect(
        AppErrorFormatter.format(dioEx),
        equals('Unable to connect to ArmSphere servers. Please check your internet connection.'),
      );
    });

    test('formats DioException badResponse 409 into friendly conflict message', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 409,
          data: {'detail': 'A user with this email address already exists.'},
        ),
      );
      expect(
        AppErrorFormatter.format(dioEx),
        equals('A user with this email address already exists.'),
      );
    });

    test('formats DioException wrapping ApiException inner error', () {
      final apiEx = ApiException(
        type: 'auth:unauthorized',
        title: 'Unauthorized',
        status: 401,
        detail: 'Invalid email or password.',
      );
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        error: apiEx,
      );
      expect(
        AppErrorFormatter.format(dioEx),
        equals('Invalid email or password.'),
      );
    });

    test('strips Exception: prefix from standard Dart exceptions', () {
      final ex = Exception('Custom operation failed');
      expect(
        AppErrorFormatter.format(ex),
        equals('Custom operation failed'),
      );
    });

    test('formats raw [401] Session Expired string cleanly into user-friendly copy', () {
      final rawStr = '[401] Session Expired: Please log in again.';
      expect(
        AppErrorFormatter.format(rawStr),
        equals('Your session has expired. Please sign in again.'),
      );
      final ex = Exception('[401] Session Expired: Please log in again.');
      expect(
        AppErrorFormatter.format(ex),
        equals('Your session has expired. Please sign in again.'),
      );
    });

    test('formats ApiException with status 401 and default detail cleanly', () {
      final apiEx = ApiException(
        type: 'auth:session-expired',
        title: 'Session Expired',
        status: 401,
        detail: 'Please log in again.',
      );
      expect(
        AppErrorFormatter.format(apiEx),
        equals('Your session has expired. Please sign in again.'),
      );
    });

    test('detects isAuthError correctly across ApiException, DioException, and raw strings', () {
      final apiEx = ApiException(
        type: 'auth:session-expired',
        title: 'Session Expired',
        status: 401,
        detail: 'Please log in again.',
      );
      expect(AppErrorFormatter.isAuthError(apiEx), isTrue);

      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/championships'),
        response: Response(
          requestOptions: RequestOptions(path: '/championships'),
          statusCode: 401,
        ),
      );
      expect(AppErrorFormatter.isAuthError(dioEx), isTrue);
      expect(AppErrorFormatter.isAuthError('[401] Session Expired'), isTrue);
      expect(AppErrorFormatter.isAuthError('Server error: connection timeout'), isFalse);
    });

    test('detects isPermissionError correctly for 403 status', () {
      final apiEx = ApiException(
        type: 'auth:forbidden',
        title: 'Forbidden',
        status: 403,
        detail: 'Access restricted.',
      );
      expect(AppErrorFormatter.isPermissionError(apiEx), isTrue);
      expect(AppErrorFormatter.isPermissionError('[403] Forbidden'), isTrue);
      expect(AppErrorFormatter.isPermissionError(apiEx.toString()), isTrue);
      expect(AppErrorFormatter.isPermissionError('Session Expired'), isFalse);
    });

    test('detects isNetworkError correctly across offline and timeout errors', () {
      final offline = OfflineException('Device offline.');
      expect(AppErrorFormatter.isNetworkError(offline), isTrue);

      final dioTimeout = DioException(
        requestOptions: RequestOptions(path: '/teams'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(AppErrorFormatter.isNetworkError(dioTimeout), isTrue);
      expect(AppErrorFormatter.isNetworkError('Connection reset by peer'), isTrue);
      expect(AppErrorFormatter.isNetworkError(Exception('User not found')), isFalse);
    });
  });
}

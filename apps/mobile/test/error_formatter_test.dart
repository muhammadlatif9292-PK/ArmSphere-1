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
  });
}

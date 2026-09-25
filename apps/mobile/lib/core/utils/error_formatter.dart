import 'package:dio/dio.dart';
import '../api/dio_client.dart';

/// Formats exceptions across the ArmSphere mobile app into user-friendly messages.
///
/// Prevents internal SDK strings, stack traces, or raw Dio exceptions
/// (such as "DioException [receive timeout]: The request took longer than 0:00:15...")
/// from ever being presented to end users.
class AppErrorFormatter {
  static String format(Object? error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    if (error is ApiException) {
      if (error.detail.isNotEmpty && error.detail != 'No detailed error message was provided.') {
        return error.detail;
      }
      if (error.title.isNotEmpty && error.title != 'An error occurred' && error.title != 'Server Error') {
        return error.title;
      }
      return 'Server error (${error.status}). Please try again.';
    }

    if (error is OfflineException) {
      return error.message;
    }

    if (error is DioException) {
      final inner = error.error;
      if (inner != null && inner != error) {
        return format(inner);
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out. Please check your internet connection and try again.';
        case DioExceptionType.sendTimeout:
          return 'Request timed out while sending data. Please check your connection and try again.';
        case DioExceptionType.receiveTimeout:
          return 'Server took too long to respond. Please check your connection and try again.';
        case DioExceptionType.badCertificate:
          return 'Secure connection could not be verified. Please check your network.';
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map) {
            final detail = data['detail'] ?? data['message'] ?? data['title'];
            if (detail is String && detail.isNotEmpty) return detail;
          }
          final status = error.response?.statusCode;
          if (status == 400) return 'Invalid request. Please check your input and try again.';
          if (status == 401) return 'Invalid credentials or session expired.';
          if (status == 403) return 'You do not have permission to perform this action.';
          if (status == 404) return 'The requested resource was not found.';
          if (status == 409) return 'An account with this email or username already exists.';
          if (status != null && status >= 500) {
            return 'Server error. Our engineers are investigating. Please try again shortly.';
          }
          return 'Unexpected server response (${status ?? 'error'}).';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to ArmSphere servers. Please check your internet connection.';
        case DioExceptionType.unknown:
        default:
          final msg = error.message;
          if (msg != null && msg.isNotEmpty && !msg.contains('DioException')) {
            return msg;
          }
          return 'Network connection error. Please check your internet connection and try again.';
      }
    }

    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring(11).trim();
    }
    return raw;
  }
}

import 'package:dio/dio.dart';
import '../api/dio_client.dart';

/// Formats exceptions across the ArmSphere mobile app into user-friendly messages.
///
/// Prevents internal SDK strings, stack traces, or raw Dio exceptions
/// (such as "DioException [receive timeout]: The request took longer than 0:00:15...")
/// from ever being presented to end users.
class AppErrorFormatter {
  /// Checks whether [error] represents an authentication or expired session defect.
  static bool isAuthError(Object? error) {
    if (error == null) return false;
    if (error is ApiException) {
      if (error.status == 401) return true;
      if (error.type.contains('session-expired') ||
          error.type.contains('unauthorized')) {
        return true;
      }
    }
    if (error is DioException) {
      if (error.response?.statusCode == 401) return true;
      if (error.error != null && error.error != error) {
        return isAuthError(error.error);
      }
    }
    final str = error.toString().toLowerCase();
    return str.contains('401') ||
        str.contains('session expired') ||
        str.contains('log in again');
  }

  /// Checks whether [error] represents a permission or forbidden access defect.
  static bool isPermissionError(Object? error) {
    if (error == null) return false;
    if (error is ApiException) {
      if (error.status == 403) return true;
      if (error.type.contains('forbidden')) return true;
    }
    if (error is DioException) {
      if (error.response?.statusCode == 403) return true;
      if (error.error != null && error.error != error) {
        return isPermissionError(error.error);
      }
    }
    final str = error.toString().toLowerCase();
    return str.contains('403') ||
        str.contains('forbidden') ||
        str.contains('permission denied') ||
        str.contains('not authorized');
  }

  /// Checks whether [error] represents an offline connection or transient network defect.
  static bool isNetworkError(Object? error) {
    if (error == null) return false;
    if (error is OfflineException) return true;
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    final str = error.toString().toLowerCase();
    return str.contains('connection') ||
        str.contains('network') ||
        str.contains('offline') ||
        str.contains('socketexception');
  }

  static String format(Object? error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    if (error is ApiException) {
      if (error.invalidParams != null && error.invalidParams!.isNotEmpty) {
        return error.invalidParams!.values.map((v) => v.toString()).join('\n');
      }
      if (error.status == 401 &&
          (error.detail == 'Please log in again.' || error.detail.isEmpty)) {
        return 'Your session has expired. Please sign in again.';
      }
      if (error.detail.isNotEmpty &&
          error.detail != 'No detailed error message was provided.') {
        return _cleanTechnicalDetails(error.detail);
      }
      if (error.title.isNotEmpty &&
          error.title != 'An error occurred' &&
          error.title != 'Server Error') {
        return _cleanTechnicalDetails(error.title);
      }
      if (error.status == 401) {
        return 'Your session has expired. Please sign in again.';
      }
      if (error.status == 403) {
        return 'You do not have permission to perform this action.';
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
            if (detail is String && detail.isNotEmpty) {
              return _cleanTechnicalDetails(detail);
            }
          }
          final status = error.response?.statusCode;
          if (status == 400) return 'Invalid request. Please check your input and try again.';
          if (status == 401) return 'Your session has expired. Please sign in again.';
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
            return _cleanTechnicalDetails(msg);
          }
          return 'Network connection error. Please check your internet connection and try again.';
      }
    }

    final raw = error.toString();
    return _cleanTechnicalDetails(raw);
  }

  static String _cleanTechnicalDetails(String raw) {
    var cleaned = raw;
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring(11).trim();
    }
    // Remove raw status code bracket prefixes like [401] or [500]
    final statusMatch = RegExp(r'^\[\d{3}\]\s*').firstMatch(cleaned);
    if (statusMatch != null) {
      final code = cleaned.substring(1, 4);
      cleaned = cleaned.substring(statusMatch.end).trim();
      if (code == '401' &&
          (cleaned.isEmpty ||
              cleaned.toLowerCase().contains('session expired') ||
              cleaned.toLowerCase().contains('log in again'))) {
        return 'Your session has expired. Please sign in again.';
      }
      if (code == '403') {
        return 'You do not have permission to perform this action.';
      }
    }
    if (cleaned.contains('Session Expired: Please log in again.')) {
      return 'Your session has expired. Please sign in again.';
    }
    return cleaned;
  }
}

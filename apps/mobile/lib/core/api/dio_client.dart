import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../storage/secure_storage.dart';

/// Custom Exception parsing RFC-7807 Problem Details
class ApiException implements Exception {
  final String type;
  final String title;
  final int status;
  final String detail;
  final String? instance;
  final Map<String, dynamic>? invalidParams;

  ApiException({
    required this.type,
    required this.title,
    required this.status,
    required this.detail,
    this.instance,
    this.invalidParams,
  });

  factory ApiException.fromResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        type: data['type']?.toString() ?? 'about:blank',
        title: data['title']?.toString() ?? 'An error occurred',
        status: (data['status'] as num?)?.toInt() ?? response.statusCode ?? 500,
        detail: data['detail']?.toString() ?? 'No detailed error message was provided.',
        instance: data['instance']?.toString(),
        invalidParams: data['invalidParams'] is Map<String, dynamic> 
            ? data['invalidParams'] as Map<String, dynamic>
            : null,
      );
    }
    return ApiException(
      type: 'about:blank',
      title: 'Server Error',
      status: response.statusCode ?? 500,
      detail: 'Unexpected response format: ${response.data}',
    );
  }

  @override
  String toString() => '[$status] $title: $detail';
}

/// Offline Connection Exception
class OfflineException implements Exception {
  final String message;
  OfflineException([this.message = 'No active internet connection. Switched to offline mode.']);
  
  @override
  String toString() => message;
}

class DioClient {
  final Dio dio;
  final SecureStorage secureStorage;
  final Connectivity connectivity;
  final _uuid = const Uuid();
  bool _isRefreshing = false;
  final List<Completer<String>> _refreshQueue = [];

  static const String defaultStagingUrl = 'https://armsphere2.netlify.app';
  static const String productionApiHost = 'armsphere-api-gateway.armsphere.workers.dev';
  static const String productionBaseUrl = 'https://armsphere-api-gateway.armsphere.workers.dev';

  /// Resolves the API base URL with a production fail-safe and strict host allowlist.
  ///
  /// In release mode ([kReleaseMode] is true):
  /// - The production API URL must be explicitly supplied and must match the verified
  ///   ArmSphere production host [productionApiHost] (https://armsphere-api-gateway.armsphere.workers.dev).
  /// - Any unauthorized host, insecure scheme, local address, staging domain, or missing
  ///   configuration throws a [StateError] to fail fast immediately on startup.
  ///
  /// In debug/development mode ([kReleaseMode] is false):
  /// - Returns the supplied [rawUrl] or [API_BASE_URL], or falls back to [defaultStagingUrl].
  static String resolveBaseUrl({bool? isRelease, String? rawUrl}) {
    final releaseMode = isRelease ?? kReleaseMode;
    final envUrl = rawUrl ?? const String.fromEnvironment('API_BASE_URL');

    if (releaseMode) {
      if (envUrl.isEmpty) {
        throw StateError(
          'FATAL [PRODUCTION FAIL-SAFE]: API_BASE_URL is not configured for this release build. '
          'You must build with: --dart-define=API_BASE_URL=$productionBaseUrl. '
          'Silent fallback to staging is strictly forbidden in release mode.',
        );
      }

      String normalizedUrl = envUrl.trim();
      while (normalizedUrl.endsWith('/')) {
        normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
      }

      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        throw StateError(
          'FATAL [PRODUCTION FAIL-SAFE]: Provided API_BASE_URL "$envUrl" is invalid. '
          'Expected a valid HTTPS URL (e.g., $productionBaseUrl).',
        );
      }

      final host = uri.host.toLowerCase();
      if (host != productionApiHost) {
        throw StateError(
          'FATAL [PRODUCTION FAIL-SAFE]: Release build cannot connect to non-production endpoint "$envUrl". '
          'Production API host must be exactly "$productionApiHost".',
        );
      }

      if (uri.scheme.toLowerCase() != 'https') {
        throw StateError(
          'FATAL [PRODUCTION FAIL-SAFE]: Production API must use HTTPS ("$envUrl").',
        );
      }

      if (uri.hasPort && uri.port != 443) {
        throw StateError(
          'FATAL [PRODUCTION FAIL-SAFE]: Production API must use default HTTPS port 443 ("$envUrl").',
        );
      }

      if (uri.path.isNotEmpty && uri.path != '/') {
        throw StateError(
          'FATAL [PRODUCTION FAIL-SAFE]: Production API base URL must not contain path segments ("$envUrl"). '
          'Specify root base URL: $productionBaseUrl.',
        );
      }

      return normalizedUrl;
    }

    return envUrl.isNotEmpty ? envUrl : defaultStagingUrl;
  }

  DioClient({
    required this.secureStorage,
    required this.connectivity,
    String? baseUrl,
    bool? isRelease,
  }) : dio = Dio(BaseOptions(
          baseUrl: resolveBaseUrl(isRelease: isRelease, rawUrl: baseUrl),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          contentType: 'application/json',
        )) {
    _initializeInterceptors();
  }

  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.get<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  void _initializeInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 1. Offline connectivity check
        final connectivityResult = await connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: OfflineException(),
              type: DioExceptionType.connectionError,
            ),
          );
        }

        // 2. Correlation ID generation for traceability
        final correlationId = _uuid.v4();
        options.headers['X-Correlation-ID'] = correlationId;

        // 3. Inject Access Token
        final token = await secureStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (DioException err, handler) async {
        // Handle RFC-7807 exceptions
        if (err.type == DioExceptionType.badResponse && err.response != null) {
          final response = err.response!;
          
          if (response.statusCode == 401) {
            final requestOptions = response.requestOptions;

            // If the request was actually to refresh, we fail immediately to prevent loops
            if (requestOptions.path.contains('/auth/refresh')) {
              await secureStorage.clearSession();
              return handler.next(err);
            }

            // Credential endpoints own their error semantics: a rejected
            // login/MFA attempt must surface the server's message, never
            // masquerade as an expired session via the refresh cycle.
            const credentialPaths = ['/auth/login', '/auth/register', '/auth/mfa'];
            final isCredentialRequest =
                credentialPaths.any(requestOptions.path.contains);
            if (!isCredentialRequest) {
              try {
                final refreshedToken = await _refreshTokenAndRetry();

                // Re-inject token and replay original request
                requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';
                final replayedResponse = await dio.fetch(requestOptions);
                return handler.resolve(replayedResponse);
              } catch (refreshErr) {
                // Distinguish transient network failure from genuine auth expiry
                bool isNetworkError = false;
                if (refreshErr is DioException) {
                  isNetworkError = refreshErr.type == DioExceptionType.connectionError ||
                      refreshErr.type == DioExceptionType.connectionTimeout ||
                      refreshErr.type == DioExceptionType.sendTimeout ||
                      refreshErr.type == DioExceptionType.receiveTimeout;
                } else if (refreshErr is OfflineException) {
                  isNetworkError = true;
                }

                if (isNetworkError) {
                  // Transient network error: PRESERVE session. Return connection error.
                  return handler.reject(DioException(
                    requestOptions: requestOptions,
                    error: OfflineException('Connection lost during token refresh. Session preserved.'),
                    type: DioExceptionType.connectionError,
                  ));
                }

                // Definitive token refresh failure - invalidate session and reject
                await secureStorage.clearSession();
                return handler.reject(DioException(
                  requestOptions: requestOptions,
                  error: ApiException(
                    type: 'auth:session-expired',
                    title: 'Session Expired',
                    status: 401,
                    detail: 'Please log in again.',
                  ),
                  type: DioExceptionType.badResponse,
                ));
              }
            }
          }

          // Return custom ApiException instead of standard DioException
          final apiException = ApiException.fromResponse(response);
          return handler.reject(DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: apiException,
          ));
        }

        return handler.next(err);
      },
    ));
  }

  /// Refreshes the authentication tokens securely, managing concurrency lock.
  Future<String> _refreshTokenAndRetry() async {
    if (_isRefreshing) {
      // Queue up and wait for the refresh call currently in progress
      final completer = Completer<String>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw ApiException(
          type: 'auth:missing-refresh-token',
          title: 'Missing Refresh Token',
          status: 401,
          detail: 'No refresh token available.',
        );
      }

      // Create a clean standalone Dio instance to make the refresh request
      final refreshDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ));
      
      final response = await refreshDio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data != null) {
        final payload = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        // Handle both nested data object and flattened token response
        final tokenMap = payload['data'] is Map
            ? Map<String, dynamic>.from(payload['data'] as Map)
            : payload;

        final newAccessToken = tokenMap['accessToken']?.toString() ?? '';
        final newRefreshToken = tokenMap['refreshToken']?.toString() ?? '';

        if (newAccessToken.isNotEmpty) {
          await secureStorage.setAccessToken(newAccessToken);
          if (newRefreshToken.isNotEmpty) {
            await secureStorage.setRefreshToken(newRefreshToken);
          }

          // Complete queued requests
          for (final completer in _refreshQueue) {
            if (!completer.isCompleted) {
              completer.complete(newAccessToken);
            }
          }
          _refreshQueue.clear();
          return newAccessToken;
        }
      }
      
      throw ApiException(
        type: 'auth:invalid-token-response',
        title: 'Invalid Token Response',
        status: 401,
        detail: 'Invalid token response from server.',
      );
    } catch (err) {
      // Broadcast error to all queued callers so none hang indefinitely
      for (final completer in _refreshQueue) {
        if (!completer.isCompleted) {
          completer.completeError(err);
        }
      }
      _refreshQueue.clear();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }
}

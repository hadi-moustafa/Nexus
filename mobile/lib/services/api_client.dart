import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Base HTTP client for all Nexus API calls.
///
/// Interceptor responsibilities:
///   - Attach Authorization: Bearer <access_token> to every request
///   - On 401: auto-refresh the token via AuthService and retry once
///   - On refresh failure: set needsLoginNotifier = true so main.dart
///     can redirect to LoginScreen
class ApiClient {
  ApiClient._() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Fires with value=true when the token refresh fails and the user
  /// must re-authenticate. Listen to this in main.dart to show LoginScreen.
  final ValueNotifier<bool> needsLoginNotifier = ValueNotifier(false);

  // ── Interceptor handlers ──────────────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthService.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      final refreshed = await AuthService.instance.refreshToken();
      if (refreshed) {
        // Retry the original request with the new token
        final newToken = await AuthService.instance.getAccessToken();
        final opts = error.requestOptions;
        if (newToken != null) {
          opts.headers['Authorization'] = 'Bearer $newToken';
        }
        try {
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (retryError) {
          return handler.next(error);
        }
      }
      // Refresh failed — signal main.dart to show LoginScreen
      needsLoginNotifier.value = true;
    }
    handler.next(error);
  }

  // ── HTTP methods ──────────────────────────────────────────────────────────

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.post(path, data: data, queryParameters: queryParameters);

  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
  }) =>
      _dio.patch(path, data: data);

  Future<Response<dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.delete(path, queryParameters: queryParameters);
}

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// API Service with retry logic and improved error handling
/// Phase 2 Optimization - Request retry mechanism
class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        followRedirects: true, // Enable automatic redirect following
        validateStatus: (status) {
          // Accept status codes 200-399 as success (includes redirects)
          return status != null && status >= 200 && status < 400;
        },
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle token refresh on 401 errors
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
            
            if (refreshToken != null && !error.requestOptions.path.contains(AppConstants.refreshTokenEndpoint)) {
              try {
                // Try to refresh the token
                final refreshResponse = await _dio.post(
                  AppConstants.refreshTokenEndpoint,
                  data: {'refreshToken': refreshToken},
                );
                
                if (refreshResponse.statusCode == 200) {
                  final responseData = refreshResponse.data;
                  if (responseData['success'] == true && responseData['data'] != null) {
                    final authData = responseData['data'] as Map<String, dynamic>;
                    final newToken = authData['token'] as String;
                    final newRefreshToken = authData['refreshToken'] as String?;
                    
                    // Save new tokens
                    await prefs.setString(AppConstants.tokenKey, newToken);
                    if (newRefreshToken != null) {
                      await prefs.setString(AppConstants.refreshTokenKey, newRefreshToken);
                    }
                    
                    // Retry the original request with new token
                    error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                    final response = await _dio.fetch(error.requestOptions);
                    return handler.resolve(response);
                  }
                }
              } catch (e) {
                // Refresh failed, clear auth data
                await _clearAuthData();
              }
            } else {
              // No refresh token or refresh endpoint failed - clear storage
              await _clearAuthData();
            }
          }
          return handler.next(error);
        },
      ),
    );
    
    // Add retry interceptor for transient failures
    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
  }
}

/// Retry interceptor for handling transient failures
/// Automatically retries failed requests for server errors (5xx)
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const List<int> _retryableStatusCodes = [500, 502, 503, 504];

  _RetryInterceptor(this.dio);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if we should retry
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    
    if (_shouldRetry(err) && retryCount < _maxRetries) {
      // Increment retry count
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      
      // Wait before retrying (exponential backoff)
      await Future.delayed(_retryDelay * (retryCount + 1));
      
      try {
        // Retry the request
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // If retry fails, pass to next handler
        if (e is DioException) {
          return handler.next(e);
        }
        return handler.next(err);
      }
    }
    
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on connection timeout
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    
    // Retry on connection errors
    if (err.type == DioExceptionType.connectionError) {
      return true;
    }
    
    // Retry on specific status codes
    if (err.response?.statusCode != null &&
        _retryableStatusCodes.contains(err.response!.statusCode)) {
      return true;
    }
    
    return false;
  }
}


import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userRole => _user?['role'] as String?;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.tokenKey);
      _refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      final userString = prefs.getString(AppConstants.userKey);
      
      // If we have a refresh token but no access token, try to refresh
      if (_refreshToken != null && _token == null) {
        final refreshed = await _refreshAccessToken();
        if (refreshed && userString != null) {
          try {
            _user = jsonDecode(userString) as Map<String, dynamic>;
            _isAuthenticated = true;
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            await _clearAuthData();
          }
        }
      } else if (_token != null && userString != null) {
        try {
          // Parse user data from JSON string
          _user = jsonDecode(userString) as Map<String, dynamic>;
          _isAuthenticated = true;
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          // Clear invalid data
          await _clearAuthData();
        }
      }
    } catch (e) {
      debugPrint('Error loading auth data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _lastError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
        },
      );

      if (response.statusCode == 200) {
        // API returns ApiResponse wrapper: { success: true, data: { token, user }, ... }
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final authData = responseData['data'] as Map<String, dynamic>;
          final user = authData['user'] as Map<String, dynamic>;
          
          // Only allow ADMIN and HR_MANAGER roles to login
          final role = user['role'] as String?;
          if (role != AppConstants.roleAdmin && role != AppConstants.roleHrManager) {
            _lastError = 'Access denied. This app is for administrators and HR managers only. Please use the Employee app.';
            notifyListeners();
            return false;
          }
          
          _token = authData['token'] as String;
          _refreshToken = authData['refreshToken'] as String?;
          _user = user;
          _isAuthenticated = true;

          // Save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, _token!);
          if (_refreshToken != null) {
            await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
          }
          await prefs.setString(AppConstants.userKey, jsonEncode(_user));

          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      // Handle DioError for better error messages
      if (e is DioException) {
        final response = e.response;
        if (response != null && response.data != null) {
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            _lastError = errorData['message'] as String? ?? 'Login failed. Please check your credentials.';
          } else {
            _lastError = 'Login failed. Please check your credentials.';
          }
        } else {
          _lastError = 'Network error. Please check your connection.';
        }
      } else {
        _lastError = e.toString().replaceFirst('Exception: ', '');
      }
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _lastError;
  String? get lastError => _lastError;

  Future<void> logout() async {
    try {
      if (_token != null || _refreshToken != null) {
        await _apiService.post(
          AppConstants.logoutEndpoint,
          data: _refreshToken != null ? {'refreshToken': _refreshToken} : null,
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _clearAuthData();
    }
  }

  Future<void> _clearAuthData() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);

    notifyListeners();
  }

  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        return false;
      }

      final response = await _apiService.post(
        AppConstants.refreshTokenEndpoint,
        data: {
          'refreshToken': _refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final authData = responseData['data'] as Map<String, dynamic>;
          _token = authData['token'] as String;
          final newRefreshToken = authData['refreshToken'] as String?;
          if (newRefreshToken != null) {
            _refreshToken = newRefreshToken;
          }

          // Save updated tokens
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, _token!);
          if (_refreshToken != null) {
            await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
          }

          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await _clearAuthData();
      return false;
    }
  }

  Future<bool> refreshTokenIfNeeded() async {
    if (_refreshToken != null && (_token == null || await _isTokenExpired())) {
      return await _refreshAccessToken();
    }
    return true;
  }

  Future<bool> _isTokenExpired() async {
    if (_token == null) return true;
    try {
      // Simple check - if token exists, assume it's valid for now
      // The API will return 401 if it's actually expired
      return false;
    } catch (e) {
      return true;
    }
  }

  bool hasRole(String role) {
    return userRole == role;
  }

  bool hasAnyRole(List<String> roles) {
    return roles.contains(userRole);
  }

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _lastError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.signupEndpoint,
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'confirmPassword': password,
        },
      );

      debugPrint('Signup response status: ${response.statusCode}');
      debugPrint('Signup response data: ${response.data}');

      // Check for successful response (200-299 status codes)
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // Check if success is true (handle both bool and string representations)
          final success = responseData['success'];
          final isSuccess = success == true || success == 'true' || success == 1;
          
          if (isSuccess) {
            debugPrint('Signup successful!');
            _lastError = null; // Clear any previous errors
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            // Success field is false, extract error message
            _lastError = responseData['message'] as String? ?? 'Signup failed. Please try again.';
            debugPrint('Signup failed: $_lastError');
            notifyListeners();
            return false;
          }
        } else {
          // Unexpected response format
          _lastError = 'Unexpected response format from server.';
          debugPrint('Unexpected response format: $responseData');
          notifyListeners();
          return false;
        }
      } else {
        // Non-success status code
        _lastError = 'Signup failed with status code: ${response.statusCode}';
        debugPrint('Signup failed with status: ${response.statusCode}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      if (e is DioException) {
        final response = e.response;
        debugPrint('Signup error status: ${response?.statusCode}');
        debugPrint('Signup error data: ${response?.data}');
        
        if (response != null && response.data != null) {
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            // Try to extract error message from different response formats
            String? errorMessage;
            
            // Check for direct message field
            if (errorData['message'] != null) {
              errorMessage = errorData['message'] as String?;
            }
            
            // Check for validation errors in data field
            if (errorMessage == null && errorData['data'] != null) {
              final data = errorData['data'];
              if (data is Map<String, dynamic>) {
                // Extract first validation error
                final firstError = data.values.first;
                if (firstError is String) {
                  errorMessage = firstError;
                } else if (data.isNotEmpty) {
                  errorMessage = data.values.first.toString();
                }
              }
            }
            
            // Check for error field
            if (errorMessage == null && errorData['error'] != null) {
              errorMessage = errorData['error'] as String?;
            }
            
            _lastError = errorMessage ?? 'Signup failed. Please try again.';
          } else {
            _lastError = 'Signup failed. Please try again.';
          }
        } else {
          // Check error type for more specific messages
          if (e.type == DioExceptionType.connectionTimeout) {
            _lastError = 'Connection timeout. Please check your internet connection.';
          } else if (e.type == DioExceptionType.connectionError) {
            _lastError = 'Cannot connect to server. Please check your internet connection.';
          } else {
            _lastError = 'Network error. Please check your connection.';
          }
        }
      } else {
        _lastError = e.toString().replaceFirst('Exception: ', '');
      }
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp({required String email}) async {
    _lastError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.sendOtpEndpoint,
        data: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Send OTP error: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null && response.data != null) {
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            _lastError = errorData['message'] as String? ?? 'Failed to send OTP. Please try again.';
          } else {
            _lastError = 'Failed to send OTP. Please try again.';
          }
        } else {
          _lastError = 'Network error. Please check your connection.';
        }
      } else {
        _lastError = e.toString().replaceFirst('Exception: ', '');
      }
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _lastError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.verifyOtpEndpoint,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final authData = responseData['data'] as Map<String, dynamic>;
          _token = authData['token'] as String;
          _refreshToken = authData['refreshToken'] as String?;
          _user = authData['user'] as Map<String, dynamic>;
          _isAuthenticated = true;

          // Save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, _token!);
          if (_refreshToken != null) {
            await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
          }
          await prefs.setString(AppConstants.userKey, jsonEncode(_user));

          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null && response.data != null) {
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            _lastError = errorData['message'] as String? ?? 'OTP verification failed. Please try again.';
          } else {
            _lastError = 'OTP verification failed. Please try again.';
          }
        } else {
          _lastError = 'Network error. Please check your connection.';
        }
      } else {
        _lastError = e.toString().replaceFirst('Exception: ', '');
      }
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


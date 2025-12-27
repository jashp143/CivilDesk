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
  String? _lastError;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String? get userRole => _user?['role'] as String?;
  int? get userId => _user?['id'] as int?;
  String? get userName => '${_user?['firstName'] ?? ''} ${_user?['lastName'] ?? ''}'.trim();

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
            // Only allow EMPLOYEE role in this app
            if (_user?['role'] == AppConstants.roleEmployee) {
              _isAuthenticated = true;
            } else {
              await _clearAuthData();
            }
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            await _clearAuthData();
          }
        }
      } else if (_token != null && userString != null) {
        try {
          _user = jsonDecode(userString) as Map<String, dynamic>;
          // Only allow EMPLOYEE role in this app
          if (_user?['role'] == AppConstants.roleEmployee) {
            _isAuthenticated = true;
          } else {
            await _clearAuthData();
          }
        } catch (e) {
          debugPrint('Error parsing user data: $e');
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
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final authData = responseData['data'] as Map<String, dynamic>;
          final user = authData['user'] as Map<String, dynamic>;
          
          // Only allow EMPLOYEE role to login
          if (user['role'] != AppConstants.roleEmployee) {
            _lastError = 'Access denied. This app is for employees only.';
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

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    _lastError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.changePasswordEndpoint,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
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
      debugPrint('Change password error: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null && response.data != null) {
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            _lastError = errorData['message'] as String? ?? 'Failed to change password. Please try again.';
          } else {
            _lastError = 'Failed to change password. Please try again.';
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

  Future<bool> forgotPassword(String email) async {
    _lastError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.forgotPasswordEndpoint,
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
      debugPrint('Forgot password error: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null && response.data != null) {
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            _lastError = errorData['message'] as String? ?? 'Failed to send password reset OTP. Please try again.';
          } else {
            _lastError = 'Failed to send password reset OTP. Please try again.';
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

  Future<bool> resetPassword(String email, String otp, String newPassword, String confirmPassword) async {
    _lastError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.resetPasswordEndpoint,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
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
      debugPrint('Reset password error: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null && response.data != null) {
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            _lastError = errorData['message'] as String? ?? 'Failed to reset password. Please try again.';
          } else {
            _lastError = 'Failed to reset password. Please try again.';
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


import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _token;
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
      final userString = prefs.getString(AppConstants.userKey);
      
      if (_token != null && userString != null) {
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

  Future<bool> login(String email, String password) async {
    _lastError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // API returns ApiResponse wrapper: { success: true, data: { token, user }, ... }
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final authData = responseData['data'] as Map<String, dynamic>;
          _token = authData['token'] as String;
          _user = authData['user'] as Map<String, dynamic>;
          _isAuthenticated = true;

          // Save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, _token!);
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
      if (_token != null) {
        await _apiService.post(AppConstants.logoutEndpoint);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _clearAuthData();
    }
  }

  Future<void> _clearAuthData() async {
    _token = null;
    _user = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);

    notifyListeners();
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

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Signup error: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null && response.data != null) {
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            _lastError = errorData['message'] as String? ?? 'Signup failed. Please try again.';
          } else {
            _lastError = 'Signup failed. Please try again.';
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
          _user = authData['user'] as Map<String, dynamic>;
          _isAuthenticated = true;

          // Save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, _token!);
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


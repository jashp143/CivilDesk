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
      final userString = prefs.getString(AppConstants.userKey);
      
      if (_token != null && userString != null) {
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
          _user = user;
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
}


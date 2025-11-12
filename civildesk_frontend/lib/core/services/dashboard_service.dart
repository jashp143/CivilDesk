import 'package:dio/dio.dart';
import '../../models/dashboard_stats.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _apiService = ApiService();
  static const String _basePath = '/dashboard';

  Future<DashboardStats> getAdminDashboardStats() async {
    try {
      final response = await _apiService.get('$_basePath/admin');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return DashboardStats.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch admin dashboard stats');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<DashboardStats> getHrDashboardStats() async {
    try {
      final response = await _apiService.get('$_basePath/hr');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return DashboardStats.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch HR dashboard stats');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<EmployeeDashboardStats> getEmployeeDashboardStats() async {
    try {
      final response = await _apiService.get('$_basePath/employee');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return EmployeeDashboardStats.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch employee dashboard stats');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'] as String;
      }
      return 'Error: ${error.response?.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }
    return error.message ?? 'An unexpected error occurred';
  }
}


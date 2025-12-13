import 'package:dio/dio.dart';
import '../../models/employee.dart';
import 'api_service.dart';

class EmployeeService {
  final ApiService _apiService = ApiService();

  // Get all employees (for handover dropdown)
  Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await _apiService.get('/employees');

      if (response.data['success']) {
        final List<dynamic> employeesJson = response.data['data']['content'] ?? response.data['data'];
        return employeesJson.map((json) => Employee.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch employees');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch employees');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get current employee details (uses /me endpoint for better security)
  Future<Map<String, dynamic>> getCurrentEmployeeDetails() async {
    try {
      final response = await _apiService.get('/employees/me');

      if (response.data['success'] && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch employee details');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch employee details');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get employee details by user ID (fallback method)
  Future<Map<String, dynamic>> getEmployeeDetailsByUserId(int userId) async {
    try {
      final response = await _apiService.get('/employees/user/$userId');

      if (response.data['success'] && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch employee details');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch employee details');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

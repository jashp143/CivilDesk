import 'package:dio/dio.dart';
import '../../models/employee.dart';
import 'api_service.dart';

class EmployeeService {
  final ApiService _apiService = ApiService();

  // Get all employees (for handover dropdown) - uses new endpoint accessible to employees
  Future<List<Employee>> getAllEmployees({String? search}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': 0,
        'size': 100, // Get a large number of employees for dropdown
        'sortBy': 'firstName',
        'sortDir': 'ASC',
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiService.get(
        '/employees/for-handover',
        queryParameters: queryParams,
      );

      if (response.data['success']) {
        final data = response.data['data'];
        // Handle paginated response
        if (data is Map && data.containsKey('content')) {
          final List<dynamic> employeesJson = data['content'];
          return employeesJson.map((json) => Employee.fromJson(json)).toList();
        } else if (data is List) {
          return data.map((json) => Employee.fromJson(json)).toList();
        } else {
          return [];
        }
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

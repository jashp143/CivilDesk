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
}

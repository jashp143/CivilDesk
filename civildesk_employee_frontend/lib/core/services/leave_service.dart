import 'package:dio/dio.dart';
import '../../models/leave.dart';
import 'api_service.dart';

class LeaveService {
  final ApiService _apiService = ApiService();

  // Apply for leave
  Future<Leave> applyLeave(LeaveRequest request) async {
    try {
      final response = await _apiService.post(
        '/leaves',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Leave.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to apply for leave');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to apply for leave');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Update leave
  Future<Leave> updateLeave(int leaveId, LeaveRequest request) async {
    try {
      final response = await _apiService.put(
        '/leaves/$leaveId',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Leave.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update leave');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update leave');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Delete leave
  Future<void> deleteLeave(int leaveId) async {
    try {
      final response = await _apiService.delete('/leaves/$leaveId');

      if (!response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to delete leave');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete leave');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get my leaves
  Future<List<Leave>> getMyLeaves() async {
    try {
      final response = await _apiService.get('/leaves/my-leaves');

      if (response.data['success']) {
        final List<dynamic> leavesJson = response.data['data'];
        return leavesJson.map((json) => Leave.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch leaves');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch leaves');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get my responsibilities
  Future<List<Leave>> getMyResponsibilities() async {
    try {
      final response = await _apiService.get('/leaves/my-responsibilities');

      if (response.data['success']) {
        final List<dynamic> leavesJson = response.data['data'];
        return leavesJson.map((json) => Leave.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch responsibilities');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch responsibilities');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get leave by ID
  Future<Leave> getLeaveById(int leaveId) async {
    try {
      final response = await _apiService.get('/leaves/$leaveId');

      if (response.data['success']) {
        return Leave.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch leave details');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch leave details');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Upload medical certificate
  Future<String> uploadMedicalCertificate(String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.post(
        '/api/upload/medical-certificate',
        data: formData,
      );

      if (response.data['success']) {
        return response.data['data']['url'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload certificate');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to upload certificate');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

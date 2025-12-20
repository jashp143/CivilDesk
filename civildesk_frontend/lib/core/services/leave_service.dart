import 'package:dio/dio.dart';
import '../../models/leave.dart';
import '../../models/page_response.dart';
import 'api_service.dart';

class LeaveService {
  final ApiService _apiService = ApiService();

  // Get all leaves
  Future<List<Leave>> getAllLeaves({
    String? status,
    String? leaveType,
    String? department,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (leaveType != null && leaveType.isNotEmpty) {
        queryParams['leaveType'] = leaveType;
      }
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }

      final response = await _apiService.get(
        '/leaves',
        queryParameters: queryParams,
      );

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

  // Get all leaves with pagination
  Future<PageResponse<Leave>> getAllLeavesPaginated({
    String? status,
    String? leaveType,
    String? department,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'DESC',
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (leaveType != null && leaveType.isNotEmpty) {
        queryParams['leaveType'] = leaveType;
      }
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }

      final response = await _apiService.get(
        '/leaves',
        queryParameters: queryParams,
      );

      if (response.data['success']) {
        final data = response.data['data'];
        // Check if response is paginated (has 'content' field) or a list
        if (data is Map && data.containsKey('content')) {
          return PageResponse.fromJson(
            data as Map<String, dynamic>,
            (json) => Leave.fromJson(json),
          );
        } else {
          // Fallback for non-paginated response
          final List<dynamic> leavesJson = data as List<dynamic>;
          final leaves = leavesJson.map((json) => Leave.fromJson(json)).toList();
          return PageResponse<Leave>(
            content: leaves,
            totalElements: leaves.length,
            totalPages: 1,
            size: leaves.length,
            number: 0,
            first: true,
            last: true,
          );
        }
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

  // Review leave (Approve/Reject)
  Future<Leave> reviewLeave(int leaveId, LeaveReviewRequest request) async {
    try {
      final response = await _apiService.put(
        '/leaves/$leaveId/review',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Leave.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to review leave');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to review leave');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get unique departments from leaves
  Future<List<String>> getDepartments() async {
    try {
      final leaves = await getAllLeaves();
      final departments = leaves
          .where((leave) => leave.department != null && leave.department!.isNotEmpty)
          .map((leave) => leave.department!)
          .toSet()
          .toList();
      departments.sort();
      return departments;
    } catch (e) {
      return [];
    }
  }
}

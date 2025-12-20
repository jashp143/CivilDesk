import 'package:dio/dio.dart';
import '../../models/task.dart';
import '../../models/page_response.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _apiService = ApiService();

  // Get my tasks
  Future<List<Task>> getMyTasks() async {
    try {
      final response = await _apiService.get('/tasks/my-tasks');

      if (response.data['success']) {
        final List<dynamic> tasksJson = response.data['data'];
        return tasksJson.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch tasks');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch tasks');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get my tasks with pagination
  Future<PageResponse<Task>> getMyTasksPaginated({
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'DESC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };

      final response = await _apiService.get(
        '/tasks/my-tasks',
        queryParameters: queryParams,
      );

      if (response.data['success']) {
        final data = response.data['data'];
        // Check if response is paginated (has 'content' field) or a list
        if (data is Map && data.containsKey('content')) {
          return PageResponse.fromJson(
            data as Map<String, dynamic>,
            (json) => Task.fromJson(json),
          );
        } else {
          // Fallback for non-paginated response
          final List<dynamic> tasksJson = data as List<dynamic>;
          final tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
          return PageResponse<Task>(
            content: tasks,
            totalElements: tasks.length,
            totalPages: 1,
            size: tasks.length,
            number: 0,
            first: true,
            last: true,
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch tasks');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch tasks');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get task by ID
  Future<Task> getTaskById(int taskId) async {
    try {
      final response = await _apiService.get('/tasks/$taskId');

      if (response.data['success']) {
        return Task.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch task');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch task');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Review task (Approve/Reject)
  Future<Task> reviewTask(int taskId, TaskStatus status, String? reviewNote) async {
    try {
      final response = await _apiService.put(
        '/tasks/$taskId/review',
        data: {
          'status': status.toString().split('.').last,
          'reviewNote': reviewNote,
        },
      );

      if (response.data['success']) {
        return Task.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to review task');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to review task');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

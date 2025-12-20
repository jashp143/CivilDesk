import 'package:dio/dio.dart';
import '../../models/task.dart';
import '../../models/page_response.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _apiService = ApiService();

  // Assign task
  Future<Task> assignTask(TaskRequest request) async {
    try {
      final response = await _apiService.post(
        '/tasks',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Task.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to assign task');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to assign task');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Update task
  Future<Task> updateTask(int taskId, TaskRequest request) async {
    try {
      final response = await _apiService.put(
        '/tasks/$taskId',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Task.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update task');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update task');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Delete task
  Future<void> deleteTask(int taskId) async {
    try {
      final response = await _apiService.delete('/tasks/$taskId');

      if (!response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to delete task');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete task');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get all tasks (with pagination support)
  Future<List<Task>> getAllTasks({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/tasks',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

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

  // Get all tasks with pagination
  Future<PageResponse<Task>> getAllTasksPaginated({
    String? status,
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
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/tasks',
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
}

import 'package:dio/dio.dart';
import '../../models/task.dart';
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

  // Get all tasks
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

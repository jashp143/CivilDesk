import 'package:dio/dio.dart';
import '../../models/task.dart';
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

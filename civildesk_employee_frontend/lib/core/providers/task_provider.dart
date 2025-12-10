import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  TaskStatus? _selectedStatusFilter;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskStatus? get selectedStatusFilter => _selectedStatusFilter;

  // Get filtered tasks
  List<Task> get filteredTasks {
    if (_selectedStatusFilter == null) {
      return _tasks;
    }
    return _tasks.where((task) => task.status == _selectedStatusFilter).toList();
  }

  // Set status filter
  void setStatusFilter(TaskStatus? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  // Clear filter
  void clearFilter() {
    _selectedStatusFilter = null;
    notifyListeners();
  }

  // Fetch my tasks
  Future<void> fetchMyTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getMyTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get task by ID
  Future<Task?> getTaskById(int taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final task = await _taskService.getTaskById(taskId);
      _isLoading = false;
      notifyListeners();
      return task;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Review task (Approve/Reject)
  Future<bool> reviewTask(int taskId, TaskStatus status, String? reviewNote) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.reviewTask(taskId, status, reviewNote);
      await fetchMyTasks(); // Refresh tasks list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

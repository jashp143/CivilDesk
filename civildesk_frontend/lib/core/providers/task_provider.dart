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

  // Assign task
  Future<bool> assignTask(TaskRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.assignTask(request);
      await fetchAllTasks(); // Refresh tasks list
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

  // Update task
  Future<bool> updateTask(int taskId, TaskRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.updateTask(taskId, request);
      await fetchAllTasks(); // Refresh tasks list
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

  // Delete task
  Future<bool> deleteTask(int taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.deleteTask(taskId);
      await fetchAllTasks(); // Refresh tasks list
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

  // Fetch all tasks
  Future<void> fetchAllTasks({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getAllTasks(status: status);
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
}

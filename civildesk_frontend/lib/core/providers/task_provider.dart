import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  TaskStatus? _selectedStatusFilter;
  
  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  bool _isInitialLoad = true; // Track if this is the first load

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskStatus? get selectedStatusFilter => _selectedStatusFilter;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;

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
      await refreshTasks(); // Refresh tasks list
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
      await refreshTasks(); // Refresh tasks list
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
      _tasks.removeWhere((task) => task.id == taskId);
      _totalElements--;
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

  // Get page size: 25 for first load, 10 for subsequent loads
  int _getPageSize() {
    return _isInitialLoad ? 25 : 10;
  }

  // Fetch all tasks (with pagination support)
  Future<void> fetchAllTasks({String? status, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _tasks.clear();
      _hasMore = true;
      _isInitialLoad = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageSize = _getPageSize();
      final pageResponse = await _taskService.getAllTasksPaginated(
        status: status,
        page: _currentPage,
        size: pageSize,
      );

      if (refresh || _currentPage == 0) {
        _tasks = pageResponse.content;
      } else {
        _tasks.addAll(pageResponse.content);
      }

      _currentPage = pageResponse.number;
      _totalPages = pageResponse.totalPages;
      _totalElements = pageResponse.totalElements;
      _hasMore = pageResponse.hasMore;
      _isInitialLoad = false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more tasks (next page)
  Future<void> loadMoreTasks() async {
    if (!_hasMore || _isLoading) return;
    await fetchAllTasks(
      status: _selectedStatusFilter?.toString().split('.').last,
      refresh: false,
    );
  }

  // Refresh tasks (reload from beginning)
  Future<void> refreshTasks() async {
    await fetchAllTasks(
      status: _selectedStatusFilter?.toString().split('.').last,
      refresh: true,
    );
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

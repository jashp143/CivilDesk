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
  final int _pageSize = 20;

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

  // Fetch my tasks (with pagination support)
  Future<void> fetchMyTasks({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _tasks.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageResponse = await _taskService.getMyTasksPaginated(
        page: _currentPage,
        size: _pageSize,
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
    await fetchMyTasks(refresh: false);
  }

  // Refresh tasks (reload from beginning)
  Future<void> refreshTasks() async {
    await fetchMyTasks(refresh: true);
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
}

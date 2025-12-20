import 'package:flutter/material.dart';
import '../../models/leave.dart';
import '../services/leave_service.dart';

class LeaveProvider with ChangeNotifier {
  final LeaveService _leaveService = LeaveService();

  List<Leave> _leaves = [];
  List<Leave> _filteredLeaves = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  final int _pageSize = 20;

  // Filters
  String? _selectedStatus;
  String? _selectedLeaveType;
  String? _selectedDepartment;
  List<String> _departments = [];

  List<Leave> get leaves => _filteredLeaves;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;
  String? get selectedStatus => _selectedStatus;
  String? get selectedLeaveType => _selectedLeaveType;
  String? get selectedDepartment => _selectedDepartment;
  List<String> get departments => _departments;

  // Fetch all leaves (with pagination support)
  Future<void> fetchAllLeaves({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _leaves.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageResponse = await _leaveService.getAllLeavesPaginated(
        status: _selectedStatus,
        leaveType: _selectedLeaveType,
        department: _selectedDepartment,
        page: _currentPage,
        size: _pageSize,
      );

      if (refresh || _currentPage == 0) {
        _leaves = pageResponse.content;
      } else {
        _leaves.addAll(pageResponse.content);
      }

      _currentPage = pageResponse.number;
      _totalPages = pageResponse.totalPages;
      _totalElements = pageResponse.totalElements;
      _hasMore = pageResponse.hasMore;

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more leaves (next page)
  Future<void> loadMoreLeaves() async {
    if (!_hasMore || _isLoading) return;
    await fetchAllLeaves(refresh: false);
  }

  // Refresh leaves (reload from beginning)
  Future<void> refreshLeaves() async {
    await fetchAllLeaves(refresh: true);
  }

  // Apply filters
  void _applyFilters() {
    _filteredLeaves = List.from(_leaves);

    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      final status = LeaveStatus.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedStatus,
      );
      _filteredLeaves = _filteredLeaves.where((leave) => leave.status == status).toList();
    }

    if (_selectedLeaveType != null && _selectedLeaveType!.isNotEmpty) {
      final leaveType = LeaveType.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedLeaveType,
      );
      _filteredLeaves = _filteredLeaves.where((leave) => leave.leaveType == leaveType).toList();
    }

    if (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) {
      _filteredLeaves = _filteredLeaves
          .where((leave) => leave.department == _selectedDepartment)
          .toList();
    }

    // Extract unique departments for filter dropdown
    _departments = _leaves
        .where((leave) => leave.department != null && leave.department!.isNotEmpty)
        .map((leave) => leave.department!)
        .toSet()
        .toList();
    _departments.sort();
  }

  // Set status filter
  void setStatusFilter(String? status) {
    _selectedStatus = status;
    refreshLeaves(); // Reload with new filter
  }

  // Set leave type filter
  void setLeaveTypeFilter(String? leaveType) {
    _selectedLeaveType = leaveType;
    refreshLeaves(); // Reload with new filter
  }

  // Set department filter
  void setDepartmentFilter(String? department) {
    _selectedDepartment = department;
    refreshLeaves(); // Reload with new filter
  }

  // Clear all filters
  void clearFilters() {
    _selectedStatus = null;
    _selectedLeaveType = null;
    _selectedDepartment = null;
    refreshLeaves(); // Reload without filters
  }

  // Review leave
  Future<bool> reviewLeave(int leaveId, LeaveStatus status, String? note) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LeaveReviewRequest(status: status, reviewNote: note);
      await _leaveService.reviewLeave(leaveId, request);
      await refreshLeaves(); // Refresh leaves list
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

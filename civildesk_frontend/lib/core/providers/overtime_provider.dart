import 'package:flutter/material.dart';
import '../../models/overtime.dart';
import '../services/overtime_service.dart';

class OvertimeProvider with ChangeNotifier {
  final OvertimeService _overtimeService = OvertimeService();

  List<Overtime> _overtimes = [];
  List<Overtime> _filteredOvertimes = [];
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
  String? _selectedDepartment;
  List<String> _departments = [];

  List<Overtime> get overtimes => _filteredOvertimes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;
  String? get selectedStatus => _selectedStatus;
  String? get selectedDepartment => _selectedDepartment;
  List<String> get departments => _departments;

  // Fetch all overtimes (with pagination support)
  Future<void> fetchAllOvertimes({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _overtimes.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageResponse = await _overtimeService.getAllOvertimesPaginated(
        status: _selectedStatus,
        department: _selectedDepartment,
        page: _currentPage,
        size: _pageSize,
      );

      if (refresh || _currentPage == 0) {
        _overtimes = pageResponse.content;
      } else {
        _overtimes.addAll(pageResponse.content);
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

  // Load more overtimes (next page)
  Future<void> loadMoreOvertimes() async {
    if (!_hasMore || _isLoading) return;
    await fetchAllOvertimes(refresh: false);
  }

  // Refresh overtimes (reload from beginning)
  Future<void> refreshOvertimes() async {
    await fetchAllOvertimes(refresh: true);
  }

  // Apply filters
  void _applyFilters() {
    _filteredOvertimes = List.from(_overtimes);

    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      final status = OvertimeStatus.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedStatus,
      );
      _filteredOvertimes = _filteredOvertimes.where((overtime) => overtime.status == status).toList();
    }

    if (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) {
      _filteredOvertimes = _filteredOvertimes
          .where((overtime) => overtime.department == _selectedDepartment)
          .toList();
    }

    // Extract unique departments for filter dropdown
    _departments = _overtimes
        .where((overtime) => overtime.department != null && overtime.department!.isNotEmpty)
        .map((overtime) => overtime.department!)
        .toSet()
        .toList();
    _departments.sort();
  }

  // Set status filter
  void setStatusFilter(String? status) {
    _selectedStatus = status;
    refreshOvertimes(); // Reload with new filter
  }

  // Set department filter
  void setDepartmentFilter(String? department) {
    _selectedDepartment = department;
    refreshOvertimes(); // Reload with new filter
  }

  // Clear all filters
  void clearFilters() {
    _selectedStatus = null;
    _selectedDepartment = null;
    refreshOvertimes(); // Reload without filters
  }

  // Review overtime
  Future<bool> reviewOvertime(int overtimeId, OvertimeStatus status, String? note) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = OvertimeReviewRequest(
        status: status,
        reviewNote: note,
      );
      await _overtimeService.reviewOvertime(overtimeId, request);
      await refreshOvertimes(); // Refresh overtimes list
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

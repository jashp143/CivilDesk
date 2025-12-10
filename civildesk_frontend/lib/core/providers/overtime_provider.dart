import 'package:flutter/material.dart';
import '../../models/overtime.dart';
import '../services/overtime_service.dart';

class OvertimeProvider with ChangeNotifier {
  final OvertimeService _overtimeService = OvertimeService();

  List<Overtime> _overtimes = [];
  List<Overtime> _filteredOvertimes = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _selectedStatus;
  String? _selectedDepartment;
  List<String> _departments = [];

  List<Overtime> get overtimes => _filteredOvertimes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedStatus => _selectedStatus;
  String? get selectedDepartment => _selectedDepartment;
  List<String> get departments => _departments;

  // Fetch all overtimes
  Future<void> fetchAllOvertimes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _overtimes = await _overtimeService.getAllOvertimes();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
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
    _applyFilters();
    notifyListeners();
  }

  // Set department filter
  void setDepartmentFilter(String? department) {
    _selectedDepartment = department;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _selectedStatus = null;
    _selectedDepartment = null;
    _applyFilters();
    notifyListeners();
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
      await fetchAllOvertimes(); // Refresh overtimes list
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

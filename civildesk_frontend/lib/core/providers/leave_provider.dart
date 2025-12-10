import 'package:flutter/material.dart';
import '../../models/leave.dart';
import '../services/leave_service.dart';

class LeaveProvider with ChangeNotifier {
  final LeaveService _leaveService = LeaveService();

  List<Leave> _leaves = [];
  List<Leave> _filteredLeaves = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _selectedStatus;
  String? _selectedLeaveType;
  String? _selectedDepartment;
  List<String> _departments = [];

  List<Leave> get leaves => _filteredLeaves;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedStatus => _selectedStatus;
  String? get selectedLeaveType => _selectedLeaveType;
  String? get selectedDepartment => _selectedDepartment;
  List<String> get departments => _departments;

  // Fetch all leaves
  Future<void> fetchAllLeaves() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaves = await _leaveService.getAllLeaves();
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
    _applyFilters();
    notifyListeners();
  }

  // Set leave type filter
  void setLeaveTypeFilter(String? leaveType) {
    _selectedLeaveType = leaveType;
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
    _selectedLeaveType = null;
    _selectedDepartment = null;
    _applyFilters();
    notifyListeners();
  }

  // Review leave
  Future<bool> reviewLeave(int leaveId, LeaveStatus status, String? note) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LeaveReviewRequest(status: status, reviewNote: note);
      await _leaveService.reviewLeave(leaveId, request);
      await fetchAllLeaves(); // Refresh leaves list
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

import 'package:flutter/material.dart';
import '../../models/leave.dart';
import '../services/leave_service.dart';

class LeaveProvider with ChangeNotifier {
  final LeaveService _leaveService = LeaveService();

  List<Leave> _leaves = [];
  List<Leave> _responsibilities = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state for leaves
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  final int _pageSize = 20;

  List<Leave> get leaves => _leaves;
  List<Leave> get responsibilities => _responsibilities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;

  // Apply for leave
  Future<bool> applyLeave(LeaveRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.applyLeave(request);
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

  // Update leave
  Future<bool> updateLeave(int leaveId, LeaveRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.updateLeave(leaveId, request);
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

  // Delete leave
  Future<bool> deleteLeave(int leaveId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.deleteLeave(leaveId);
      _leaves.removeWhere((leave) => leave.id == leaveId);
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

  // Fetch my leaves (with pagination support)
  Future<void> fetchMyLeaves({bool refresh = false}) async {
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
      final pageResponse = await _leaveService.getMyLeavesPaginated(
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
    await fetchMyLeaves(refresh: false);
  }

  // Refresh leaves (reload from beginning)
  Future<void> refreshLeaves() async {
    await fetchMyLeaves(refresh: true);
  }

  // Fetch my responsibilities
  Future<void> fetchMyResponsibilities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _responsibilities = await _leaveService.getMyResponsibilities();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload medical certificate
  Future<String?> uploadMedicalCertificate(String filePath) async {
    try {
      return await _leaveService.uploadMedicalCertificate(filePath);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

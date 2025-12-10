import 'package:flutter/material.dart';
import '../../models/leave.dart';
import '../services/leave_service.dart';

class LeaveProvider with ChangeNotifier {
  final LeaveService _leaveService = LeaveService();

  List<Leave> _leaves = [];
  List<Leave> _responsibilities = [];
  bool _isLoading = false;
  String? _error;

  List<Leave> get leaves => _leaves;
  List<Leave> get responsibilities => _responsibilities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Apply for leave
  Future<bool> applyLeave(LeaveRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.applyLeave(request);
      await fetchMyLeaves(); // Refresh leaves list
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
      await fetchMyLeaves(); // Refresh leaves list
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
      await fetchMyLeaves(); // Refresh leaves list
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

  // Fetch my leaves
  Future<void> fetchMyLeaves() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaves = await _leaveService.getMyLeaves();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
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

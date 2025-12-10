import 'package:flutter/material.dart';
import '../../models/overtime.dart';
import '../services/overtime_service.dart';

class OvertimeProvider with ChangeNotifier {
  final OvertimeService _overtimeService = OvertimeService();

  List<Overtime> _overtimes = [];
  bool _isLoading = false;
  String? _error;

  List<Overtime> get overtimes => _overtimes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Apply for overtime
  Future<bool> applyOvertime(OvertimeRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _overtimeService.applyOvertime(request);
      await fetchMyOvertimes(); // Refresh overtimes list
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

  // Update overtime
  Future<bool> updateOvertime(int overtimeId, OvertimeRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _overtimeService.updateOvertime(overtimeId, request);
      await fetchMyOvertimes(); // Refresh overtimes list
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

  // Delete overtime
  Future<bool> deleteOvertime(int overtimeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _overtimeService.deleteOvertime(overtimeId);
      await fetchMyOvertimes(); // Refresh overtimes list
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

  // Fetch my overtimes
  Future<void> fetchMyOvertimes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _overtimes = await _overtimeService.getMyOvertimes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

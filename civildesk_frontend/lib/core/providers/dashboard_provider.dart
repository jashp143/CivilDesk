import 'package:flutter/foundation.dart';
import '../../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  DashboardStats? _adminStats;
  EmployeeDashboardStats? _employeeStats;
  bool _isLoading = false;
  String? _error;

  DashboardStats? get adminStats => _adminStats;
  EmployeeDashboardStats? get employeeStats => _employeeStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAdminDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _adminStats = await _dashboardService.getAdminDashboardStats();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading admin dashboard stats: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHrDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _adminStats = await _dashboardService.getHrDashboardStats();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading HR dashboard stats: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEmployeeDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _employeeStats = await _dashboardService.getEmployeeDashboardStats();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading employee dashboard stats: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearStats() {
    _adminStats = null;
    _employeeStats = null;
    _error = null;
    notifyListeners();
  }
}


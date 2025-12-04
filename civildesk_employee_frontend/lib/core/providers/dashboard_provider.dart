import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/dashboard_stats.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  EmployeeDashboardStats? _dashboardStats;
  bool _isLoading = false;
  String? _error;

  EmployeeDashboardStats? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.dashboardEndpoint);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          _dashboardStats = EmployeeDashboardStats.fromJson(
            responseData['data'] as Map<String, dynamic>,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      if (e is DioException) {
        _error = e.response?.data?['message'] as String? ?? 'Failed to fetch dashboard data';
      } else {
        _error = 'Failed to fetch dashboard data';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


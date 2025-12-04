import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../models/attendance_analytics.dart';

class AttendanceAnalyticsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AttendanceAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;

  AttendanceAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAttendanceAnalytics(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await _apiService.get(
        '/attendance/analytics/$employeeId?startDate=$startDateStr&endDate=$endDateStr',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        _analytics = AttendanceAnalytics.fromJson(data);
        _error = null;
      } else {
        _error = response.data['message'] ?? 'Failed to fetch analytics';
        _analytics = null;
      }
    } catch (e) {
      _error = 'Error fetching attendance analytics: ${e.toString()}';
      _analytics = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearAnalytics() {
    _analytics = null;
    _error = null;
    notifyListeners();
  }
}


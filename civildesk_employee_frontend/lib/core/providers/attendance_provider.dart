import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/attendance.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Attendance> _attendanceList = [];
  Attendance? _todayAttendance;
  bool _isLoading = false;
  String? _error;

  List<Attendance> get attendanceList => _attendanceList;
  Attendance? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAttendanceHistory({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiService.get(
        '${AppConstants.attendanceEndpoint}/my-attendance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          _attendanceList = data
              .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
      if (e is DioException) {
        _error = e.response?.data?['message'] as String? ?? 'Failed to fetch attendance history';
      } else {
        _error = 'Failed to fetch attendance history';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodayAttendance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _apiService.get(
        '${AppConstants.attendanceEndpoint}/my-attendance',
        queryParameters: {'date': today},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          if (data.isNotEmpty) {
            _todayAttendance = Attendance.fromJson(data[0] as Map<String, dynamic>);
          } else {
            _todayAttendance = null;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching today attendance: $e');
      if (e is DioException) {
        _error = e.response?.data?['message'] as String? ?? 'Failed to fetch today\'s attendance';
      } else {
        _error = 'Failed to fetch today\'s attendance';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Note: Attendance marking is done by Admin/HR only
  // Employees can only view their attendance

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


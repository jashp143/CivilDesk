import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class AttendanceService {
  final ApiService _apiService = ApiService();

  /// Mark attendance using face recognition
  Future<Map<String, dynamic>> markAttendanceWithFace(
    File imageFile, {
    String attendanceType = 'PUNCH_IN',
    String? employeeId,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
        'attendance_type': attendanceType,
        if (employeeId != null) 'employee_id': employeeId,
      });

      final response = await _apiService.post(
        AppConstants.attendanceEndpoint + '/mark',
        data: formData,
      );

      return response.data;
    } catch (e) {
      throw Exception('Error marking attendance: $e');
    }
  }

  /// Mark attendance manually
  Future<Map<String, dynamic>> markAttendanceManual(String employeeId) async {
    try {
      FormData formData = FormData.fromMap({
        'employee_id': employeeId,
      });
      
      final response = await _apiService.post(
        AppConstants.attendanceEndpoint + '/mark',
        data: formData,
      );

      return response.data;
    } catch (e) {
      throw Exception('Error marking attendance: $e');
    }
  }

  /// Check out
  Future<Map<String, dynamic>> checkOut(String employeeId) async {
    try {
      FormData formData = FormData.fromMap({
        'employee_id': employeeId,
      });
      
      final response = await _apiService.post(
        AppConstants.attendanceEndpoint + '/checkout',
        data: formData,
      );

      return response.data;
    } catch (e) {
      throw Exception('Error during check-out: $e');
    }
  }

  /// Get today's attendance
  Future<Map<String, dynamic>> getTodayAttendance(String employeeId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.attendanceEndpoint}/today/$employeeId',
      );

      return response.data;
    } catch (e) {
      throw Exception('Error retrieving attendance: $e');
    }
  }

  /// Get employee attendance history
  Future<Map<String, dynamic>> getEmployeeAttendance(
    String employeeId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.attendanceEndpoint}/employee/$employeeId',
        queryParameters: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Error retrieving attendance history: $e');
    }
  }

  /// Get daily attendance overview
  Future<Map<String, dynamic>> getDailyAttendance({String? date}) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.attendanceEndpoint}/daily',
        queryParameters: {
          if (date != null) 'date': date,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Error retrieving daily attendance: $e');
    }
  }

  /// Update punch time (admin function)
  Future<Map<String, dynamic>> updatePunchTime({
    required int attendanceId,
    required String punchType, // CHECK_IN, LUNCH_OUT, LUNCH_IN, CHECK_OUT
    required DateTime newTime,
  }) async {
    try {
      // Format datetime as ISO 8601 string
      final timeString = newTime.toIso8601String();
      
      final response = await _apiService.put(
        '${AppConstants.attendanceEndpoint}/update-punch-time',
        queryParameters: {
          'attendance_id': attendanceId.toString(),
          'punch_type': punchType,
          'new_time': timeString,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Error updating punch time: $e');
    }
  }

  /// Mark employee as absent for a specific date (admin function)
  Future<Map<String, dynamic>> markAbsent({
    required String employeeId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0]; // Format as YYYY-MM-DD
      
      final response = await _apiService.post(
        '${AppConstants.attendanceEndpoint}/mark-absent',
        queryParameters: {
          'employee_id': employeeId,
          'date': dateString,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Error marking absent: $e');
    }
  }
}


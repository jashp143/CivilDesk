import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../models/site.dart';

class GpsAttendanceService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<Options> _getOptions() async {
    final token = await _getToken();
    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  /// Get assigned sites for the employee
  Future<List<Site>> getAssignedSites(String employeeId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        '/gps-attendance/my-sites',
        queryParameters: {'employeeId': employeeId},
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((site) => Site.fromJson(site))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch assigned sites: $e');
    }
  }

  /// Mark GPS attendance
  Future<GpsAttendanceLog> markAttendance(GpsAttendanceRequest request) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '/gps-attendance/mark',
        data: request.toJson(),
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return GpsAttendanceLog.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to mark attendance');
      }
      throw Exception('Failed to mark attendance');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error marking attendance: $e');
    }
  }

  /// Get today's attendance logs
  Future<List<GpsAttendanceLog>> getTodayAttendance(String employeeId) async {
    try {
      final options = await _getOptions();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _dio.get(
        '/gps-attendance/my-attendance',
        queryParameters: {
          'employeeId': employeeId,
          'date': today,
        },
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((log) => GpsAttendanceLog.fromJson(log))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  /// Sync offline attendance
  Future<void> syncOfflineAttendance(List<GpsAttendanceRequest> requests) async {
    try {
      final options = await _getOptions();
      await _dio.post(
        '/gps-attendance/sync',
        data: requests.map((r) => r.toJson()).toList(),
        options: options,
      );
    } catch (e) {
      throw Exception('Failed to sync offline attendance: $e');
    }
  }
}


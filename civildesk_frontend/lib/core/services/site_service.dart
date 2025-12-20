import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../models/site.dart';

class SiteService {
  String get baseUrl => AppConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    // Get token from storage
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // ==================== Sites CRUD ====================

  Future<List<Site>> getAllSites() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/sites/active'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((site) => Site.fromJson(site))
              .toList();
        }
      }
      
      // Extract error message from response if available
      String errorMessage = 'Failed to load sites';
      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          // If response body is not JSON, use default message
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Extract clean error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      throw Exception('Error fetching sites: $errorMsg');
    }
  }

  Future<Site> getSiteById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/sites/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Site.fromJson(data['data']);
        }
      }
      
      // Extract error message from response if available
      String errorMessage = 'Failed to load site';
      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          // If response body is not JSON, use default message
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Extract clean error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      throw Exception('Error fetching site: $errorMsg');
    }
  }

  Future<Site> createSite(Site site) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sites'),
        headers: headers,
        body: json.encode(site.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Site.fromJson(data['data']);
        }
      }
      throw Exception('Failed to create site');
    } catch (e) {
      throw Exception('Error creating site: $e');
    }
  }

  Future<Site> updateSite(int id, Site site) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/sites/$id'),
        headers: headers,
        body: json.encode(site.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Site.fromJson(data['data']);
        }
      }
      throw Exception('Failed to update site');
    } catch (e) {
      throw Exception('Error updating site: $e');
    }
  }

  Future<void> deleteSite(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/sites/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete site');
      }
    } catch (e) {
      throw Exception('Error deleting site: $e');
    }
  }

  // ==================== Site Assignments ====================

  Future<void> assignEmployeeToSite(int employeeId, int siteId, {bool isPrimary = false}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sites/assignments'),
        headers: headers,
        body: json.encode({
          'employeeId': employeeId,
          'siteId': siteId,
          'isPrimary': isPrimary,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to assign employee to site');
      }
    } catch (e) {
      throw Exception('Error assigning employee to site: $e');
    }
  }

  Future<void> removeEmployeeFromSite(int assignmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/sites/assignments/$assignmentId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove employee from site');
      }
    } catch (e) {
      throw Exception('Error removing employee from site: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSiteEmployees(int siteId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/sites/$siteId/employees'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Failed to load site employees');
    } catch (e) {
      throw Exception('Error fetching site employees: $e');
    }
  }

  // ==================== GPS Attendance ====================

  Future<List<GpsAttendanceLog>> getMapDashboardData(DateTime date, {String? employeeId}) async {
    try {
      final headers = await _getHeaders();
      final dateStr = date.toIso8601String().split('T')[0];
      final uri = employeeId != null && employeeId != 'all'
          ? Uri.parse('$baseUrl/gps-attendance/dashboard/map?date=$dateStr&employeeId=$employeeId')
          : Uri.parse('$baseUrl/gps-attendance/dashboard/map?date=$dateStr');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((log) => GpsAttendanceLog.fromJson(log))
              .toList();
        }
      }
      throw Exception('Failed to load map data');
    } catch (e) {
      throw Exception('Error fetching map data: $e');
    }
  }

  Future<List<GpsAttendanceLog>> getSiteAttendance(int siteId, DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/gps-attendance/site/$siteId?date=$dateStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((log) => GpsAttendanceLog.fromJson(log))
              .toList();
        }
      }
      throw Exception('Failed to load site attendance');
    } catch (e) {
      throw Exception('Error fetching site attendance: $e');
    }
  }
}


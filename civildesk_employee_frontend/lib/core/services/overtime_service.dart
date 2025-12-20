import 'package:dio/dio.dart';
import '../../models/overtime.dart';
import '../../models/page_response.dart';
import 'api_service.dart';

class OvertimeService {
  final ApiService _apiService = ApiService();

  // Apply for overtime
  Future<Overtime> applyOvertime(OvertimeRequest request) async {
    try {
      final response = await _apiService.post(
        '/overtimes',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Overtime.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to apply for overtime');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to apply for overtime');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Update overtime
  Future<Overtime> updateOvertime(int overtimeId, OvertimeRequest request) async {
    try {
      final response = await _apiService.put(
        '/overtimes/$overtimeId',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Overtime.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update overtime');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update overtime');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Delete overtime
  Future<void> deleteOvertime(int overtimeId) async {
    try {
      final response = await _apiService.delete('/overtimes/$overtimeId');

      if (!response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to delete overtime');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete overtime');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get my overtimes
  Future<List<Overtime>> getMyOvertimes() async {
    try {
      final response = await _apiService.get('/overtimes/my-overtimes');

      if (response.data['success']) {
        final List<dynamic> overtimesJson = response.data['data'];
        return overtimesJson.map((json) => Overtime.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch overtimes');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch overtimes');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get my overtimes with pagination
  Future<PageResponse<Overtime>> getMyOvertimesPaginated({
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'DESC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };

      final response = await _apiService.get(
        '/overtimes/my-overtimes',
        queryParameters: queryParams,
      );

      if (response.data['success']) {
        final data = response.data['data'];
        // Check if response is paginated (has 'content' field) or a list
        if (data is Map && data.containsKey('content')) {
          return PageResponse.fromJson(
            data as Map<String, dynamic>,
            (json) => Overtime.fromJson(json),
          );
        } else {
          // Fallback for non-paginated response
          final List<dynamic> overtimesJson = data as List<dynamic>;
          final overtimes = overtimesJson.map((json) => Overtime.fromJson(json)).toList();
          return PageResponse<Overtime>(
            content: overtimes,
            totalElements: overtimes.length,
            totalPages: 1,
            size: overtimes.length,
            number: 0,
            first: true,
            last: true,
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch overtimes');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch overtimes');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get overtime by ID
  Future<Overtime> getOvertimeById(int overtimeId) async {
    try {
      final response = await _apiService.get('/overtimes/$overtimeId');

      if (response.data['success']) {
        return Overtime.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch overtime details');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch overtime details');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

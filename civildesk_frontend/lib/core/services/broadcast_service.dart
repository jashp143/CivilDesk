import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../models/broadcast.dart';
import '../../models/page_response.dart';

class BroadcastService {
  final ApiService _apiService = ApiService();
  final String _basePath = '/broadcasts';

  // Get all broadcasts (Admin/HR)
  Future<PageResponse<BroadcastMessage>> getAllBroadcasts({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiService.get(
        _basePath,
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return PageResponse.fromJson(
          response.data['data'] as Map<String, dynamic>,
          (json) => BroadcastMessage.fromJson(json as Map<String, dynamic>),
        );
      }
      throw Exception('Failed to fetch broadcasts');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get active broadcasts (for employees)
  Future<PageResponse<BroadcastMessage>> getActiveBroadcasts({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '$_basePath/active',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return PageResponse.fromJson(
          response.data['data'] as Map<String, dynamic>,
          (json) => BroadcastMessage.fromJson(json as Map<String, dynamic>),
        );
      }
      throw Exception('Failed to fetch active broadcasts');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get broadcast by ID
  Future<BroadcastMessage> getBroadcastById(int id) async {
    try {
      final response = await _apiService.get('$_basePath/$id');

      if (response.data['success'] == true && response.data['data'] != null) {
        return BroadcastMessage.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch broadcast');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create broadcast (Admin/HR)
  Future<BroadcastMessage> createBroadcast(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(_basePath, data: data);

      if (response.data['success'] == true && response.data['data'] != null) {
        return BroadcastMessage.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to create broadcast');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update broadcast (Admin/HR)
  Future<BroadcastMessage> updateBroadcast(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('$_basePath/$id', data: data);

      if (response.data['success'] == true && response.data['data'] != null) {
        return BroadcastMessage.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to update broadcast');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete broadcast (Admin/HR)
  Future<bool> deleteBroadcast(int id) async {
    try {
      final response = await _apiService.delete('$_basePath/$id');

      if (response.data['success'] == true) {
        return true;
      }
      throw Exception('Failed to delete broadcast');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final message = e.response?.data['message'] ?? 'An error occurred';
      return Exception(message);
    }
    return Exception('Network error: ${e.message}');
  }
}


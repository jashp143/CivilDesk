import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../models/broadcast.dart';
import '../../models/page_response.dart';

class BroadcastService {
  final ApiService _apiService = ApiService();
  final String _basePath = '/broadcasts';

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

  Exception _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final message = e.response?.data['message'] ?? 'An error occurred';
      return Exception(message);
    }
    return Exception('Network error: ${e.message}');
  }
}


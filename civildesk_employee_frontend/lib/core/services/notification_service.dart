import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../../models/notification.dart';
import '../../models/page_response.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  static const String _basePath = '/notifications';

  // Register FCM token
  Future<void> registerFcmToken(String fcmToken) async {
    try {
      final response = await _apiService.post(
        '$_basePath/fcm-token',
        data: {'fcmToken': fcmToken},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to register FCM token');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to register FCM token');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Remove FCM token
  Future<void> removeFcmToken() async {
    try {
      final response = await _apiService.delete('$_basePath/fcm-token');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to remove FCM token');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to remove FCM token');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get paginated notifications
  Future<PageResponse<NotificationModel>> getNotifications({
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
          (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
        );
      }
      throw Exception('Failed to fetch notifications');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch notifications');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final response = await _apiService.get('$_basePath/unread');

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> notificationsJson = response.data['data'] as List<dynamic>;
        return notificationsJson
            .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to fetch unread notifications');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch unread notifications');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('$_basePath/unread/count');

      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data']['count'] as int?) ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      return 0;
    }
  }

  // Mark notification as read
  Future<NotificationModel> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.patch('$_basePath/$notificationId/read');

      if (response.data['success'] == true && response.data['data'] != null) {
        return NotificationModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to mark notification as read');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to mark notification as read');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.patch('$_basePath/read-all');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to mark all notifications as read');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to mark all notifications as read');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await _apiService.delete('$_basePath/$notificationId');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete notification');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete notification');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}


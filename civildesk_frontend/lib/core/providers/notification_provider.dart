import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';
import '../../models/notification.dart';
import '../../models/page_response.dart';
import '../constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 0;
  bool _notificationsEnabled = true;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get notificationsEnabled => _notificationsEnabled;

  NotificationProvider() {
    _loadNotificationSettings();
  }

  // Load notification settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;
    notifyListeners();
  }

  // Initialize FCM and load notifications
  Future<void> initialize() async {
    try {
      await _fcmService.initialize();
      await fetchNotifications(refresh: true);
      await fetchUnreadCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch notifications with pagination
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      if (!_hasMore || _isLoadingMore || _isLoading) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        size: 20,
      );

      if (refresh) {
        _notifications = response.content;
      } else {
        // Avoid duplicates
        final existingIds = _notifications.map((n) => n.id).toSet();
        final newNotifications = response.content
            .where((n) => !existingIds.contains(n.id))
            .toList();
        _notifications.addAll(newNotifications);
      }

      // Increment page for next load
      _currentPage = response.number + 1;
      _hasMore = response.hasMore;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Fetch unread count
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      // Silently fail for unread count
    }
  }

  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          body: _notifications[index].body,
          type: _notifications[index].type,
          data: _notifications[index].data,
          isRead: true,
          createdAt: _notifications[index].createdAt,
          readAt: DateTime.now(),
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Update local state
      _notifications = _notifications.map((n) {
        if (!n.isRead) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
            readAt: DateTime.now(),
          );
        }
        return n;
      }).toList();
      
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      if (_notifications.any((n) => n.id == notificationId && !n.isRead)) {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Load more notifications
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    await fetchNotifications(refresh: false);
  }

  // Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchNotifications(refresh: true),
      fetchUnreadCount(),
    ]);
  }

  // Toggle notifications on/off
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.notificationsEnabledKey, enabled);
    
    if (!enabled) {
      // Remove FCM token when notifications are disabled
      await _fcmService.removeToken();
    } else {
      // Re-initialize FCM when notifications are enabled
      await _fcmService.initialize();
    }
    
    notifyListeners();
  }
}


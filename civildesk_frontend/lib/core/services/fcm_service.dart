import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../constants/app_constants.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
  debugPrint('Handling background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final NotificationService _notificationService = NotificationService();
  
  String? _fcmToken;
  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  // Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request notification permissions
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _registerTokenWithBackend(token);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification (terminated state)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;
    
    if (!notificationsEnabled) {
      return; // Don't request if user disabled notifications
    }

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'civildesk_notifications',
      'Civildesk Notifications',
      description: 'Notifications for Civildesk app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    
    // Extract title and body from data payload (since we send data-only messages)
    final title = message.data['title'] as String? ?? 'Notification';
    final body = message.data['body'] as String? ?? '';
    
    // Show local notification
    _showLocalNotification(title, body, message.data);
  }

  // Show local notification
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    await _localNotifications.show(
      data.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'civildesk_notifications',
          'Civildesk Notifications',
          channelDescription: 'Notifications for Civildesk app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data.toString(),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    _navigateFromNotification(message.data);
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Parse payload and navigate
      // This is a simplified version - you may need to parse the payload properly
    }
  }

  // Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    if (_navigatorKey?.currentState == null) return;

    final type = data['type'] as String?;
    final navigator = _navigatorKey!.currentState!;

    // Add navigation logic based on notification type
    // This will be implemented based on your routing structure
  }

  // Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;
      
      if (notificationsEnabled) {
        await _notificationService.registerFcmToken(token);
        debugPrint('FCM token registered with backend');
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  // Remove FCM token (on logout)
  Future<void> removeToken() async {
    try {
      await _notificationService.removeFcmToken();
      _fcmToken = null;
      debugPrint('FCM token removed');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  // Set navigator key for navigation
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // Get current FCM token
  String? get fcmToken => _fcmToken;
}


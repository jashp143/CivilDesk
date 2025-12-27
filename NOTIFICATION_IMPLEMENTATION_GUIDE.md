# Complete Notification System Implementation Guide

This document provides a comprehensive guide to implementing the notification feature used in this application. The system uses **Firebase Cloud Messaging (FCM)** for push notifications with a **MongoDB** backend for persistence.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Backend Implementation](#backend-implementation)
3. [Frontend Implementation](#frontend-implementation)
4. [Database Schema](#database-schema)
5. [API Endpoints](#api-endpoints)
6. [Setup Instructions](#setup-instructions)
7. [Key Features](#key-features)
8. [Notification Types](#notification-types)
9. [Flow Diagrams](#flow-diagrams)

---

## Architecture Overview

The notification system consists of three main components:

1. **Backend (Spring Boot + MongoDB)**: Stores notifications, manages FCM tokens, and sends push notifications
2. **Frontend (Flutter)**: Receives notifications, displays them, and manages local state
3. **Firebase Cloud Messaging**: Handles the actual push notification delivery

### Technology Stack

**Backend:**
- Spring Boot (Java)
- MongoDB (Database)
- Firebase Admin SDK (Push notifications)
- Spring Data MongoDB (Repository layer)

**Frontend:**
- Flutter (Dart)
- Firebase Messaging (FCM client)
- Flutter Local Notifications (Display notifications)
- Provider (State management)

---

## Backend Implementation

### 1. Database Model (`Notification.java`)

```java
@Document(collection = "notifications")
@CompoundIndexes({
    @CompoundIndex(name = "user_createdAt_idx", def = "{'userId': 1, 'createdAt': -1}"),
    @CompoundIndex(name = "user_read_idx", def = "{'userId': 1, 'isRead': 1}")
})
public class Notification {
    @Id
    private String id;
    
    @Indexed
    private String userId;  // User who receives the notification
    
    private String title;
    private String body;
    private String type;  // TASK_ASSIGNED, LEAVE_APPROVED, etc.
    
    private Map<String, String> data;  // Additional data for navigation
    
    private boolean isRead;
    
    @Indexed
    private LocalDateTime createdAt;
    
    private LocalDateTime readAt;
}
```

**Key Points:**
- Compound indexes for efficient querying by userId + createdAt and userId + isRead
- Stores notification metadata and custom data for deep linking

### 2. Repository Layer (`NotificationRepository.java`)

```java
@Repository
public interface NotificationRepository extends MongoRepository<Notification, String> {
    Page<Notification> findByUserIdOrderByCreatedAtDesc(String userId, Pageable pageable);
    List<Notification> findByUserIdAndIsReadFalseOrderByCreatedAtDesc(String userId);
    long countByUserIdAndIsReadFalse(String userId);
    List<Notification> findByUserId(String userId);
}
```

### 3. Service Layer (`NotificationService.java`)

#### Core Methods:

**FCM Token Management:**
```java
// Register/update FCM token for a user
public void updateFcmToken(String userId, String fcmToken)

// Remove FCM token (on logout)
public void removeFcmToken(String userId)
```

**Sending Notifications:**
```java
// Send notification and save to database
public Notification sendNotification(String userId, String title, String body, 
                                     String type, Map<String, String> data)

// Send push notification via FCM (without saving to DB)
public void sendPushNotification(String userId, String title, String body, 
                                 String type, Map<String, String> data, 
                                 String notificationId)
```

**Key Implementation Details:**
- Sends **data-only messages** (not notification payload) to allow custom notification display
- Includes `notificationId` in data payload for tracking
- Handles invalid FCM tokens by removing them automatically
- Uses high priority for Android and sound for iOS

**Notification Retrieval:**
```java
// Get paginated notifications
public Page<Notification> getUserNotifications(String userId, int page, int size)

// Get unread notifications
public List<Notification> getUnreadNotifications(String userId)

// Get unread count
public long getUnreadCount(String userId)
```

**Status Management:**
```java
// Mark single notification as read
public Notification markAsRead(String notificationId, String userId)

// Mark all notifications as read
public void markAllAsRead(String userId)

// Delete notification
public boolean deleteNotification(String notificationId, String userId)
```

**Convenience Methods:**
The service includes helper methods for common notification types:
- `notifyTaskAssigned()`
- `notifyLeaveStatusChanged()`
- `notifyExpenseStatusChanged()`
- `notifyOvertimeStatusChanged()`
- `notifyNewLeaveRequest()` (to all admins)
- `notifyNewExpenseRequest()` (to all admins)
- `notifyNewOvertimeRequest()` (to all admins)
- `notifyTaskStatusChanged()`

### 4. Controller Layer (`NotificationController.java`)

**REST Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/notifications/fcm-token` | Register/update FCM token |
| DELETE | `/api/notifications/fcm-token` | Remove FCM token |
| GET | `/api/notifications` | Get paginated notifications |
| GET | `/api/notifications/unread` | Get unread notifications |
| GET | `/api/notifications/unread/count` | Get unread count |
| PATCH | `/api/notifications/{id}/read` | Mark as read |
| PATCH | `/api/notifications/read-all` | Mark all as read |
| DELETE | `/api/notifications/{id}` | Delete notification |

**Authentication:**
- All endpoints require authentication
- User is identified from JWT token in the request

### 5. Firebase Configuration (`FirebaseConfig.java`)

```java
@Configuration
public class FirebaseConfig {
    @Value("${firebase.credentials.json:}")
    private String firebaseCredentialsJson;
    
    @Value("${firebase.credentials.file:firebase-service-account.json}")
    private String firebaseCredentialsFile;
    
    @Bean
    public FirebaseMessaging firebaseMessaging() {
        // Returns FirebaseMessaging instance or null if not configured
    }
}
```

**Configuration Options:**
1. **Environment Variable**: Set `FIREBASE_CREDENTIALS_JSON` with full JSON content
2. **File**: Place `firebase-service-account.json` in `src/main/resources/`

### 6. User Model Extension

The `User` model includes:
```java
private String fcmToken;
private LocalDateTime fcmTokenUpdatedAt;
```

---

## Frontend Implementation

### 1. FCM Service (`fcm_service.dart`)

**Key Responsibilities:**
- Initialize Firebase Messaging
- Request notification permissions
- Register FCM token with backend
- Handle foreground, background, and terminated app states
- Display local notifications
- Handle notification taps and navigation

**Initialization Flow:**
```dart
Future<void> initialize() async {
    // 1. Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 2. Request permission
    await _requestPermission();
    
    // 3. Initialize local notifications
    await _initializeLocalNotifications();
    
    // 4. Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    
    // 5. Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
        _registerTokenWithBackend(token);
    });
    
    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // 7. Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // 8. Check if app opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
    }
}
```

**Notification Display:**
- Uses `flutter_local_notifications` package
- Creates Android notification channel with high importance
- Shows notifications in foreground, background, and terminated states
- Includes notification ID in payload for tracking

**Navigation Handling:**
- Parses notification data to determine navigation target
- Supports deep linking based on notification type
- Handles retry mechanism for navigation when app is starting

### 2. Notification Provider (`notification_provider.dart`)

**State Management:**
- Manages notification list with pagination
- Tracks unread count
- Handles loading and error states

**Key Methods:**
```dart
// Initialize FCM and load notifications
Future<void> initialize()

// Fetch notifications with pagination
Future<void> fetchNotifications({bool refresh = false})

// Fetch unread count
Future<void> fetchUnreadCount()

// Mark notification as read
Future<void> markAsRead(String notificationId)

// Mark all as read
Future<void> markAllAsRead()

// Delete notification
Future<bool> deleteNotification(String notificationId)

// Refresh all data
Future<void> refresh()

// Load more (pagination)
Future<void> loadMore()
```

### 3. Notification Model (`notification_model.dart`)

```dart
class NotificationModel {
    final String id;
    final String userId;
    final String title;
    final String body;
    final String type;
    final Map<String, dynamic>? data;
    final bool isRead;
    final DateTime createdAt;
    final DateTime? readAt;
    
    // Helper methods
    String get iconName;  // Returns icon based on type
    bool get isPositive;  // True for approved/assigned
    bool get isNegative;  // True for rejected
}
```

### 4. API Service (`api_service.dart`)

**Methods:**
```dart
static Future<Map<String, dynamic>> getNotifications({int? page, int? size})
static Future<Map<String, dynamic>> getUnreadNotifications()
static Future<Map<String, dynamic>> getUnreadCount()
static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId)
static Future<Map<String, dynamic>> markAllNotificationsAsRead()
static Future<Map<String, dynamic>> deleteNotification(String notificationId)
static Future<Map<String, dynamic>> registerFcmToken(String fcmToken)
static Future<Map<String, dynamic>> removeFcmToken()
```

### 5. UI Components

**Notifications Screen (`notifications_screen.dart`):**
- Displays paginated list of notifications
- Pull-to-refresh support
- Infinite scroll pagination
- Mark all as read button
- Swipe to delete
- Visual indicators for unread notifications

**Notification Bell (`notification_bell.dart`):**
- Shows unread count badge
- Navigates to notifications screen on tap
- Updates count automatically

---

## Database Schema

### Notifications Collection

```javascript
{
    "_id": "ObjectId",
    "userId": "String (indexed)",
    "title": "String",
    "body": "String",
    "type": "String",  // TASK_ASSIGNED, LEAVE_APPROVED, etc.
    "data": {
        "taskId": "String",  // or leaveId, expenseId, etc.
        // ... other custom fields
    },
    "isRead": "Boolean",
    "createdAt": "ISODate (indexed)",
    "readAt": "ISODate"
}
```

### Indexes

1. **Compound Index**: `{userId: 1, createdAt: -1}` - For efficient pagination
2. **Compound Index**: `{userId: 1, isRead: 1}` - For unread queries
3. **Single Index**: `userId` - For general queries
4. **Single Index**: `createdAt` - For sorting

### User Collection Extension

```javascript
{
    // ... other user fields
    "fcmToken": "String",
    "fcmTokenUpdatedAt": "ISODate"
}
```

---

## API Endpoints

### Base URL: `/api/notifications`

#### 1. Register FCM Token
```
POST /api/notifications/fcm-token
Body: { "fcmToken": "string" }
Response: { "success": true, "message": "...", "data": null }
```

#### 2. Remove FCM Token
```
DELETE /api/notifications/fcm-token
Response: { "success": true, "message": "...", "data": null }
```

#### 3. Get Notifications (Paginated)
```
GET /api/notifications?page=0&size=20
Response: {
    "success": true,
    "data": {
        "content": [...],
        "page": 0,
        "size": 20,
        "totalElements": 100,
        "totalPages": 5,
        "first": true,
        "last": false
    }
}
```

#### 4. Get Unread Notifications
```
GET /api/notifications/unread
Response: {
    "success": true,
    "data": [...]
}
```

#### 5. Get Unread Count
```
GET /api/notifications/unread/count
Response: {
    "success": true,
    "data": { "count": 5 }
}
```

#### 6. Mark as Read
```
PATCH /api/notifications/{notificationId}/read
Response: {
    "success": true,
    "data": { ...notification object... }
}
```

#### 7. Mark All as Read
```
PATCH /api/notifications/read-all
Response: { "success": true, "message": "...", "data": null }
```

#### 8. Delete Notification
```
DELETE /api/notifications/{notificationId}
Response: { "success": true, "message": "...", "data": null }
```

---

## Setup Instructions

### Backend Setup

1. **Add Dependencies** (`pom.xml`):
```xml
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.2.0</version>
</dependency>
```

2. **Configure Firebase:**
   - Download Firebase service account JSON from Firebase Console
   - Option A: Set `FIREBASE_CREDENTIALS_JSON` environment variable
   - Option B: Place `firebase-service-account.json` in `src/main/resources/`

3. **Update `application.yml`:**
```yaml
firebase:
  credentials:
    json: ${FIREBASE_CREDENTIALS_JSON:}
    file: ${FIREBASE_CREDENTIALS_FILE:firebase-service-account.json}
```

4. **Add User Fields:**
   - Add `fcmToken` and `fcmTokenUpdatedAt` to User model
   - Update UserRepository if needed

### Frontend Setup

1. **Add Dependencies** (`pubspec.yaml`):
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
  provider: ^6.1.1
```

2. **Configure Firebase:**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Update `android/build.gradle` and `ios/Podfile` as needed

3. **Initialize in `main.dart`:**
```dart
void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    
    // Initialize FCM service
    final fcmService = FCMService();
    await fcmService.initialize();
    fcmService.setNavigatorKey(navigatorKey);
    
    // Register token after login
    // ...
}
```

4. **Setup Provider:**
```dart
MultiProvider(
    providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // ... other providers
    ],
    child: MyApp(),
)
```

---

## Key Features

### 1. **Dual Storage**
- Notifications saved in MongoDB for persistence
- Push notifications sent via FCM for real-time delivery

### 2. **Data-Only Messages**
- Backend sends data-only FCM messages
- Frontend displays notifications using local notifications
- Allows custom notification appearance and actions

### 3. **Smart Navigation**
- Deep linking based on notification type
- Navigates to specific screens (tasks, leaves, expenses, etc.)
- Handles app state (foreground, background, terminated)

### 4. **Pagination**
- Efficient loading with page-based pagination
- Infinite scroll support
- Pull-to-refresh functionality

### 5. **Read Status Management**
- Track read/unread status
- Mark individual or all notifications as read
- Unread count badge

### 6. **Token Management**
- Automatic token registration on login
- Token refresh handling
- Token removal on logout
- Invalid token cleanup

### 7. **Error Handling**
- Graceful degradation if Firebase not configured
- Invalid token detection and removal
- Retry mechanisms for navigation

---

## Notification Types

The system supports various notification types:

| Type | Description | Recipient |
|------|-------------|-----------|
| `TASK_ASSIGNED` | New task assigned to employee | Employee |
| `TASK_STATUS_CHANGED` | Task status updated | Admin |
| `LEAVE_REQUEST` | New leave request submitted | All Admins |
| `LEAVE_APPROVED` | Leave request approved | Employee |
| `LEAVE_REJECTED` | Leave request rejected | Employee |
| `EXPENSE_REQUEST` | New expense request submitted | All Admins |
| `EXPENSE_APPROVED` | Expense request approved | Employee |
| `EXPENSE_REJECTED` | Expense request rejected | Employee |
| `OVERTIME_REQUEST` | New overtime request submitted | All Admins |
| `OVERTIME_APPROVED` | Overtime request approved | Employee |
| `OVERTIME_REJECTED` | Overtime request rejected | Employee |
| `GENERAL` | General notifications | User |

### Notification Data Structure

Each notification includes a `data` map with relevant IDs:
```json
{
    "type": "TASK_ASSIGNED",
    "taskId": "123",
    "notificationId": "456",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
}
```

---

## Flow Diagrams

### Notification Sending Flow

```
1. Event occurs (e.g., task assigned)
   ↓
2. Service method called (e.g., notifyTaskAssigned())
   ↓
3. Notification saved to MongoDB
   ↓
4. FCM token retrieved from User
   ↓
5. Data-only message built with notificationId
   ↓
6. Message sent via FirebaseMessaging
   ↓
7. FCM delivers to device
   ↓
8. Frontend receives message
   ↓
9. Local notification displayed
```

### Notification Receiving Flow

```
App State: Foreground
   ↓
FirebaseMessaging.onMessage
   ↓
Extract title/body from data
   ↓
Show local notification
   ↓
User taps notification
   ↓
Navigate based on type

App State: Background/Terminated
   ↓
Background handler triggered
   ↓
Show local notification
   ↓
User taps notification
   ↓
App opens
   ↓
FirebaseMessaging.getInitialMessage
   ↓
Navigate based on type
```

### Token Registration Flow

```
1. User logs in
   ↓
2. FCM service initialized
   ↓
3. Permission requested
   ↓
4. FCM token obtained
   ↓
5. Token sent to backend
   ↓
6. Backend saves token to User
   ↓
7. Token refresh listener set up
   ↓
8. On token refresh, re-register with backend
```

---

## Best Practices

1. **Security:**
   - Never commit Firebase credentials to version control
   - Use environment variables in production
   - Validate notification ownership before marking as read

2. **Performance:**
   - Use pagination for notification lists
   - Index database queries properly
   - Cache unread count

3. **User Experience:**
   - Show unread count badge
   - Support pull-to-refresh
   - Provide visual feedback for actions
   - Handle offline scenarios gracefully

4. **Error Handling:**
   - Log errors for debugging
   - Remove invalid FCM tokens
   - Provide fallback navigation

5. **Testing:**
   - Test in all app states (foreground, background, terminated)
   - Test token refresh scenarios
   - Test navigation from notifications
   - Test with invalid/missing tokens

---

## Troubleshooting

### Common Issues

1. **Notifications not received:**
   - Check Firebase configuration
   - Verify FCM token is registered
   - Check notification permissions
   - Verify backend Firebase credentials

2. **Duplicate notifications:**
   - Ensure using data-only messages
   - Check local notification setup

3. **Navigation not working:**
   - Verify navigator key is set
   - Check notification data payload
   - Ensure app is fully initialized

4. **Token not registering:**
   - Check authentication
   - Verify API endpoint
   - Check network connectivity

---

## Conclusion

This notification system provides a robust, scalable solution for push notifications with:
- ✅ Persistent storage in MongoDB
- ✅ Real-time delivery via FCM
- ✅ Smart navigation and deep linking
- ✅ Efficient pagination
- ✅ Comprehensive error handling
- ✅ Cross-platform support (Android & iOS)

You can adapt this implementation to any application by:
1. Adjusting notification types to match your domain
2. Customizing navigation logic
3. Modifying UI components
4. Adding additional notification channels if needed


package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.model.Notification;
import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.NotificationRepository;
import com.civiltech.civildesk_backend.repository.UserRepository;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Transactional
public class NotificationService {

    private static final Logger logger = LoggerFactory.getLogger(NotificationService.class);

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired(required = false)
    private FirebaseMessaging firebaseMessaging;

    // ==================== FCM Token Management ====================

    /**
     * Register or update FCM token for a user
     */
    public void updateFcmToken(Long userId, String fcmToken) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        user.setFcmToken(fcmToken);
        user.setFcmTokenUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        logger.info("FCM token updated for user: {}", userId);
    }

    /**
     * Remove FCM token (on logout)
     */
    public void removeFcmToken(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        user.setFcmToken(null);
        user.setFcmTokenUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        logger.info("FCM token removed for user: {}", userId);
    }

    // ==================== Notification Sending ====================

    /**
     * Send notification and save to database
     */
    public Notification sendNotification(Long userId, String title, String body, 
                                         String type, Map<String, String> data) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        // Create notification entity
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setTitle(title);
        notification.setBody(body);
        notification.setType(type);
        notification.setData(data != null ? data : new HashMap<>());
        notification.setIsRead(false);
        notification.setCreatedAt(LocalDateTime.now());

        notification = notificationRepository.save(notification);

        // Send push notification
        sendPushNotification(userId, title, body, type, data, notification.getId().toString());

        return notification;
    }

    /**
     * Send push notification via FCM (without saving to DB)
     */
    public void sendPushNotification(Long userId, String title, String body, 
                                     String type, Map<String, String> data, 
                                     String notificationId) {
        if (firebaseMessaging == null) {
            logger.warn("Firebase Messaging is not configured. Push notification skipped.");
            return;
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        String fcmToken = user.getFcmToken();
        if (fcmToken == null || fcmToken.trim().isEmpty()) {
            logger.debug("No FCM token found for user: {}. Push notification skipped.", userId);
            return;
        }

        try {
            // Build data payload (data-only message for custom notification display)
            Map<String, String> messageData = new HashMap<>();
            messageData.put("title", title);
            messageData.put("body", body);
            messageData.put("type", type);
            messageData.put("notificationId", notificationId);
            messageData.put("click_action", "FLUTTER_NOTIFICATION_CLICK");
            
            // Add custom data
            if (data != null) {
                messageData.putAll(data);
            }

            // Build FCM message
            Message message = Message.builder()
                    .setToken(fcmToken)
                    .putAllData(messageData)
                    .setAndroidConfig(com.google.firebase.messaging.AndroidConfig.builder()
                            .setPriority(com.google.firebase.messaging.AndroidConfig.Priority.HIGH)
                            .build())
                    .setApnsConfig(com.google.firebase.messaging.ApnsConfig.builder()
                            .setAps(com.google.firebase.messaging.Aps.builder()
                                    .setSound("default")
                                    .build())
                            .build())
                    .build();

            // Send message
            String response = firebaseMessaging.send(message);
            logger.info("Push notification sent successfully to user: {}. Message ID: {}", userId, response);

        } catch (FirebaseMessagingException e) {
            logger.error("Failed to send push notification to user: {}", userId, e);
            
            // Handle invalid token
            if (e.getErrorCode() != null) {
                String errorCode = e.getErrorCode().toString();
                if ("messaging/invalid-registration-token".equals(errorCode) ||
                    "messaging/registration-token-not-registered".equals(errorCode)) {
                    logger.warn("Invalid FCM token detected for user: {}. Removing token.", userId);
                    user.setFcmToken(null);
                    user.setFcmTokenUpdatedAt(LocalDateTime.now());
                    userRepository.save(user);
                }
            }
        } catch (Exception e) {
            logger.error("Unexpected error sending push notification to user: {}", userId, e);
        }
    }

    // ==================== Notification Retrieval ====================

    /**
     * Get paginated notifications for a user
     */
    @Transactional(readOnly = true)
    public Page<Notification> getUserNotifications(Long userId, Pageable pageable) {
        return notificationRepository.findByUserIdAndDeletedFalseOrderByCreatedAtDesc(userId, pageable);
    }

    /**
     * Get unread notifications for a user
     */
    @Transactional(readOnly = true)
    public List<Notification> getUnreadNotifications(Long userId) {
        return notificationRepository.findByUserIdAndIsReadFalseAndDeletedFalseOrderByCreatedAtDesc(userId);
    }

    /**
     * Get unread count for a user
     */
    @Transactional(readOnly = true)
    public long getUnreadCount(Long userId) {
        return notificationRepository.countByUserIdAndIsReadFalseAndDeletedFalse(userId);
    }

    // ==================== Status Management ====================

    /**
     * Mark notification as read
     */
    public Notification markAsRead(Long notificationId, Long userId) {
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, userId);
        if (notification == null) {
            throw new RuntimeException("Notification not found or access denied");
        }

        notification.setIsRead(true);
        notification.setReadAt(LocalDateTime.now());
        return notificationRepository.save(notification);
    }

    /**
     * Mark all notifications as read for a user
     */
    public void markAllAsRead(Long userId) {
        List<Notification> unreadNotifications = 
                notificationRepository.findByUserIdAndIsReadFalseAndDeletedFalseOrderByCreatedAtDesc(userId);
        
        LocalDateTime now = LocalDateTime.now();
        for (Notification notification : unreadNotifications) {
            notification.setIsRead(true);
            notification.setReadAt(now);
        }
        
        notificationRepository.saveAll(unreadNotifications);
    }

    /**
     * Delete notification
     */
    public boolean deleteNotification(Long notificationId, Long userId) {
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, userId);
        if (notification == null) {
            return false;
        }

        notification.setDeleted(true);
        notificationRepository.save(notification);
        return true;
    }

    // ==================== Convenience Methods for Notification Types ====================

    /**
     * Notify when task is assigned
     */
    public void notifyTaskAssigned(Long userId, Long taskId, String taskTitle) {
        Map<String, String> data = new HashMap<>();
        data.put("taskId", taskId.toString());
        
        sendNotification(userId, 
                "New Task Assigned", 
                "You have been assigned a new task: " + taskTitle,
                "TASK_ASSIGNED", 
                data);
    }

    /**
     * Notify when task status changes
     */
    public void notifyTaskStatusChanged(Long userId, Long taskId, String taskTitle, String status) {
        Map<String, String> data = new HashMap<>();
        data.put("taskId", taskId.toString());
        data.put("status", status);
        
        sendNotification(userId,
                "Task Status Updated",
                "Task '" + taskTitle + "' status has been changed to " + status,
                "TASK_STATUS_CHANGED",
                data);
    }

    /**
     * Notify when employee reviews task (approves/rejects) - to all admins
     */
    public void notifyTaskReviewedByEmployee(Long adminUserId, Long taskId, String taskTitle, String employeeName, String status) {
        Map<String, String> data = new HashMap<>();
        data.put("taskId", taskId.toString());
        data.put("status", status);
        
        sendNotification(adminUserId,
                "Task " + status,
                employeeName + " has " + status.toLowerCase() + " the task: " + taskTitle,
                "TASK_STATUS_CHANGED",
                data);
    }

    /**
     * Notify when leave request is submitted (to all admins)
     */
    public void notifyNewLeaveRequest(Long adminUserId, Long leaveId, String employeeName) {
        Map<String, String> data = new HashMap<>();
        data.put("leaveId", leaveId.toString());
        
        sendNotification(adminUserId,
                "New Leave Request",
                employeeName + " has submitted a new leave request",
                "LEAVE_REQUEST",
                data);
    }

    /**
     * Notify when leave is approved
     */
    public void notifyLeaveApproved(Long userId, Long leaveId) {
        Map<String, String> data = new HashMap<>();
        data.put("leaveId", leaveId.toString());
        
        sendNotification(userId,
                "Leave Approved",
                "Your leave request has been approved",
                "LEAVE_APPROVED",
                data);
    }

    /**
     * Notify when leave is rejected
     */
    public void notifyLeaveRejected(Long userId, Long leaveId, String reason) {
        Map<String, String> data = new HashMap<>();
        data.put("leaveId", leaveId.toString());
        if (reason != null) {
            data.put("reason", reason);
        }
        
        sendNotification(userId,
                "Leave Rejected",
                "Your leave request has been rejected" + (reason != null ? ": " + reason : ""),
                "LEAVE_REJECTED",
                data);
    }

    /**
     * Notify when responsibility is assigned (handover)
     */
    public void notifyAssignedResponsibility(Long userId, Long leaveId, String employeeName) {
        Map<String, String> data = new HashMap<>();
        data.put("leaveId", leaveId.toString());
        
        sendNotification(userId,
                "Responsibility Assigned",
                employeeName + " has assigned you responsibilities during their leave",
                "ASSIGNED_RESPONSIBILITY",
                data);
    }

    /**
     * Notify when expense request is submitted (to all admins)
     */
    public void notifyNewExpenseRequest(Long adminUserId, Long expenseId, String employeeName, String amount) {
        Map<String, String> data = new HashMap<>();
        data.put("expenseId", expenseId.toString());
        data.put("amount", amount);
        
        sendNotification(adminUserId,
                "New Expense Request",
                employeeName + " has submitted an expense request of ₹" + amount,
                "EXPENSE_REQUEST",
                data);
    }

    /**
     * Notify when expense is approved
     */
    public void notifyExpenseApproved(Long userId, Long expenseId) {
        Map<String, String> data = new HashMap<>();
        data.put("expenseId", expenseId.toString());
        
        sendNotification(userId,
                "Expense Approved",
                "Your expense request has been approved",
                "EXPENSE_APPROVED",
                data);
    }

    /**
     * Notify when expense is rejected
     */
    public void notifyExpenseRejected(Long userId, Long expenseId, String reason) {
        Map<String, String> data = new HashMap<>();
        data.put("expenseId", expenseId.toString());
        if (reason != null) {
            data.put("reason", reason);
        }
        
        sendNotification(userId,
                "Expense Rejected",
                "Your expense request has been rejected" + (reason != null ? ": " + reason : ""),
                "EXPENSE_REJECTED",
                data);
    }

    /**
     * Notify when overtime request is submitted (to all admins)
     */
    public void notifyNewOvertimeRequest(Long adminUserId, Long overtimeId, String employeeName) {
        Map<String, String> data = new HashMap<>();
        data.put("overtimeId", overtimeId.toString());
        
        sendNotification(adminUserId,
                "New Overtime Request",
                employeeName + " has submitted an overtime request",
                "OVERTIME_REQUEST",
                data);
    }

    /**
     * Notify when overtime is approved
     */
    public void notifyOvertimeApproved(Long userId, Long overtimeId) {
        Map<String, String> data = new HashMap<>();
        data.put("overtimeId", overtimeId.toString());
        
        sendNotification(userId,
                "Overtime Approved",
                "Your overtime request has been approved",
                "OVERTIME_APPROVED",
                data);
    }

    /**
     * Notify when overtime is rejected
     */
    public void notifyOvertimeRejected(Long userId, Long overtimeId, String reason) {
        Map<String, String> data = new HashMap<>();
        data.put("overtimeId", overtimeId.toString());
        if (reason != null) {
            data.put("reason", reason);
        }
        
        sendNotification(userId,
                "Overtime Rejected",
                "Your overtime request has been rejected" + (reason != null ? ": " + reason : ""),
                "OVERTIME_REJECTED",
                data);
    }

    /**
     * Notify when salary slip is finalized
     */
    public void notifyFinalizedSalarySlip(Long userId, Long salarySlipId, String period) {
        Map<String, String> data = new HashMap<>();
        data.put("salarySlipId", salarySlipId.toString());
        data.put("period", period);
        
        sendNotification(userId,
                "Salary Slip Finalized",
                "Your salary slip for " + period + " has been finalized",
                "FINALIZED_SALARY_SLIPS",
                data);
    }

    /**
     * Notify when broadcast message is created
     */
    public void notifyBroadcastMessage(Long userId, Long broadcastId, String title, String message, 
                                      com.civiltech.civildesk_backend.model.BroadcastMessage.Priority priority) {
        Map<String, String> data = new HashMap<>();
        data.put("broadcastId", broadcastId.toString());
        data.put("priority", priority.name());
        
        // Truncate message if too long for notification body
        String notificationBody = message.length() > 150 
                ? message.substring(0, 147) + "..." 
                : message;
        
        String notificationTitle = "📢 " + title;
        if (priority == com.civiltech.civildesk_backend.model.BroadcastMessage.Priority.URGENT) {
            notificationTitle = "🚨 URGENT: " + title;
        } else if (priority == com.civiltech.civildesk_backend.model.BroadcastMessage.Priority.HIGH) {
            notificationTitle = "⚠️ " + title;
        }
        
        sendNotification(userId,
                notificationTitle,
                notificationBody,
                "BROADCAST_MESSAGE",
                data);
    }
}


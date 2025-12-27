package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.FcmTokenRequest;
import com.civiltech.civildesk_backend.dto.NotificationResponse;
import com.civiltech.civildesk_backend.model.Notification;
import com.civiltech.civildesk_backend.security.SecurityUtils;
import com.civiltech.civildesk_backend.service.NotificationService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.NonNull;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    /**
     * Register or update FCM token
     */
    @PostMapping("/fcm-token")
    public ResponseEntity<ApiResponse<Void>> registerFcmToken(@Valid @RequestBody FcmTokenRequest request) {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("User not authenticated", HttpStatus.UNAUTHORIZED.value()));
        }

        notificationService.updateFcmToken(userId, request.getFcmToken());
        return ResponseEntity.ok(ApiResponse.success("FCM token registered successfully", null));
    }

    /**
     * Remove FCM token (on logout)
     */
    @DeleteMapping("/fcm-token")
    public ResponseEntity<ApiResponse<Void>> removeFcmToken() {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("User not authenticated", HttpStatus.UNAUTHORIZED.value()));
        }

        notificationService.removeFcmToken(userId);
        return ResponseEntity.ok(ApiResponse.success("FCM token removed successfully", null));
    }

    /**
     * Get paginated notifications
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Page<NotificationResponse>>> getNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("User not authenticated", HttpStatus.UNAUTHORIZED.value()));
        }

        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Notification> notifications = notificationService.getUserNotifications(userId, pageable);
        Page<NotificationResponse> response = notifications.map(this::convertToResponse);

        return ResponseEntity.ok(ApiResponse.success("Notifications retrieved successfully", response));
    }

    /**
     * Get unread notifications
     */
    @GetMapping("/unread")
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> getUnreadNotifications() {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("User not authenticated", HttpStatus.UNAUTHORIZED.value()));
        }

        List<Notification> notifications = notificationService.getUnreadNotifications(userId);
        List<NotificationResponse> response = notifications.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success("Unread notifications retrieved successfully", response));
    }

    /**
     * Get unread count
     */
    @GetMapping("/unread/count")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount() {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("User not authenticated", HttpStatus.UNAUTHORIZED.value()));
        }

        long count = notificationService.getUnreadCount(userId);
        Map<String, Long> response = new HashMap<>();
        response.put("count", count);

        return ResponseEntity.ok(ApiResponse.success("Unread count retrieved successfully", response));
    }

    /**
     * Mark notification as read
     */
    @PatchMapping("/{notificationId}/read")
    public ResponseEntity<ApiResponse<NotificationResponse>> markAsRead(@PathVariable @NonNull Long notificationId) {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("User not authenticated", HttpStatus.UNAUTHORIZED.value()));
        }

        try {
            Notification notification = notificationService.markAsRead(notificationId, userId);
            NotificationResponse response = convertToResponse(notification);
            return ResponseEntity.ok(ApiResponse.success("Notification marked as read", response));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(e.getMessage(), HttpStatus.NOT_FOUND.value()));
        }
    }

    /**
     * Mark all notifications as read
     */
    @PatchMapping("/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead() {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("User not authenticated", HttpStatus.UNAUTHORIZED.value()));
        }

        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.success("All notifications marked as read", null));
    }

    /**
     * Delete notification
     */
    @DeleteMapping("/{notificationId}")
    public ResponseEntity<ApiResponse<Void>> deleteNotification(@PathVariable @NonNull Long notificationId) {
        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("User not authenticated", HttpStatus.UNAUTHORIZED.value()));
        }

        boolean deleted = notificationService.deleteNotification(notificationId, userId);
        if (deleted) {
            return ResponseEntity.ok(ApiResponse.success("Notification deleted successfully", null));
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Notification not found or access denied", HttpStatus.NOT_FOUND.value()));
        }
    }

    /**
     * Helper method to convert Notification entity to NotificationResponse
     */
    private NotificationResponse convertToResponse(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getTitle(),
                notification.getBody(),
                notification.getType(),
                notification.getData(),
                notification.getIsRead(),
                notification.getCreatedAt(),
                notification.getReadAt()
        );
    }
}


package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    // Get paginated notifications for a user, ordered by created date descending
    // Uses composite index (user_id, created_at DESC) for optimal performance
    Page<Notification> findByUserIdAndDeletedFalseOrderByCreatedAtDesc(Long userId, Pageable pageable);

    // Get all unread notifications for a user
    List<Notification> findByUserIdAndIsReadFalseAndDeletedFalseOrderByCreatedAtDesc(Long userId);

    // Count unread notifications for a user
    long countByUserIdAndIsReadFalseAndDeletedFalse(Long userId);

    // Get all notifications for a user (for testing/debugging)
    List<Notification> findByUserIdAndDeletedFalseOrderByCreatedAtDesc(Long userId);

    // Get notification by ID and user ID (for security)
    @Query("SELECT n FROM Notification n WHERE n.id = :id AND n.user.id = :userId AND n.deleted = false")
    Notification findByIdAndUserId(@Param("id") Long id, @Param("userId") Long userId);
}


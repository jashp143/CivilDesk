package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.BroadcastMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BroadcastMessageRepository extends JpaRepository<BroadcastMessage, Long> {
    
    // Find all active (non-deleted) broadcast messages
    List<BroadcastMessage> findByDeletedFalseOrderByCreatedAtDesc();
    
    // Find all active broadcast messages with pagination
    Page<BroadcastMessage> findByDeletedFalseOrderByCreatedAtDesc(Pageable pageable);
    
    // Find active broadcast messages (visible to employees)
    @Query("SELECT b FROM BroadcastMessage b WHERE b.deleted = false AND b.isActive = true ORDER BY b.priority DESC, b.createdAt DESC")
    List<BroadcastMessage> findActiveBroadcasts();
    
    // Find active broadcast messages with pagination
    @Query("SELECT b FROM BroadcastMessage b WHERE b.deleted = false AND b.isActive = true ORDER BY b.priority DESC, b.createdAt DESC")
    Page<BroadcastMessage> findActiveBroadcasts(Pageable pageable);
    
    // Find by priority
    List<BroadcastMessage> findByPriorityAndDeletedFalseOrderByCreatedAtDesc(BroadcastMessage.Priority priority);
    
    // Find by active status
    List<BroadcastMessage> findByIsActiveAndDeletedFalseOrderByCreatedAtDesc(Boolean isActive);
}


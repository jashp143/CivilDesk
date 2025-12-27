package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.BroadcastMessageRequest;
import com.civiltech.civildesk_backend.dto.BroadcastMessageResponse;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.exception.UnauthorizedException;
import com.civiltech.civildesk_backend.model.BroadcastMessage;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.BroadcastMessageRepository;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.security.SecurityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class BroadcastService {

    private static final Logger logger = LoggerFactory.getLogger(BroadcastService.class);

    @Autowired
    private BroadcastMessageRepository broadcastMessageRepository;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private EmployeeRepository employeeRepository;

    // Create broadcast message (Admin/HR only)
    @CacheEvict(value = "broadcasts", allEntries = true)
    public BroadcastMessageResponse createBroadcast(BroadcastMessageRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can create broadcast messages");
        }

        // Create broadcast message
        BroadcastMessage broadcast = new BroadcastMessage();
        broadcast.setTitle(request.getTitle().trim());
        broadcast.setMessage(request.getMessage().trim());
        broadcast.setPriority(request.getPriority());
        broadcast.setIsActive(request.getIsActive() != null ? request.getIsActive() : true);
        broadcast.setCreatedBy(currentUser);
        broadcast.setDeleted(false);

        broadcast = broadcastMessageRepository.save(broadcast);

        // Send notification to all employees if broadcast is active
        if (broadcast.getIsActive()) {
            sendBroadcastNotificationToAllEmployees(broadcast);
        }

        return convertToResponse(broadcast);
    }

    // Update broadcast message (Admin/HR only)
    @CacheEvict(value = "broadcasts", key = "#id", allEntries = true)
    public BroadcastMessageResponse updateBroadcast(@NonNull Long id, BroadcastMessageRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can update broadcast messages");
        }

        BroadcastMessage broadcast = broadcastMessageRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Broadcast message not found with id: " + id));

        // Check if broadcast is deleted
        if (broadcast.getDeleted()) {
            throw new ResourceNotFoundException("Broadcast message not found with id: " + id);
        }

        boolean wasActive = broadcast.getIsActive();
        boolean isNowActive = request.getIsActive() != null ? request.getIsActive() : true;

        // Update broadcast
        broadcast.setTitle(request.getTitle().trim());
        broadcast.setMessage(request.getMessage().trim());
        broadcast.setPriority(request.getPriority());
        broadcast.setIsActive(isNowActive);
        broadcast.setUpdatedBy(currentUser);

        broadcast = broadcastMessageRepository.save(broadcast);

        // Send notification if broadcast was just activated
        if (!wasActive && isNowActive) {
            sendBroadcastNotificationToAllEmployees(broadcast);
        }

        return convertToResponse(broadcast);
    }

    // Delete broadcast message (Admin/HR only) - Soft delete
    @CacheEvict(value = "broadcasts", key = "#id", allEntries = true)
    public void deleteBroadcast(@NonNull Long id) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can delete broadcast messages");
        }

        BroadcastMessage broadcast = broadcastMessageRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Broadcast message not found with id: " + id));

        // Check if broadcast is already deleted
        if (broadcast.getDeleted()) {
            throw new ResourceNotFoundException("Broadcast message not found with id: " + id);
        }

        // Soft delete
        broadcast.setDeleted(true);
        broadcast.setUpdatedBy(currentUser);
        broadcastMessageRepository.save(broadcast);
    }

    // Get all broadcast messages (Admin/HR only)
    @Cacheable(value = "broadcasts", key = "'all-broadcasts'")
    @Transactional(readOnly = true)
    public List<BroadcastMessageResponse> getAllBroadcasts() {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all broadcast messages");
        }

        List<BroadcastMessage> broadcasts = broadcastMessageRepository.findByDeletedFalseOrderByCreatedAtDesc();

        return broadcasts.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get all broadcast messages with pagination (Admin/HR only)
    @Transactional(readOnly = true)
    public Page<BroadcastMessageResponse> getAllBroadcastsPaginated(Pageable pageable) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all broadcast messages");
        }

        Page<BroadcastMessage> broadcasts = broadcastMessageRepository.findByDeletedFalseOrderByCreatedAtDesc(pageable);

        return broadcasts.map(this::convertToResponse);
    }

    // Get active broadcast messages (for employees)
    @Cacheable(value = "broadcasts", key = "'active-broadcasts'")
    @Transactional(readOnly = true)
    public List<BroadcastMessageResponse> getActiveBroadcasts() {
        List<BroadcastMessage> broadcasts = broadcastMessageRepository.findActiveBroadcasts();

        return broadcasts.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get active broadcast messages with pagination (for employees)
    @Transactional(readOnly = true)
    public Page<BroadcastMessageResponse> getActiveBroadcastsPaginated(Pageable pageable) {
        Page<BroadcastMessage> broadcasts = broadcastMessageRepository.findActiveBroadcasts(pageable);

        return broadcasts.map(this::convertToResponse);
    }

    // Get broadcast message by ID
    @Cacheable(value = "broadcasts", key = "#id")
    @Transactional(readOnly = true)
    public BroadcastMessageResponse getBroadcastById(@NonNull Long id) {
        BroadcastMessage broadcast = broadcastMessageRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Broadcast message not found with id: " + id));

        // Check if broadcast is deleted
        if (broadcast.getDeleted()) {
            throw new ResourceNotFoundException("Broadcast message not found with id: " + id);
        }

        User currentUser = SecurityUtils.getCurrentUser();
        boolean isAdminOrHR = currentUser.getRole() == User.Role.ADMIN || 
                              currentUser.getRole() == User.Role.HR_MANAGER;

        // Employees can only see active broadcasts
        if (!isAdminOrHR && !broadcast.getIsActive()) {
            throw new ResourceNotFoundException("Broadcast message not found with id: " + id);
        }

        return convertToResponse(broadcast);
    }

    // Send broadcast notification to all employees
    private void sendBroadcastNotificationToAllEmployees(BroadcastMessage broadcast) {
        try {
            // Get all active employees
            List<Employee> employees = employeeRepository.findByEmploymentStatusAndDeletedFalse(
                    Employee.EmploymentStatus.ACTIVE
            );

            int successCount = 0;
            int skippedCount = 0;
            int errorCount = 0;

            for (Employee employee : employees) {
                if (employee.getUser() != null && employee.getUser().getId() != null) {
                    try {
                        notificationService.notifyBroadcastMessage(
                                employee.getUser().getId(),
                                broadcast.getId(),
                                broadcast.getTitle(),
                                broadcast.getMessage(),
                                broadcast.getPriority()
                        );
                        successCount++;
                        logger.debug("Broadcast notification sent to employee: {} (userId: {})", 
                                employee.getId(), employee.getUser().getId());
                    } catch (Exception e) {
                        errorCount++;
                        logger.error("Failed to send broadcast notification to employee: {} (userId: {})", 
                                employee.getId(), employee.getUser().getId(), e);
                    }
                } else {
                    skippedCount++;
                    logger.warn("Skipping employee {} - no user account found", employee.getId());
                }
            }

            logger.info("Broadcast notification completed - Total: {}, Success: {}, Errors: {}, Skipped: {}", 
                    employees.size(), successCount, errorCount, skippedCount);
        } catch (Exception e) {
            logger.error("Failed to send broadcast notifications to employees", e);
        }
    }

    // Convert entity to response
    private BroadcastMessageResponse convertToResponse(BroadcastMessage broadcast) {
        BroadcastMessageResponse response = new BroadcastMessageResponse();
        response.setId(broadcast.getId());
        response.setTitle(broadcast.getTitle());
        response.setMessage(broadcast.getMessage());
        response.setPriority(broadcast.getPriority().name());
        response.setPriorityDisplay(broadcast.getPriority().getDisplayName());
        response.setIsActive(broadcast.getIsActive());
        response.setCreatedAt(broadcast.getCreatedAt());
        response.setUpdatedAt(broadcast.getUpdatedAt());

        // Set creator info
        if (broadcast.getCreatedBy() != null) {
            BroadcastMessageResponse.CreatorInfo creatorInfo = new BroadcastMessageResponse.CreatorInfo();
            creatorInfo.setId(broadcast.getCreatedBy().getId());
            creatorInfo.setName(broadcast.getCreatedBy().getFirstName() + " " + 
                               broadcast.getCreatedBy().getLastName());
            creatorInfo.setEmail(broadcast.getCreatedBy().getEmail());
            creatorInfo.setRole(broadcast.getCreatedBy().getRole().name());
            response.setCreatedBy(creatorInfo);
        }

        // Set updater info
        if (broadcast.getUpdatedBy() != null) {
            BroadcastMessageResponse.CreatorInfo updaterInfo = new BroadcastMessageResponse.CreatorInfo();
            updaterInfo.setId(broadcast.getUpdatedBy().getId());
            updaterInfo.setName(broadcast.getUpdatedBy().getFirstName() + " " + 
                              broadcast.getUpdatedBy().getLastName());
            updaterInfo.setEmail(broadcast.getUpdatedBy().getEmail());
            updaterInfo.setRole(broadcast.getUpdatedBy().getRole().name());
            response.setUpdatedBy(updaterInfo);
        }

        return response;
    }
}


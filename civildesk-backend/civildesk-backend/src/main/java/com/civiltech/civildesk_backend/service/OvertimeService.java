package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.OvertimeRequest;
import com.civiltech.civildesk_backend.dto.OvertimeResponse;
import com.civiltech.civildesk_backend.dto.OvertimeReviewRequest;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.exception.UnauthorizedException;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.Overtime;
import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.OvertimeRepository;
import com.civiltech.civildesk_backend.repository.UserRepository;
import com.civiltech.civildesk_backend.security.SecurityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class OvertimeService {

    private static final Logger logger = LoggerFactory.getLogger(OvertimeService.class);

    @Autowired
    private OvertimeRepository overtimeRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserRepository userRepository;

    // Apply for overtime
    public OvertimeResponse applyOvertime(OvertimeRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Find employee for current user
        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        // Validate date (must be present or future)
        validateOvertimeDate(request.getDate());

        // Validate time range
        validateTimeRange(request.getStartTime(), request.getEndTime());

        // Create overtime entity
        Overtime overtime = new Overtime();
        overtime.setEmployee(employee);
        overtime.setDate(request.getDate());
        overtime.setStartTime(request.getStartTime());
        overtime.setEndTime(request.getEndTime());
        overtime.setReason(request.getReason());
        overtime.setStatus(Overtime.OvertimeStatus.PENDING);

        overtime = overtimeRepository.save(overtime);

        OvertimeResponse response = convertToResponse(overtime);
        
        // Send notification to all admins and HR managers
        try {
            List<User.Role> adminRoles = Arrays.asList(User.Role.ADMIN, User.Role.HR_MANAGER);
            List<User> adminUsers = userRepository.findByRoleInAndDeletedFalseAndIsActiveTrue(adminRoles);
            
            String employeeName = employee.getFirstName() + " " + employee.getLastName();
            
            for (User adminUser : adminUsers) {
                notificationService.notifyNewOvertimeRequest(
                        adminUser.getId(),
                        overtime.getId(),
                        employeeName
                );
            }
        } catch (Exception e) {
            logger.error("Failed to send overtime request notification to admins", e);
        }
        
        return response;
    }

    // Update overtime (only if status is PENDING)
    public OvertimeResponse updateOvertime(@NonNull Long overtimeId, OvertimeRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Overtime overtime = overtimeRepository.findById(overtimeId)
                .orElseThrow(() -> new ResourceNotFoundException("Overtime not found with id: " + overtimeId));

        // Check if overtime is deleted
        if (overtime.getDeleted()) {
            throw new ResourceNotFoundException("Overtime not found with id: " + overtimeId);
        }

        // Check if overtime belongs to current user
        if (!overtime.getEmployee().getUser().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("You are not authorized to update this overtime");
        }

        // Check if overtime is in PENDING status
        if (overtime.getStatus() != Overtime.OvertimeStatus.PENDING) {
            throw new BadRequestException("Cannot update overtime that is not in PENDING status");
        }

        // Validate date
        validateOvertimeDate(request.getDate());

        // Validate time range
        validateTimeRange(request.getStartTime(), request.getEndTime());

        // Update overtime
        overtime.setDate(request.getDate());
        overtime.setStartTime(request.getStartTime());
        overtime.setEndTime(request.getEndTime());
        overtime.setReason(request.getReason());

        overtime = overtimeRepository.save(overtime);

        return convertToResponse(overtime);
    }

    // Delete overtime (only if status is PENDING)
    public void deleteOvertime(@NonNull Long overtimeId) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Overtime overtime = overtimeRepository.findById(overtimeId)
                .orElseThrow(() -> new ResourceNotFoundException("Overtime not found with id: " + overtimeId));

        // Check if overtime is deleted
        if (overtime.getDeleted()) {
            throw new ResourceNotFoundException("Overtime not found with id: " + overtimeId);
        }

        // Check if overtime belongs to current user
        if (!overtime.getEmployee().getUser().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("You are not authorized to delete this overtime");
        }

        // Check if overtime is in PENDING status
        if (overtime.getStatus() != Overtime.OvertimeStatus.PENDING) {
            throw new BadRequestException("Cannot delete overtime that is not in PENDING status");
        }

        // Soft delete
        overtime.setDeleted(true);
        overtimeRepository.save(overtime);
    }

    // Get all overtimes for current employee
    public List<OvertimeResponse> getMyOvertimes() {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        List<Overtime> overtimes = overtimeRepository.findByEmployeeIdAndDeletedFalse(employee.getId());
        
        return overtimes.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get all overtimes (Admin/HR only)
    public List<OvertimeResponse> getAllOvertimes() {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all overtimes");
        }

        List<Overtime> overtimes = overtimeRepository.findByDeletedFalse();
        
        return overtimes.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get overtimes by status (Admin/HR only)
    public List<OvertimeResponse> getOvertimesByStatus(Overtime.OvertimeStatus status) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter overtimes");
        }

        List<Overtime> overtimes = overtimeRepository.findByStatusAndDeletedFalse(status);
        
        return overtimes.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get overtimes by department (Admin/HR only)
    public List<OvertimeResponse> getOvertimesByDepartment(String department) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter overtimes");
        }

        List<Overtime> overtimes = overtimeRepository.findOvertimesByDepartment(department);
        
        return overtimes.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Paginated methods
    @Transactional(readOnly = true)
    public Page<OvertimeResponse> getAllOvertimesPaginated(String status, String department, Pageable pageable) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all overtimes");
        }

        Page<Overtime> overtimes;
        
        if (status != null && !status.isEmpty()) {
            try {
                Overtime.OvertimeStatus overtimeStatus = Overtime.OvertimeStatus.valueOf(status.toUpperCase());
                overtimes = overtimeRepository.findByStatusAndDeletedFalse(overtimeStatus, pageable);
            } catch (IllegalArgumentException e) {
                throw new BadRequestException("Invalid status value: " + status);
            }
        } else if (department != null && !department.isEmpty()) {
            overtimes = overtimeRepository.findOvertimesByDepartment(department, pageable);
        } else {
            overtimes = overtimeRepository.findByDeletedFalse(pageable);
        }
        
        return overtimes.map(this::convertToResponse);
    }

    // Get overtime by ID
    public OvertimeResponse getOvertimeById(@NonNull Long overtimeId) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Overtime overtime = overtimeRepository.findById(overtimeId)
                .orElseThrow(() -> new ResourceNotFoundException("Overtime not found with id: " + overtimeId));

        // Check if overtime is deleted
        if (overtime.getDeleted()) {
            throw new ResourceNotFoundException("Overtime not found with id: " + overtimeId);
        }

        // Check authorization
        boolean isOwnOvertime = overtime.getEmployee().getUser().getId().equals(currentUser.getId());
        boolean isAdminOrHR = currentUser.getRole() == User.Role.ADMIN || 
                              currentUser.getRole() == User.Role.HR_MANAGER;

        if (!isOwnOvertime && !isAdminOrHR) {
            throw new UnauthorizedException("You are not authorized to view this overtime");
        }

        return convertToResponse(overtime);
    }

    // Review overtime (Approve/Reject) - Admin/HR only
    public OvertimeResponse reviewOvertime(@NonNull Long overtimeId, OvertimeReviewRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can review overtimes");
        }

        Overtime overtime = overtimeRepository.findById(overtimeId)
                .orElseThrow(() -> new ResourceNotFoundException("Overtime not found with id: " + overtimeId));

        // Check if overtime is deleted
        if (overtime.getDeleted()) {
            throw new ResourceNotFoundException("Overtime not found with id: " + overtimeId);
        }

        // Check if overtime is in PENDING status
        if (overtime.getStatus() != Overtime.OvertimeStatus.PENDING) {
            throw new BadRequestException("Can only review overtimes in PENDING status");
        }

        // Validate status
        if (request.getStatus() != Overtime.OvertimeStatus.APPROVED && 
            request.getStatus() != Overtime.OvertimeStatus.REJECTED) {
            throw new BadRequestException("Status must be either APPROVED or REJECTED");
        }

        // Update overtime
        overtime.setStatus(request.getStatus());
        overtime.setReviewedBy(currentUser);
        overtime.setReviewedAt(LocalDateTime.now());
        overtime.setReviewNote(request.getReviewNote());

        overtime = overtimeRepository.save(overtime);

        // Send notification to employee
        if (overtime.getEmployee() != null && overtime.getEmployee().getUser() != null 
                && overtime.getEmployee().getUser().getId() != null) {
            try {
                if (request.getStatus() == Overtime.OvertimeStatus.APPROVED) {
                    notificationService.notifyOvertimeApproved(
                            overtime.getEmployee().getUser().getId(),
                            overtime.getId()
                    );
                } else if (request.getStatus() == Overtime.OvertimeStatus.REJECTED) {
                    notificationService.notifyOvertimeRejected(
                            overtime.getEmployee().getUser().getId(),
                            overtime.getId(),
                            request.getReviewNote()
                    );
                }
            } catch (Exception e) {
                logger.error("Failed to send overtime status notification", e);
            }
        }

        return convertToResponse(overtime);
    }

    // Helper method to validate date
    private void validateOvertimeDate(LocalDate date) {
        if (date.isBefore(LocalDate.now())) {
            throw new BadRequestException("Overtime date cannot be in the past");
        }
        // Allow present or future dates
    }

    // Helper method to validate time range
    private void validateTimeRange(java.time.LocalTime startTime, java.time.LocalTime endTime) {
        if (endTime.isBefore(startTime) || endTime.equals(startTime)) {
            throw new BadRequestException("End time must be after start time");
        }
    }

    // Helper method to convert Overtime entity to OvertimeResponse
    private OvertimeResponse convertToResponse(Overtime overtime) {
        OvertimeResponse response = new OvertimeResponse();
        response.setId(overtime.getId());
        response.setEmployeeId(overtime.getEmployee().getId());
        response.setEmployeeName(overtime.getEmployee().getFirstName() + " " + overtime.getEmployee().getLastName());
        response.setEmployeeEmail(overtime.getEmployee().getEmail());
        response.setEmployeeId_str(overtime.getEmployee().getEmployeeId());
        response.setDepartment(overtime.getEmployee().getDepartment());
        response.setDesignation(overtime.getEmployee().getDesignation());
        response.setDate(overtime.getDate());
        response.setStartTime(overtime.getStartTime());
        response.setEndTime(overtime.getEndTime());
        response.setReason(overtime.getReason());
        response.setStatus(overtime.getStatus());
        response.setStatusDisplay(overtime.getStatus().getDisplayName());
        response.setCreatedAt(overtime.getCreatedAt());
        response.setUpdatedAt(overtime.getUpdatedAt());

        // Set reviewer info
        if (overtime.getReviewedBy() != null) {
            OvertimeResponse.ReviewerInfo reviewerInfo = new OvertimeResponse.ReviewerInfo();
            reviewerInfo.setId(overtime.getReviewedBy().getId());
            reviewerInfo.setName(overtime.getReviewedBy().getFirstName() + " " + overtime.getReviewedBy().getLastName());
            reviewerInfo.setEmail(overtime.getReviewedBy().getEmail());
            reviewerInfo.setRole(overtime.getReviewedBy().getRole().name());
            response.setReviewedBy(reviewerInfo);
            response.setReviewedAt(overtime.getReviewedAt());
            response.setReviewNote(overtime.getReviewNote());
        }

        return response;
    }
}

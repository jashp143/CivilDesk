package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.LeaveRequest;
import com.civiltech.civildesk_backend.dto.LeaveResponse;
import com.civiltech.civildesk_backend.dto.LeaveReviewRequest;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.exception.UnauthorizedException;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.Leave;
import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.LeaveRepository;
import com.civiltech.civildesk_backend.repository.UserRepository;
import com.civiltech.civildesk_backend.security.SecurityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@Transactional
public class LeaveService {

    private static final Logger logger = LoggerFactory.getLogger(LeaveService.class);

    @Autowired
    private LeaveRepository leaveRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserRepository userRepository;

    // Apply for leave
    @CacheEvict(value = "leaves", allEntries = true)
    public LeaveResponse applyLeave(LeaveRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Find employee for current user
        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        // Validate dates
        validateLeaveDates(request.getStartDate(), request.getEndDate());

        // Validate medical certificate for medical leave
        if (request.getLeaveType() == Leave.LeaveType.MEDICAL_LEAVE && 
            (request.getMedicalCertificateUrl() == null || request.getMedicalCertificateUrl().isBlank())) {
            throw new BadRequestException("Medical certificate is required for medical leave");
        }

        // Validate half day
        if (request.getIsHalfDay() && request.getHalfDayPeriod() == null) {
            throw new BadRequestException("Half day period is required when applying for half day leave");
        }

        if (request.getIsHalfDay() && !request.getStartDate().equals(request.getEndDate())) {
            throw new BadRequestException("Half day leave can only be applied for a single day");
        }

        // Create leave entity
        Leave leave = new Leave();
        leave.setEmployee(employee);
        leave.setLeaveType(request.getLeaveType());
        leave.setStartDate(request.getStartDate());
        leave.setEndDate(request.getEndDate());
        leave.setIsHalfDay(request.getIsHalfDay());
        leave.setHalfDayPeriod(request.getHalfDayPeriod());
        leave.setContactNumber(request.getContactNumber());
        leave.setReason(request.getReason());
        leave.setMedicalCertificateUrl(request.getMedicalCertificateUrl());
        leave.setStatus(Leave.LeaveStatus.PENDING);

        // Convert handover employee IDs list to comma-separated string
        if (request.getHandoverEmployeeIds() != null && !request.getHandoverEmployeeIds().isEmpty()) {
            // Validate handover employees and check for conflicts
            validateHandoverEmployees(request.getHandoverEmployeeIds(), 
                                    request.getStartDate(), request.getEndDate(), employee.getId());
            
            String handoverIds = request.getHandoverEmployeeIds().stream()
                    .map(String::valueOf)
                    .collect(Collectors.joining(","));
            leave.setHandoverEmployeeIds(handoverIds);
        }

        // Calculate total days
        double totalDays = calculateLeaveDays(request.getStartDate(), request.getEndDate(), request.getIsHalfDay());
        leave.setTotalDays(totalDays);

        leave = leaveRepository.save(leave);

        LeaveResponse response = convertToResponse(leave);
        
        // Check for conflicts in handover employees
        if (request.getHandoverEmployeeIds() != null && !request.getHandoverEmployeeIds().isEmpty()) {
            checkHandoverConflicts(response, request.getHandoverEmployeeIds(), 
                                 request.getStartDate(), request.getEndDate());
        }
        
        // Send notification to all admins and HR managers
        try {
            List<User.Role> adminRoles = Arrays.asList(User.Role.ADMIN, User.Role.HR_MANAGER);
            List<User> adminUsers = userRepository.findByRoleInAndDeletedFalseAndIsActiveTrue(adminRoles);
            
            String employeeName = employee.getFirstName() + " " + employee.getLastName();
            
            for (User adminUser : adminUsers) {
                notificationService.notifyNewLeaveRequest(
                        adminUser.getId(),
                        leave.getId(),
                        employeeName
                );
            }
        } catch (Exception e) {
            logger.error("Failed to send leave request notification to admins", e);
        }
        
        return response;
    }

    // Update leave (only if status is PENDING)
    @Caching(evict = {
        @CacheEvict(value = "leaves", key = "#leaveId"),
        @CacheEvict(value = "leaves", allEntries = true)
    })
    public LeaveResponse updateLeave(@NonNull Long leaveId, LeaveRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Leave leave = leaveRepository.findById(leaveId)
                .orElseThrow(() -> new ResourceNotFoundException("Leave not found with id: " + leaveId));

        // Check if leave is deleted
        if (leave.getDeleted()) {
            throw new ResourceNotFoundException("Leave not found with id: " + leaveId);
        }

        // Check if leave belongs to current user
        if (!leave.getEmployee().getUser().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("You are not authorized to update this leave");
        }

        // Check if leave is in PENDING status
        if (leave.getStatus() != Leave.LeaveStatus.PENDING) {
            throw new BadRequestException("Cannot update leave that is not in PENDING status");
        }

        // Validate dates
        validateLeaveDates(request.getStartDate(), request.getEndDate());

        // Validate medical certificate for medical leave
        if (request.getLeaveType() == Leave.LeaveType.MEDICAL_LEAVE && 
            (request.getMedicalCertificateUrl() == null || request.getMedicalCertificateUrl().isBlank())) {
            throw new BadRequestException("Medical certificate is required for medical leave");
        }

        // Validate half day
        if (request.getIsHalfDay() && request.getHalfDayPeriod() == null) {
            throw new BadRequestException("Half day period is required when applying for half day leave");
        }

        if (request.getIsHalfDay() && !request.getStartDate().equals(request.getEndDate())) {
            throw new BadRequestException("Half day leave can only be applied for a single day");
        }

        // Update leave
        leave.setLeaveType(request.getLeaveType());
        leave.setStartDate(request.getStartDate());
        leave.setEndDate(request.getEndDate());
        leave.setIsHalfDay(request.getIsHalfDay());
        leave.setHalfDayPeriod(request.getHalfDayPeriod());
        leave.setContactNumber(request.getContactNumber());
        leave.setReason(request.getReason());
        leave.setMedicalCertificateUrl(request.getMedicalCertificateUrl());

        // Convert handover employee IDs list to comma-separated string
        if (request.getHandoverEmployeeIds() != null && !request.getHandoverEmployeeIds().isEmpty()) {
            // Validate handover employees and check for conflicts
            validateHandoverEmployees(request.getHandoverEmployeeIds(), 
                                    request.getStartDate(), request.getEndDate(), leave.getEmployee().getId());
            
            String handoverIds = request.getHandoverEmployeeIds().stream()
                    .map(String::valueOf)
                    .collect(Collectors.joining(","));
            leave.setHandoverEmployeeIds(handoverIds);
        } else {
            leave.setHandoverEmployeeIds(null);
        }

        // Recalculate total days
        double totalDays = calculateLeaveDays(request.getStartDate(), request.getEndDate(), request.getIsHalfDay());
        leave.setTotalDays(totalDays);

        leave = leaveRepository.save(leave);

        LeaveResponse response = convertToResponse(leave);
        
        // Check for conflicts in handover employees
        if (request.getHandoverEmployeeIds() != null && !request.getHandoverEmployeeIds().isEmpty()) {
            checkHandoverConflicts(response, request.getHandoverEmployeeIds(), 
                                 request.getStartDate(), request.getEndDate());
        }
        
        return response;
    }

    // Delete leave (only if status is PENDING)
    @Caching(evict = {
        @CacheEvict(value = "leaves", key = "#leaveId"),
        @CacheEvict(value = "leaves", allEntries = true)
    })
    public void deleteLeave(@NonNull Long leaveId) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Leave leave = leaveRepository.findById(leaveId)
                .orElseThrow(() -> new ResourceNotFoundException("Leave not found with id: " + leaveId));

        // Check if leave is deleted
        if (leave.getDeleted()) {
            throw new ResourceNotFoundException("Leave not found with id: " + leaveId);
        }

        // Check if leave belongs to current user
        if (!leave.getEmployee().getUser().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("You are not authorized to delete this leave");
        }

        // Check if leave is in PENDING status
        if (leave.getStatus() != Leave.LeaveStatus.PENDING) {
            throw new BadRequestException("Cannot delete leave that is not in PENDING status");
        }

        // Soft delete
        leave.setDeleted(true);
        leaveRepository.save(leave);
    }

    // Get all leaves for current employee
    @Cacheable(value = "leaves", key = "'my-leaves:' + T(com.civiltech.civildesk_backend.security.SecurityUtils).getCurrentUserId()")
    @Transactional(readOnly = true)
    public List<LeaveResponse> getMyLeaves() {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        List<Leave> leaves = leaveRepository.findByEmployeeIdAndDeletedFalse(employee.getId());
        
        return leaves.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get responsibilities assigned to current employee
    @Cacheable(value = "leaves", key = "'my-responsibilities:' + T(com.civiltech.civildesk_backend.security.SecurityUtils).getCurrentUserId()")
    @Transactional(readOnly = true)
    public List<LeaveResponse> getMyResponsibilities() {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        String employeeIdStr = String.valueOf(employee.getId());
        List<Leave> leaves = leaveRepository.findLeavesWithHandoverResponsibility(employeeIdStr);
        
        // Filter approved and pending leaves (exclude rejected and cancelled)
        leaves = leaves.stream()
                .filter(leave -> leave.getStatus() == Leave.LeaveStatus.APPROVED || 
                               leave.getStatus() == Leave.LeaveStatus.PENDING)
                .collect(Collectors.toList());

        // Convert to response and add conflict information
        List<LeaveResponse> responses = leaves.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
        
        // Check for conflicts for each responsibility (check if assigned employee has overlapping leaves)
        for (LeaveResponse response : responses) {
            checkAndSetConflicts(response, employee.getId());
        }

        return responses;
    }
    
    // Check for conflicts when assigning responsibilities
    private void checkAndSetConflicts(LeaveResponse response, Long assignedEmployeeId) {
        List<LeaveResponse.ConflictInfo> conflicts = new ArrayList<>();
        
        // Check if assigned employee has overlapping leaves
        List<Leave> employeeLeaves = leaveRepository.findLeavesByEmployeeAndDateRange(
            assignedEmployeeId,
            response.getStartDate(),
            response.getEndDate()
        );
        
        // Filter only approved or pending leaves (exclude rejected/cancelled)
        employeeLeaves = employeeLeaves.stream()
                .filter(leave -> leave.getStatus() == Leave.LeaveStatus.APPROVED || 
                               leave.getStatus() == Leave.LeaveStatus.PENDING)
                .filter(leave -> !leave.getId().equals(response.getId())) // Exclude the current leave
                .collect(Collectors.toList());
        
        for (Leave conflictingLeave : employeeLeaves) {
            LeaveResponse.ConflictInfo conflict = new LeaveResponse.ConflictInfo();
            conflict.setEmployeeId(conflictingLeave.getEmployee().getId());
            conflict.setEmployeeName(conflictingLeave.getEmployee().getFirstName() + " " + 
                                   conflictingLeave.getEmployee().getLastName());
            conflict.setEmployeeId_str(conflictingLeave.getEmployee().getEmployeeId());
            conflict.setLeaveStartDate(conflictingLeave.getStartDate());
            conflict.setLeaveEndDate(conflictingLeave.getEndDate());
            conflict.setLeaveType(conflictingLeave.getLeaveType().getDisplayName());
            conflict.setConflictType(determineConflictType(
                response.getStartDate(), response.getEndDate(),
                conflictingLeave.getStartDate(), conflictingLeave.getEndDate()
            ));
            conflicts.add(conflict);
        }
        
        response.setConflicts(conflicts);
        response.setHasConflicts(!conflicts.isEmpty());
    }
    
    // Determine the type of conflict
    private String determineConflictType(LocalDate leave1Start, LocalDate leave1End,
                                        LocalDate leave2Start, LocalDate leave2End) {
        if (leave1Start.equals(leave2Start) && leave1End.equals(leave2End)) {
            return "EXACT_OVERLAP";
        } else if (leave1Start.isBefore(leave2Start) && leave1End.isAfter(leave2End)) {
            return "COMPLETE_OVERLAP";
        } else if (leave2Start.isBefore(leave1Start) && leave2End.isAfter(leave1End)) {
            return "COMPLETE_OVERLAP";
        } else if ((leave1Start.isBefore(leave2End) || leave1Start.equals(leave2End)) &&
                   (leave1End.isAfter(leave2Start) || leave1End.equals(leave2Start))) {
            return "PARTIAL_OVERLAP";
        }
        return "NO_OVERLAP";
    }

    // Get all leaves (Admin/HR only)
    @Cacheable(value = "leaves", key = "'all-leaves'")
    @Transactional(readOnly = true)
    public List<LeaveResponse> getAllLeaves() {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all leaves");
        }

        List<Leave> leaves = leaveRepository.findByDeletedFalse();
        
        return leaves.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get leaves by status (Admin/HR only)
    @Cacheable(value = "leaves", key = "'leaves-status:' + #status")
    @Transactional(readOnly = true)
    public List<LeaveResponse> getLeavesByStatus(Leave.LeaveStatus status) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter leaves");
        }

        List<Leave> leaves = leaveRepository.findByStatusAndDeletedFalse(status);
        
        return leaves.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get leaves by leave type (Admin/HR only)
    public List<LeaveResponse> getLeavesByType(Leave.LeaveType leaveType) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter leaves");
        }

        List<Leave> leaves = leaveRepository.findByLeaveTypeAndDeletedFalse(leaveType);
        
        return leaves.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get leaves by department (Admin/HR only)
    public List<LeaveResponse> getLeavesByDepartment(String department) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter leaves");
        }

        List<Leave> leaves = leaveRepository.findLeavesByDepartment(department);
        
        return leaves.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Paginated methods
    @Transactional(readOnly = true)
    public Page<LeaveResponse> getAllLeavesPaginated(String status, String leaveType, String department, Pageable pageable) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all leaves");
        }

        Page<Leave> leaves;
        
        if (status != null && !status.isEmpty()) {
            try {
                Leave.LeaveStatus leaveStatus = Leave.LeaveStatus.valueOf(status.toUpperCase());
                leaves = leaveRepository.findByStatusAndDeletedFalse(leaveStatus, pageable);
            } catch (IllegalArgumentException e) {
                throw new BadRequestException("Invalid status value: " + status);
            }
        } else if (leaveType != null && !leaveType.isEmpty()) {
            try {
                Leave.LeaveType type = Leave.LeaveType.valueOf(leaveType.toUpperCase());
                leaves = leaveRepository.findByLeaveTypeAndDeletedFalse(type, pageable);
            } catch (IllegalArgumentException e) {
                throw new BadRequestException("Invalid leave type value: " + leaveType);
            }
        } else if (department != null && !department.isEmpty()) {
            leaves = leaveRepository.findLeavesByDepartment(department, pageable);
        } else {
            leaves = leaveRepository.findByDeletedFalse(pageable);
        }
        
        return leaves.map(this::convertToResponse);
    }

    // Get leave by ID
    @Cacheable(value = "leaves", key = "#leaveId")
    @Transactional(readOnly = true)
    public LeaveResponse getLeaveById(@NonNull Long leaveId) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Leave leave = leaveRepository.findById(leaveId)
                .orElseThrow(() -> new ResourceNotFoundException("Leave not found with id: " + leaveId));

        // Check if leave is deleted
        if (leave.getDeleted()) {
            throw new ResourceNotFoundException("Leave not found with id: " + leaveId);
        }

        // Check authorization
        boolean isOwnLeave = leave.getEmployee().getUser().getId().equals(currentUser.getId());
        boolean isAdminOrHR = currentUser.getRole() == User.Role.ADMIN || 
                              currentUser.getRole() == User.Role.HR_MANAGER;

        if (!isOwnLeave && !isAdminOrHR) {
            throw new UnauthorizedException("You are not authorized to view this leave");
        }

        return convertToResponse(leave);
    }

    // Review leave (Approve/Reject) - Admin/HR only
    @Caching(evict = {
        @CacheEvict(value = "leaves", key = "#leaveId"),
        @CacheEvict(value = "leaves", allEntries = true)
    })
    public LeaveResponse reviewLeave(@NonNull Long leaveId, LeaveReviewRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can review leaves");
        }

        Leave leave = leaveRepository.findById(leaveId)
                .orElseThrow(() -> new ResourceNotFoundException("Leave not found with id: " + leaveId));

        // Check if leave is deleted
        if (leave.getDeleted()) {
            throw new ResourceNotFoundException("Leave not found with id: " + leaveId);
        }

        // Check if leave is in PENDING status
        if (leave.getStatus() != Leave.LeaveStatus.PENDING) {
            throw new BadRequestException("Can only review leaves in PENDING status");
        }

        // Validate status
        if (request.getStatus() != Leave.LeaveStatus.APPROVED && 
            request.getStatus() != Leave.LeaveStatus.REJECTED) {
            throw new BadRequestException("Status must be either APPROVED or REJECTED");
        }

        // Update leave
        leave.setStatus(request.getStatus());
        leave.setReviewedBy(currentUser);
        leave.setReviewedAt(LocalDateTime.now());
        leave.setReviewNote(request.getReviewNote());

        leave = leaveRepository.save(leave);

        // Send notification to employee
        if (leave.getEmployee() != null && leave.getEmployee().getUser() != null 
                && leave.getEmployee().getUser().getId() != null) {
            try {
                if (request.getStatus() == Leave.LeaveStatus.APPROVED) {
                    notificationService.notifyLeaveApproved(
                            leave.getEmployee().getUser().getId(),
                            leave.getId()
                    );
                } else if (request.getStatus() == Leave.LeaveStatus.REJECTED) {
                    notificationService.notifyLeaveRejected(
                            leave.getEmployee().getUser().getId(),
                            leave.getId(),
                            request.getReviewNote()
                    );
                }
            } catch (Exception e) {
                logger.error("Failed to send leave status notification", e);
            }
        }

        return convertToResponse(leave);
    }

    // Helper method to validate dates
    private void validateLeaveDates(LocalDate startDate, LocalDate endDate) {
        if (startDate.isBefore(LocalDate.now())) {
            throw new BadRequestException("Start date cannot be in the past");
        }

        if (endDate.isBefore(startDate)) {
            throw new BadRequestException("End date cannot be before start date");
        }
    }
    
    // Validate handover employees exist and are active
    private void validateHandoverEmployees(List<Long> handoverEmployeeIds, 
                                          LocalDate startDate, LocalDate endDate, 
                                          Long currentEmployeeId) {
        for (Long empId : handoverEmployeeIds) {
            if (empId.equals(currentEmployeeId)) {
                throw new BadRequestException("Cannot assign responsibilities to yourself");
            }
            
            Employee emp = employeeRepository.findById(empId)
                    .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + empId));
            
            if (emp.getDeleted() != null && emp.getDeleted()) {
                throw new BadRequestException("Cannot assign responsibilities to deleted employee: " + emp.getEmployeeId());
            }
            
            if (emp.getEmploymentStatus() != Employee.EmploymentStatus.ACTIVE) {
                throw new BadRequestException("Cannot assign responsibilities to inactive employee: " + emp.getEmployeeId());
            }
        }
    }
    
    // Check for conflicts in handover employees
    private void checkHandoverConflicts(LeaveResponse response, List<Long> handoverEmployeeIds,
                                       LocalDate leaveStartDate, LocalDate leaveEndDate) {
        List<LeaveResponse.ConflictInfo> conflicts = new ArrayList<>();
        
        for (Long handoverEmpId : handoverEmployeeIds) {
            // Check if handover employee has overlapping leaves
            List<Leave> employeeLeaves = leaveRepository.findLeavesByEmployeeAndDateRange(
                handoverEmpId, leaveStartDate, leaveEndDate
            );
            
            // Filter only approved or pending leaves
            employeeLeaves = employeeLeaves.stream()
                    .filter(leave -> leave.getStatus() == Leave.LeaveStatus.APPROVED || 
                                   leave.getStatus() == Leave.LeaveStatus.PENDING)
                    .filter(leave -> !leave.getId().equals(response.getId())) // Exclude current leave
                    .collect(Collectors.toList());
            
            for (Leave conflictingLeave : employeeLeaves) {
                LeaveResponse.ConflictInfo conflict = new LeaveResponse.ConflictInfo();
                conflict.setEmployeeId(conflictingLeave.getEmployee().getId());
                conflict.setEmployeeName(conflictingLeave.getEmployee().getFirstName() + " " + 
                                       conflictingLeave.getEmployee().getLastName());
                conflict.setEmployeeId_str(conflictingLeave.getEmployee().getEmployeeId());
                conflict.setLeaveStartDate(conflictingLeave.getStartDate());
                conflict.setLeaveEndDate(conflictingLeave.getEndDate());
                conflict.setLeaveType(conflictingLeave.getLeaveType().getDisplayName());
                conflict.setConflictType(determineConflictType(
                    leaveStartDate, leaveEndDate,
                    conflictingLeave.getStartDate(), conflictingLeave.getEndDate()
                ));
                conflicts.add(conflict);
            }
        }
        
        response.setConflicts(conflicts);
        response.setHasConflicts(!conflicts.isEmpty());
    }

    // Helper method to calculate leave days
    private double calculateLeaveDays(LocalDate startDate, LocalDate endDate, boolean isHalfDay) {
        if (isHalfDay) {
            return 0.5;
        }

        long days = ChronoUnit.DAYS.between(startDate, endDate) + 1;
        return (double) days;
    }

    // Helper method to convert Leave entity to LeaveResponse
    private LeaveResponse convertToResponse(Leave leave) {
        LeaveResponse response = new LeaveResponse();
        response.setId(leave.getId());
        response.setEmployeeId(leave.getEmployee().getId());
        response.setEmployeeName(leave.getEmployee().getFirstName() + " " + leave.getEmployee().getLastName());
        response.setEmployeeEmail(leave.getEmployee().getEmail());
        response.setEmployeeId_str(leave.getEmployee().getEmployeeId());
        response.setDepartment(leave.getEmployee().getDepartment());
        response.setDesignation(leave.getEmployee().getDesignation());
        response.setLeaveType(leave.getLeaveType());
        response.setLeaveTypeDisplay(leave.getLeaveType().getDisplayName());
        response.setStartDate(leave.getStartDate());
        response.setEndDate(leave.getEndDate());
        response.setIsHalfDay(leave.getIsHalfDay());
        response.setHalfDayPeriod(leave.getHalfDayPeriod());
        
        if (leave.getHalfDayPeriod() != null) {
            response.setHalfDayPeriodDisplay(leave.getHalfDayPeriod().getDisplayName());
        }
        
        response.setContactNumber(leave.getContactNumber());
        response.setReason(leave.getReason());
        response.setMedicalCertificateUrl(leave.getMedicalCertificateUrl());
        response.setStatus(leave.getStatus());
        response.setStatusDisplay(leave.getStatus().getDisplayName());
        response.setTotalDays(leave.getTotalDays());
        response.setCreatedAt(leave.getCreatedAt());
        response.setUpdatedAt(leave.getUpdatedAt());
        
        // Initialize conflict fields
        response.setHasConflicts(false);
        response.setConflicts(new ArrayList<>());

        // Set handover employees
        if (leave.getHandoverEmployeeIds() != null && !leave.getHandoverEmployeeIds().isEmpty()) {
            List<Long> employeeIds = Arrays.stream(leave.getHandoverEmployeeIds().split(","))
                    .map(Long::valueOf)
                    .collect(Collectors.toList());

            List<LeaveResponse.HandoverEmployeeInfo> handoverEmployees = new ArrayList<>();
            for (Long empId : employeeIds) {
                employeeRepository.findById(Objects.requireNonNull(empId, "Employee ID cannot be null")).ifPresent(emp -> {
                    if (emp.getId() != null) {
                        LeaveResponse.HandoverEmployeeInfo info = new LeaveResponse.HandoverEmployeeInfo();
                        info.setId(emp.getId());
                        info.setName(emp.getFirstName() + " " + emp.getLastName());
                        info.setEmployeeId(emp.getEmployeeId());
                        info.setDesignation(emp.getDesignation());
                        info.setEmail(emp.getEmail());
                        handoverEmployees.add(info);
                    }
                });
            }
            response.setHandoverEmployees(handoverEmployees);
        }

        // Set reviewer info
        if (leave.getReviewedBy() != null) {
            LeaveResponse.ReviewerInfo reviewerInfo = new LeaveResponse.ReviewerInfo();
            reviewerInfo.setId(leave.getReviewedBy().getId());
            reviewerInfo.setName(leave.getReviewedBy().getFirstName() + " " + leave.getReviewedBy().getLastName());
            reviewerInfo.setEmail(leave.getReviewedBy().getEmail());
            reviewerInfo.setRole(leave.getReviewedBy().getRole().name());
            response.setReviewedBy(reviewerInfo);
            response.setReviewedAt(leave.getReviewedAt());
            response.setReviewNote(leave.getReviewNote());
        }

        return response;
    }
}

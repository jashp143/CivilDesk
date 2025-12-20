package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.annotation.RequiresRole;
import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.LeaveRequest;
import com.civiltech.civildesk_backend.dto.LeaveResponse;
import com.civiltech.civildesk_backend.dto.LeaveReviewRequest;
import com.civiltech.civildesk_backend.model.Leave;
import com.civiltech.civildesk_backend.service.LeaveService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.NonNull;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/leaves")
@CrossOrigin(origins = "*")
public class LeaveController {

    @Autowired
    private LeaveService leaveService;

    // Apply for leave
    @PostMapping
    public ResponseEntity<ApiResponse<LeaveResponse>> applyLeave(@Valid @RequestBody LeaveRequest request) {
        LeaveResponse response = leaveService.applyLeave(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Leave application submitted successfully", response));
    }

    // Update leave
    @PutMapping("/{leaveId}")
    public ResponseEntity<ApiResponse<LeaveResponse>> updateLeave(
            @PathVariable @NonNull Long leaveId,
            @Valid @RequestBody LeaveRequest request) {
        LeaveResponse response = leaveService.updateLeave(leaveId, request);
        return ResponseEntity.ok(ApiResponse.success("Leave updated successfully", response));
    }

    // Delete leave
    @DeleteMapping("/{leaveId}")
    public ResponseEntity<ApiResponse<Void>> deleteLeave(@PathVariable @NonNull Long leaveId) {
        leaveService.deleteLeave(leaveId);
        return ResponseEntity.ok(ApiResponse.success("Leave deleted successfully", null));
    }

    // Get my leaves (current employee)
    @GetMapping("/my-leaves")
    public ResponseEntity<ApiResponse<List<LeaveResponse>>> getMyLeaves() {
        List<LeaveResponse> leaves = leaveService.getMyLeaves();
        return ResponseEntity.ok(ApiResponse.success("Leaves fetched successfully", leaves));
    }

    // Get my responsibilities (leaves where current employee is assigned responsibilities)
    @GetMapping("/my-responsibilities")
    public ResponseEntity<ApiResponse<List<LeaveResponse>>> getMyResponsibilities() {
        List<LeaveResponse> leaves = leaveService.getMyResponsibilities();
        return ResponseEntity.ok(ApiResponse.success("Responsibilities fetched successfully", leaves));
    }

    // Get all leaves (Admin/HR only)
    @GetMapping
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<List<LeaveResponse>>> getAllLeaves(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String leaveType,
            @RequestParam(required = false) String department) {
        
        List<LeaveResponse> leaves;

        if (status != null && !status.isEmpty()) {
            try {
                Leave.LeaveStatus leaveStatus = Leave.LeaveStatus.valueOf(status.toUpperCase());
                leaves = leaveService.getLeavesByStatus(leaveStatus);
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Invalid status value", 400));
            }
        } else if (leaveType != null && !leaveType.isEmpty()) {
            try {
                Leave.LeaveType type = Leave.LeaveType.valueOf(leaveType.toUpperCase());
                leaves = leaveService.getLeavesByType(type);
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Invalid leave type value", 400));
            }
        } else if (department != null && !department.isEmpty()) {
            leaves = leaveService.getLeavesByDepartment(department);
        } else {
            leaves = leaveService.getAllLeaves();
        }

        return ResponseEntity.ok(ApiResponse.success("Leaves fetched successfully", leaves));
    }

    // Get leave by ID
    @GetMapping("/{leaveId}")
    public ResponseEntity<ApiResponse<LeaveResponse>> getLeaveById(@PathVariable @NonNull Long leaveId) {
        LeaveResponse leave = leaveService.getLeaveById(leaveId);
        return ResponseEntity.ok(ApiResponse.success("Leave fetched successfully", leave));
    }

    // Review leave (Approve/Reject) - Admin/HR only
    @PutMapping("/{leaveId}/review")
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<LeaveResponse>> reviewLeave(
            @PathVariable @NonNull Long leaveId,
            @Valid @RequestBody LeaveReviewRequest request) {
        LeaveResponse response = leaveService.reviewLeave(leaveId, request);
        return ResponseEntity.ok(ApiResponse.success("Leave reviewed successfully", response));
    }

    // Get all leave types
    @GetMapping("/types")
    public ResponseEntity<ApiResponse<List<String>>> getLeaveTypes() {
        List<String> leaveTypes = List.of(
                "SICK_LEAVE",
                "CASUAL_LEAVE",
                "ANNUAL_LEAVE",
                "MATERNITY_LEAVE",
                "PATERNITY_LEAVE",
                "MEDICAL_LEAVE",
                "EMERGENCY_LEAVE",
                "UNPAID_LEAVE",
                "COMPENSATORY_OFF"
        );
        return ResponseEntity.ok(ApiResponse.success("Leave types fetched successfully", leaveTypes));
    }

    // Get all leave statuses
    @GetMapping("/statuses")
    public ResponseEntity<ApiResponse<List<String>>> getLeaveStatuses() {
        List<String> statuses = List.of(
                "PENDING",
                "APPROVED",
                "REJECTED",
                "CANCELLED"
        );
        return ResponseEntity.ok(ApiResponse.success("Leave statuses fetched successfully", statuses));
    }
}

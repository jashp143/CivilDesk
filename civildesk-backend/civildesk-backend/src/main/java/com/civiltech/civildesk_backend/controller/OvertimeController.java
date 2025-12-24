package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.annotation.RequiresRole;
import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.OvertimeRequest;
import com.civiltech.civildesk_backend.dto.OvertimeResponse;
import com.civiltech.civildesk_backend.dto.OvertimeReviewRequest;
import com.civiltech.civildesk_backend.model.Overtime;
import com.civiltech.civildesk_backend.service.OvertimeService;
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

import java.util.List;

@RestController
@RequestMapping("/api/overtimes")
@CrossOrigin(origins = "*")
public class OvertimeController {

    @Autowired
    private OvertimeService overtimeService;

    // Apply for overtime
    @PostMapping
    public ResponseEntity<ApiResponse<OvertimeResponse>> applyOvertime(@Valid @RequestBody OvertimeRequest request) {
        OvertimeResponse response = overtimeService.applyOvertime(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Overtime application submitted successfully", response));
    }

    // Update overtime
    @PutMapping("/{overtimeId}")
    public ResponseEntity<ApiResponse<OvertimeResponse>> updateOvertime(
            @PathVariable @NonNull Long overtimeId,
            @Valid @RequestBody OvertimeRequest request) {
        OvertimeResponse response = overtimeService.updateOvertime(overtimeId, request);
        return ResponseEntity.ok(ApiResponse.success("Overtime updated successfully", response));
    }

    // Delete overtime
    @DeleteMapping("/{overtimeId}")
    public ResponseEntity<ApiResponse<Void>> deleteOvertime(@PathVariable @NonNull Long overtimeId) {
        overtimeService.deleteOvertime(overtimeId);
        return ResponseEntity.ok(ApiResponse.success("Overtime deleted successfully", null));
    }

    // Get my overtimes (current employee)
    @GetMapping("/my-overtimes")
    public ResponseEntity<ApiResponse<List<OvertimeResponse>>> getMyOvertimes() {
        List<OvertimeResponse> overtimes = overtimeService.getMyOvertimes();
        return ResponseEntity.ok(ApiResponse.success("Overtimes fetched successfully", overtimes));
    }

    // Get all overtimes (Admin/HR only)
    @GetMapping
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<?>> getAllOvertimes(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String department,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String sortDir) {
        
        // If pagination parameters are provided, return paginated response
        if (page != null && size != null) {
            Sort sort = Sort.by(Sort.Direction.fromString(sortDir != null ? sortDir : "DESC"), 
                    sortBy != null ? sortBy : "createdAt");
            Pageable pageable = PageRequest.of(page, size, sort);
            Page<OvertimeResponse> pageResponse = overtimeService.getAllOvertimesPaginated(status, department, pageable);
            return ResponseEntity.ok(ApiResponse.success("Overtimes fetched successfully", pageResponse));
        } else {
            // Return list for backward compatibility
            List<OvertimeResponse> overtimes;

            if (status != null && !status.isEmpty()) {
                try {
                    Overtime.OvertimeStatus overtimeStatus = Overtime.OvertimeStatus.valueOf(status.toUpperCase());
                    overtimes = overtimeService.getOvertimesByStatus(overtimeStatus);
                } catch (IllegalArgumentException e) {
                    return ResponseEntity.badRequest()
                            .body(ApiResponse.error("Invalid status value", 400));
                }
            } else if (department != null && !department.isEmpty()) {
                overtimes = overtimeService.getOvertimesByDepartment(department);
            } else {
                overtimes = overtimeService.getAllOvertimes();
            }

            return ResponseEntity.ok(ApiResponse.success("Overtimes fetched successfully", overtimes));
        }
    }

    // Get overtime by ID
    @GetMapping("/{overtimeId}")
    public ResponseEntity<ApiResponse<OvertimeResponse>> getOvertimeById(@PathVariable @NonNull Long overtimeId) {
        OvertimeResponse overtime = overtimeService.getOvertimeById(overtimeId);
        return ResponseEntity.ok(ApiResponse.success("Overtime fetched successfully", overtime));
    }

    // Review overtime (Approve/Reject) - Admin/HR only
    @PutMapping("/{overtimeId}/review")
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<OvertimeResponse>> reviewOvertime(
            @PathVariable @NonNull Long overtimeId,
            @Valid @RequestBody OvertimeReviewRequest request) {
        OvertimeResponse response = overtimeService.reviewOvertime(overtimeId, request);
        return ResponseEntity.ok(ApiResponse.success("Overtime reviewed successfully", response));
    }

    // Get all overtime statuses
    @GetMapping("/statuses")
    public ResponseEntity<ApiResponse<List<String>>> getOvertimeStatuses() {
        List<String> statuses = List.of(
                "PENDING",
                "APPROVED",
                "REJECTED"
        );
        return ResponseEntity.ok(ApiResponse.success("Overtime statuses fetched successfully", statuses));
    }
}

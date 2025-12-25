package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.AttendanceRequest;
import com.civiltech.civildesk_backend.dto.AttendanceResponse;
import com.civiltech.civildesk_backend.dto.AttendanceAnalyticsResponse;
import com.civiltech.civildesk_backend.dto.FaceRecognitionResponse;
import com.civiltech.civildesk_backend.model.Attendance;
import com.civiltech.civildesk_backend.service.AbsentAttendanceService;
import com.civiltech.civildesk_backend.service.AttendanceService;
import com.civiltech.civildesk_backend.service.FaceRecognitionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/attendance")
@CrossOrigin(origins = "*")
public class AttendanceController {

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    private FaceRecognitionService faceRecognitionService;

    @Autowired
    private AbsentAttendanceService absentAttendanceService;

    @PostMapping("/mark")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AttendanceResponse>> markAttendance(
            @RequestParam(value = "image", required = false) MultipartFile imageFile,
            @RequestParam(value = "employee_id", required = false) String employeeId,
            @RequestParam(value = "attendance_type", required = false) String attendanceType) {
        try {
            AttendanceRequest request = new AttendanceRequest();
            
            // If image is provided, try face recognition first
            if (imageFile != null && !imageFile.isEmpty()) {
                FaceRecognitionResponse recognitionResponse = faceRecognitionService.detectFaces(imageFile);
                
                if (recognitionResponse != null && recognitionResponse.isSuccess() && 
                    recognitionResponse.getFaces() != null && !recognitionResponse.getFaces().isEmpty()) {
                    
                    // Find recognized face
                    FaceRecognitionResponse.DetectedFace recognizedFace = recognitionResponse.getFaces().stream()
                            .filter(FaceRecognitionResponse.DetectedFace::isRecognized)
                            .findFirst()
                            .orElse(null);
                    
                    if (recognizedFace != null) {
                        // Face recognition successful
                        request.setEmployeeId(recognizedFace.getEmployeeId());
                        request.setRecognitionMethod("FACE_RECOGNITION");
                        request.setFaceRecognitionConfidence(recognizedFace.getMatchConfidence());
                        request.setAttendanceType(attendanceType);
                    } else if (employeeId != null) {
                        // Face recognition failed but employee_id provided - use it as fallback
                        request.setEmployeeId(employeeId);
                        request.setRecognitionMethod("FACE_RECOGNITION"); // Still using face recognition method since image was sent
                        request.setAttendanceType(attendanceType);
                    } else {
                        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                                .body(ApiResponse.error("No recognized face found in the image and no employee_id provided"));
                    }
                } else {
                    // Face detection failed - fall back to employee_id if provided
                    if (employeeId != null) {
                        request.setEmployeeId(employeeId);
                        request.setRecognitionMethod("FACE_RECOGNITION"); // Still using face recognition method since image was sent
                        request.setAttendanceType(attendanceType);
                    } else {
                        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                                .body(ApiResponse.error("Face detection failed and no employee_id provided"));
                    }
                }
            } else if (employeeId != null) {
                // Manual attendance marking (no image, only employee_id)
                request.setEmployeeId(employeeId);
                request.setRecognitionMethod("MANUAL");
                request.setAttendanceType(attendanceType);
            } else {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Either image file or employee_id is required"));
            }
            
            AttendanceResponse response = attendanceService.markAttendance(request);
            return ResponseEntity.ok(
                    ApiResponse.success("Attendance marked successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error marking attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @PostMapping("/checkout")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AttendanceResponse>> checkOut(
            @RequestParam("employee_id") String employeeId) {
        try {
            AttendanceResponse response = attendanceService.checkOut(employeeId);
            return ResponseEntity.ok(
                    ApiResponse.success("Check-out successful", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error during check-out: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/today/{employeeId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AttendanceResponse>> getTodayAttendance(
            @PathVariable String employeeId) {
        try {
            AttendanceResponse response = attendanceService.getTodayAttendance(employeeId);
            if (response != null) {
                return ResponseEntity.ok(
                        ApiResponse.success("Today's attendance retrieved successfully", response));
            } else {
                return ResponseEntity.ok(
                        ApiResponse.success("No attendance record for today", null));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/employee/{employeeId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<?>> getEmployeeAttendance(
            @PathVariable String employeeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "date") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDir) {
        try {
            if (startDate == null) {
                startDate = LocalDate.now().minusMonths(1);
            }
            if (endDate == null) {
                endDate = LocalDate.now();
            }
            
            // Use pagination if page/size are provided (non-zero page or size != default)
            if (page > 0 || size != 20) {
                Sort sort = sortDir.equalsIgnoreCase("ASC") ? 
                    Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
                Pageable pageable = PageRequest.of(page, size, sort);
                Page<AttendanceResponse> responses = attendanceService.getEmployeeAttendancePaginated(
                        employeeId, startDate, endDate, pageable);
                return ResponseEntity.ok(
                        ApiResponse.success("Attendance records retrieved successfully", responses));
            } else {
                // Backward compatibility: return list if pagination not requested
                List<AttendanceResponse> responses = attendanceService.getEmployeeAttendance(
                        employeeId, startDate, endDate);
                return ResponseEntity.ok(
                        ApiResponse.success("Attendance records retrieved successfully", responses));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/daily")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<?>> getDailyAttendance(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "25") int size,
            @RequestParam(defaultValue = "employeeId") String sortBy,
            @RequestParam(defaultValue = "ASC") String sortDir) {
        try {
            if (date == null) {
                date = LocalDate.now();
            }
            
            // Always use pagination when page and size are provided
            Sort sort = sortDir.equalsIgnoreCase("DESC") ? 
                Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
            Pageable pageable = PageRequest.of(page, size, sort);
            Page<AttendanceResponse> responses = attendanceService.getDailyAttendancePaginated(date, pageable);
            return ResponseEntity.ok(
                    ApiResponse.success("Daily attendance retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving daily attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/daily/summary")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getDailyAttendanceSummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        try {
            if (date == null) {
                date = LocalDate.now();
            }
            
            Map<String, Long> summary = attendanceService.getDailyAttendanceSummary(date);
            return ResponseEntity.ok(
                    ApiResponse.success("Daily attendance summary retrieved successfully", summary));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving daily attendance summary: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    // Employee-specific endpoints (using authenticated user's ID)
    @PostMapping("/my-attendance/mark")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> markMyAttendance(
            @RequestBody AttendanceRequest request) {
        try {
            // Get employee ID from authenticated user
            Long userId = com.civiltech.civildesk_backend.security.SecurityUtils.getCurrentUserId();
            
            // Find employee by user ID
            com.civiltech.civildesk_backend.model.Employee employee = 
                attendanceService.getEmployeeByUserId(userId);
            
            if (employee == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Employee record not found for current user"));
            }
            
            request.setEmployeeId(employee.getEmployeeId());
            request.setRecognitionMethod("SELF_SERVICE");
            
            AttendanceResponse response = attendanceService.markAttendance(request);
            return ResponseEntity.ok(
                    ApiResponse.success("Attendance marked successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error marking attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/my-attendance")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<List<AttendanceResponse>>> getMyAttendance(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        try {
            // Get employee ID from authenticated user
            Long userId = com.civiltech.civildesk_backend.security.SecurityUtils.getCurrentUserId();
            
            // Find employee by user ID
            com.civiltech.civildesk_backend.model.Employee employee = 
                attendanceService.getEmployeeByUserId(userId);
            
            if (employee == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Employee record not found for current user"));
            }
            
            // If specific date is requested, get attendance for that date
            if (date != null) {
                List<AttendanceResponse> responses = attendanceService.getEmployeeAttendance(
                        employee.getEmployeeId(), date, date);
                return ResponseEntity.ok(
                        ApiResponse.success("Attendance record retrieved successfully", responses));
            }
            
            // Otherwise, get attendance for date range
            if (startDate == null) {
                startDate = LocalDate.now().minusMonths(1);
            }
            if (endDate == null) {
                endDate = LocalDate.now();
            }
            
            List<AttendanceResponse> responses = attendanceService.getEmployeeAttendance(
                    employee.getEmployeeId(), startDate, endDate);
            return ResponseEntity.ok(
                    ApiResponse.success("Attendance records retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/my-attendance/today")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> getMyTodayAttendance() {
        try {
            // Get employee ID from authenticated user
            Long userId = com.civiltech.civildesk_backend.security.SecurityUtils.getCurrentUserId();
            
            // Find employee by user ID
            com.civiltech.civildesk_backend.model.Employee employee = 
                attendanceService.getEmployeeByUserId(userId);
            
            if (employee == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Employee record not found for current user"));
            }
            
            AttendanceResponse response = attendanceService.getTodayAttendance(employee.getEmployeeId());
            if (response != null) {
                return ResponseEntity.ok(
                        ApiResponse.success("Today's attendance retrieved successfully", response));
            } else {
                return ResponseEntity.ok(
                        ApiResponse.success("No attendance record for today", null));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @PutMapping("/update-punch-time")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> updatePunchTime(
            @RequestParam(value = "attendance_id", required = false) Long attendanceId,
            @RequestParam(value = "employee_id", required = false) String employeeId,
            @RequestParam(value = "date", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam("punch_type") String punchType,
            @RequestParam("new_time") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) java.time.LocalDateTime newTime) {
        try {
            AttendanceResponse response;
            if (attendanceId != null) {
                // Update existing attendance record
                response = attendanceService.updatePunchTime(attendanceId, punchType, newTime);
            } else if (employeeId != null && date != null) {
                // Create or update attendance record for employee and date
                response = attendanceService.createOrUpdatePunchTime(employeeId, date, punchType, newTime);
            } else {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Either attendance_id or (employee_id and date) must be provided", HttpStatus.BAD_REQUEST.value()));
            }
            return ResponseEntity.ok(
                    ApiResponse.success("Punch time updated successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error updating punch time: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/analytics/{employeeId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<AttendanceAnalyticsResponse>> getAttendanceAnalytics(
            @PathVariable String employeeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        try {
            AttendanceAnalyticsResponse response = attendanceService.getAttendanceAnalytics(employeeId, startDate, endDate);
            return ResponseEntity.ok(
                    ApiResponse.success("Attendance analytics retrieved successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving attendance analytics: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    /**
     * Manually mark an employee as absent for a specific date.
     * Only accessible by ADMIN or HR_MANAGER.
     */
    @PostMapping("/mark-absent")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> markAbsent(
            @RequestParam("employee_id") String employeeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        try {
            Attendance absentAttendance = absentAttendanceService.markEmployeeAbsent(employeeId, date);
            AttendanceResponse response = attendanceService.mapToResponse(absentAttendance);
            return ResponseEntity.ok(
                    ApiResponse.success("Employee marked as absent successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error marking absent: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    /**
     * Manually mark attendance for a specific employee and date (admin function).
     * Used for emergency situations when employee forgot to mark attendance.
     */
    @PostMapping("/mark-manual")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> markAttendanceManual(
            @RequestParam("employee_id") String employeeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(value = "attendance_type", defaultValue = "PUNCH_IN") String attendanceType) {
        try {
            AttendanceResponse response = attendanceService.markAttendanceForDate(employeeId, date, attendanceType);
            return ResponseEntity.ok(
                    ApiResponse.success("Attendance marked successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error marking attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    /**
     * Bulk mark absent for multiple employees on a specific date.
     * Only accessible by ADMIN or HR_MANAGER.
     */
    @PostMapping("/bulk-mark-absent")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> bulkMarkAbsent(
            @RequestBody Map<String, Object> request) {
        try {
            @SuppressWarnings("unchecked")
            List<String> employeeIds = (List<String>) request.get("employee_ids");
            String dateStr = (String) request.get("date");
            LocalDate date = LocalDate.parse(dateStr);

            if (employeeIds == null || employeeIds.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("employee_ids list is required and cannot be empty"));
            }

            int count = absentAttendanceService.bulkMarkAbsent(employeeIds, date);
            return ResponseEntity.ok(
                    ApiResponse.success("Bulk absent marking completed", 
                            Map.of("marked_count", count, "total_requested", employeeIds.size())));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error in bulk marking absent: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    /**
     * Manually trigger absent marking for a specific date.
     * Useful for backfilling missing records or correcting data.
     * Only accessible by ADMIN or HR_MANAGER.
     */
    @PostMapping("/trigger-absent-marking")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> triggerAbsentMarking(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        try {
            if (date == null) {
                date = LocalDate.now().minusDays(1); // Default to yesterday
            }

            int count = absentAttendanceService.markAbsentForDate(date);
            return ResponseEntity.ok(
                    ApiResponse.success("Absent marking completed for date: " + date, 
                            Map.of("date", date.toString(), "absent_records_created", count)));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error triggering absent marking: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }
}


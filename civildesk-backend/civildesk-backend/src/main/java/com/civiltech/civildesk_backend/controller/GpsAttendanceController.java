package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.GpsAttendanceRequest;
import com.civiltech.civildesk_backend.dto.GpsAttendanceResponse;
import com.civiltech.civildesk_backend.service.GpsAttendanceService;
import com.civiltech.civildesk_backend.service.SiteService;
import com.civiltech.civildesk_backend.dto.SiteResponse;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/gps-attendance")
@CrossOrigin(origins = "*")
public class GpsAttendanceController {

    @Autowired
    private GpsAttendanceService gpsAttendanceService;

    @Autowired
    private SiteService siteService;

    /**
     * Mark GPS-based attendance punch
     */
    @PostMapping("/mark")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<GpsAttendanceResponse>> markAttendance(
            @Valid @RequestBody GpsAttendanceRequest request) {
        try {
            GpsAttendanceResponse response = gpsAttendanceService.markGpsAttendance(request);
            
            String message;
            switch (request.getPunchType()) {
                case CHECK_IN:
                    message = "Check-in successful";
                    break;
                case LUNCH_OUT:
                    message = "Lunch out marked successfully";
                    break;
                case LUNCH_IN:
                    message = "Lunch in marked successfully";
                    break;
                case CHECK_OUT:
                    message = "Check-out successful";
                    break;
                default:
                    message = "Attendance marked successfully";
            }
            
            return ResponseEntity.ok(ApiResponse.success(message, response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * Sync offline attendance punches
     */
    @PostMapping("/sync")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<List<GpsAttendanceResponse>>> syncOfflineAttendance(
            @Valid @RequestBody List<GpsAttendanceRequest> requests) {
        try {
            List<GpsAttendanceResponse> responses = gpsAttendanceService.syncOfflineAttendance(requests);
            return ResponseEntity.ok(ApiResponse.success("Offline attendance synced successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Failed to sync: " + e.getMessage()));
        }
    }

    /**
     * Get my attendance for a specific date
     */
    @GetMapping("/my-attendance")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<List<GpsAttendanceResponse>>> getMyAttendance(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String employeeId) {
        try {
            if (date == null) {
                date = LocalDate.now();
            }
            
            // Get employee ID from token if not provided
            if (employeeId == null || employeeId.isEmpty()) {
                // Would need to get from security context
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(ApiResponse.error("Employee ID is required"));
            }
            
            List<GpsAttendanceResponse> responses = gpsAttendanceService.getEmployeeAttendanceForDate(employeeId, date);
            return ResponseEntity.ok(ApiResponse.success("Attendance retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving attendance: " + e.getMessage()));
        }
    }

    /**
     * Get my assigned sites
     */
    @GetMapping("/my-sites")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<List<SiteResponse>>> getMySites(
            @RequestParam String employeeId) {
        try {
            List<SiteResponse> sites = siteService.getAssignedSitesForEmployee(employeeId);
            return ResponseEntity.ok(ApiResponse.success("Sites retrieved successfully", sites));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving sites: " + e.getMessage()));
        }
    }

    // ==================== Admin Endpoints ====================

    /**
     * Get all attendance punches for a date (Map Dashboard)
     */
    @GetMapping("/dashboard/map")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<List<GpsAttendanceResponse>>> getMapDashboardData(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String employeeId) {
        try {
            if (date == null) {
                date = LocalDate.now();
            }
            
            List<GpsAttendanceResponse> responses = gpsAttendanceService.getAllAttendanceForDate(date, employeeId);
            return ResponseEntity.ok(ApiResponse.success("Map data retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving map data: " + e.getMessage()));
        }
    }

    /**
     * Get attendance for date range
     */
    @GetMapping("/reports")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Page<GpsAttendanceResponse>>> getAttendanceReports(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        try {
            LocalDateTime startDateTime = startDate.atStartOfDay();
            LocalDateTime endDateTime = endDate.atTime(LocalTime.MAX);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<GpsAttendanceResponse> responses = gpsAttendanceService.getAttendanceForDateRange(
                    startDateTime, endDateTime, pageable);
            
            return ResponseEntity.ok(ApiResponse.success("Reports retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving reports: " + e.getMessage()));
        }
    }

    /**
     * Get site-specific attendance
     */
    @GetMapping("/site/{siteId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<List<GpsAttendanceResponse>>> getSiteAttendance(
            @PathVariable Long siteId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        try {
            if (date == null) {
                date = LocalDate.now();
            }
            
            List<GpsAttendanceResponse> responses = gpsAttendanceService.getSiteAttendanceForDate(siteId, date);
            return ResponseEntity.ok(ApiResponse.success("Site attendance retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving site attendance: " + e.getMessage()));
        }
    }

    /**
     * Get employee attendance history
     */
    @GetMapping("/employee/{employeeId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<List<GpsAttendanceResponse>>> getEmployeeAttendance(
            @PathVariable String employeeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        try {
            if (date == null) {
                date = LocalDate.now();
            }
            
            List<GpsAttendanceResponse> responses = gpsAttendanceService.getEmployeeAttendanceForDate(employeeId, date);
            return ResponseEntity.ok(ApiResponse.success("Employee attendance retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving employee attendance: " + e.getMessage()));
        }
    }

    /**
     * Get attendance summary
     */
    @GetMapping("/summary")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAttendanceSummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        try {
            if (date == null) {
                date = LocalDate.now();
            }
            
            List<Object[]> punchCounts = gpsAttendanceService.getAttendanceSummaryForDate(date);
            
            Map<String, Object> summary = new HashMap<>();
            summary.put("date", date.toString());
            
            Map<String, Long> punchTypeCounts = new HashMap<>();
            for (Object[] row : punchCounts) {
                punchTypeCounts.put(row[0].toString(), (Long) row[1]);
            }
            summary.put("punchCounts", punchTypeCounts);
            
            return ResponseEntity.ok(ApiResponse.success("Summary retrieved successfully", summary));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving summary: " + e.getMessage()));
        }
    }
}


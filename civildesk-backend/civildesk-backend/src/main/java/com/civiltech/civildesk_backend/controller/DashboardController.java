package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.DashboardStatsResponse;
import com.civiltech.civildesk_backend.dto.EmployeeDashboardStatsResponse;
import com.civiltech.civildesk_backend.service.DashboardService;
import com.civiltech.civildesk_backend.security.SecurityUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "*")
public class DashboardController {

    @Autowired
    private DashboardService dashboardService;

    @GetMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<DashboardStatsResponse>> getAdminDashboardStats() {
        DashboardStatsResponse stats = dashboardService.getAdminDashboardStats();
        return ResponseEntity.ok(ApiResponse.success("Dashboard stats retrieved successfully", stats));
    }

    @GetMapping("/hr")
    @PreAuthorize("hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<DashboardStatsResponse>> getHrDashboardStats() {
        // HR Manager can see same stats as Admin
        DashboardStatsResponse stats = dashboardService.getAdminDashboardStats();
        return ResponseEntity.ok(ApiResponse.success("Dashboard stats retrieved successfully", stats));
    }

    @GetMapping("/employee")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<EmployeeDashboardStatsResponse>> getEmployeeDashboardStats() {
        Long userId = SecurityUtils.getCurrentUserId();
        EmployeeDashboardStatsResponse stats = dashboardService.getEmployeeDashboardStats(userId);
        return ResponseEntity.ok(ApiResponse.success("Dashboard stats retrieved successfully", stats));
    }
}


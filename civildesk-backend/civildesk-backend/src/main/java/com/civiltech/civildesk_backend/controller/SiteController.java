package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.*;
import com.civiltech.civildesk_backend.service.SiteService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sites")
@CrossOrigin(origins = "*")
public class SiteController {

    @Autowired
    private SiteService siteService;

    // ==================== Site CRUD ====================

    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<SiteResponse>> createSite(@Valid @RequestBody SiteRequest request) {
        SiteResponse response = siteService.createSite(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Site created successfully", response));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<SiteResponse>> updateSite(
            @PathVariable Long id,
            @Valid @RequestBody SiteRequest request) {
        SiteResponse response = siteService.updateSite(id, request);
        return ResponseEntity.ok(ApiResponse.success("Site updated successfully", response));
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<SiteResponse>> getSiteById(@PathVariable Long id) {
        SiteResponse response = siteService.getSiteById(id);
        return ResponseEntity.ok(ApiResponse.success("Site retrieved successfully", response));
    }

    @GetMapping("/code/{siteCode}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<SiteResponse>> getSiteBySiteCode(@PathVariable String siteCode) {
        SiteResponse response = siteService.getSiteBySiteCode(siteCode);
        return ResponseEntity.ok(ApiResponse.success("Site retrieved successfully", response));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Page<SiteResponse>>> getAllSites(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "ASC") String sortDir) {
        Sort sort = sortDir.equalsIgnoreCase("DESC") ? Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
        Pageable pageable = PageRequest.of(page, size, sort);
        Page<SiteResponse> sites = siteService.getAllSites(pageable);
        return ResponseEntity.ok(ApiResponse.success("Sites retrieved successfully", sites));
    }

    @GetMapping("/active")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<SiteResponse>>> getActiveSites() {
        List<SiteResponse> sites = siteService.getActiveSites();
        return ResponseEntity.ok(ApiResponse.success("Active sites retrieved successfully", sites));
    }

    @GetMapping("/search")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Page<SiteResponse>>> searchSites(
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<SiteResponse> sites = siteService.searchSites(search, pageable);
        return ResponseEntity.ok(ApiResponse.success("Sites retrieved successfully", sites));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteSite(@PathVariable Long id) {
        siteService.deleteSite(id);
        return ResponseEntity.ok(ApiResponse.success("Site deleted successfully", null));
    }

    // ==================== Nearby Sites ====================

    @GetMapping("/nearby")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<SiteResponse>>> findNearbySites(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "1000") Double radiusMeters) {
        List<SiteResponse> sites = siteService.findNearbySites(latitude, longitude, radiusMeters);
        return ResponseEntity.ok(ApiResponse.success("Nearby sites retrieved successfully", sites));
    }

    // ==================== Site Assignment ====================

    @PostMapping("/assignments")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<EmployeeSiteAssignmentResponse>> assignEmployeeToSite(
            @Valid @RequestBody EmployeeSiteAssignmentRequest request) {
        EmployeeSiteAssignmentResponse response = siteService.assignEmployeeToSite(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Employee assigned to site successfully", response));
    }

    @DeleteMapping("/assignments/{assignmentId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Void>> removeEmployeeFromSite(@PathVariable Long assignmentId) {
        siteService.removeEmployeeFromSite(assignmentId);
        return ResponseEntity.ok(ApiResponse.success("Employee removed from site successfully", null));
    }

    @GetMapping("/employees/{employeeId}/assignments")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<EmployeeSiteAssignmentResponse>>> getEmployeeAssignments(
            @PathVariable Long employeeId) {
        List<EmployeeSiteAssignmentResponse> assignments = siteService.getEmployeeAssignments(employeeId);
        return ResponseEntity.ok(ApiResponse.success("Employee assignments retrieved successfully", assignments));
    }

    @GetMapping("/{siteId}/employees")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<List<EmployeeSiteAssignmentResponse>>> getSiteEmployees(
            @PathVariable Long siteId) {
        List<EmployeeSiteAssignmentResponse> assignments = siteService.getSiteEmployees(siteId);
        return ResponseEntity.ok(ApiResponse.success("Site employees retrieved successfully", assignments));
    }

    @GetMapping("/my-sites")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<List<SiteResponse>>> getMyAssignedSites() {
        // Get employee ID from authenticated user
        Long userId = com.civiltech.civildesk_backend.security.SecurityUtils.getCurrentUserId();
        
        // Find employee by user ID and get their assigned sites
        // For now, return empty list - would need to implement proper lookup
        List<SiteResponse> sites = java.util.Collections.emptyList();
        return ResponseEntity.ok(ApiResponse.success("Assigned sites retrieved successfully", sites));
    }
}


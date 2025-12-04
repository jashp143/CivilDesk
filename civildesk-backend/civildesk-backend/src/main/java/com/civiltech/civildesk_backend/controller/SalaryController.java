package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.SalaryCalculationRequest;
import com.civiltech.civildesk_backend.dto.SalaryCalculationResponse;
import com.civiltech.civildesk_backend.dto.SalarySlipResponse;
import com.civiltech.civildesk_backend.model.SalarySlip;
import com.civiltech.civildesk_backend.service.SalaryService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/salary")
@CrossOrigin(origins = "*")
public class SalaryController {

    @Autowired
    private SalaryService salaryService;

    @PostMapping("/calculate")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<SalaryCalculationResponse>> calculateAndGenerateSlip(
            @Valid @RequestBody SalaryCalculationRequest request) {
        SalaryCalculationResponse response = salaryService.calculateAndGenerateSlip(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Salary slip calculated and generated successfully", response));
    }

    @GetMapping("/slip/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<SalarySlipResponse>> getSalarySlipById(@PathVariable Long id) {
        SalarySlipResponse response = salaryService.getSalarySlipById(id);
        return ResponseEntity.ok(ApiResponse.success("Salary slip retrieved successfully", response));
    }

    @GetMapping("/employee/{employeeId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<SalarySlipResponse>>> getEmployeeSalarySlips(
            @PathVariable String employeeId) {
        List<SalarySlipResponse> response = salaryService.getEmployeeSalarySlips(employeeId);
        return ResponseEntity.ok(ApiResponse.success("Employee salary slips retrieved successfully", response));
    }

    @GetMapping("/employee/{employeeId}/period")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<SalarySlipResponse>> getSalarySlipByPeriod(
            @PathVariable String employeeId,
            @RequestParam Integer year,
            @RequestParam Integer month) {
        SalarySlipResponse response = salaryService.getSalarySlipByEmployeeAndPeriod(employeeId, year, month);
        return ResponseEntity.ok(ApiResponse.success("Salary slip retrieved successfully", response));
    }

    @GetMapping("/my-salary-slips")
    @PreAuthorize("hasRole('EMPLOYEE')")
    public ResponseEntity<ApiResponse<List<SalarySlipResponse>>> getMySalarySlips(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) String status) {
        try {
            // Get employee ID from authenticated user
            Long userId = com.civiltech.civildesk_backend.security.SecurityUtils.getCurrentUserId();
            
            // Find employee by user ID
            com.civiltech.civildesk_backend.model.Employee employee = 
                salaryService.getEmployeeByUserId(userId);
            
            if (employee == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Employee record not found for current user"));
            }
            
            List<SalarySlipResponse> responses = salaryService.getMySalarySlips(
                    employee.getEmployeeId(), year, month, status);
            return ResponseEntity.ok(
                    ApiResponse.success("Salary slips retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving salary slips: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<List<SalarySlipResponse>>> getAllSalarySlips(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        List<SalarySlipResponse> response = salaryService.getAllSalarySlips(year, month);
        return ResponseEntity.ok(ApiResponse.success("Salary slips retrieved successfully", response));
    }

    @PutMapping("/slip/{id}/finalize")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<SalarySlipResponse>> finalizeSalarySlip(@PathVariable Long id) {
        SalarySlipResponse response = salaryService.finalizeSalarySlip(id);
        return ResponseEntity.ok(ApiResponse.success("Salary slip finalized successfully", response));
    }

    @PutMapping("/slip/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<SalarySlipResponse>> updateSalarySlipStatus(
            @PathVariable Long id,
            @RequestParam String status) {
        SalarySlip.SalarySlipStatus slipStatus = SalarySlip.SalarySlipStatus.valueOf(status.toUpperCase());
        SalarySlipResponse response = salaryService.updateSalarySlipStatus(id, slipStatus);
        return ResponseEntity.ok(ApiResponse.success("Salary slip status updated successfully", response));
    }

    @DeleteMapping("/slip/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Void>> deleteSalarySlip(@PathVariable Long id) {
        salaryService.deleteSalarySlip(id);
        return ResponseEntity.ok(ApiResponse.success("Salary slip deleted successfully", null));
    }
}


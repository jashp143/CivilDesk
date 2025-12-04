package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SalarySlipResponse {
    
    private Long id;
    private String employeeId;
    private String employeeName;
    private String department;
    private String designation;
    private Integer year;
    private Integer month;
    private String periodString;
    
    // Calendar & Working Days
    private Integer totalDaysInMonth;
    private Integer workingDays;
    private Integer weeklyOffs;
    
    // Attendance Data
    private Double totalEffectiveWorkingHours;
    private Double totalOvertimeHours;
    private Double rawPresentDays;
    private Integer presentDays;
    private Integer absentDays;
    private Double prorationFactor;
    
    // Earnings
    private Double basicPay;
    private Double hraAmount;
    private Double medicalAllowance;
    private Double conveyanceAllowance;
    private Double uniformAndSafetyAllowance;
    private Double bonus;
    private Double foodAllowance;
    private Double specialAllowance;
    private Double overtimePay;
    private Double totalSpecialAllowance;
    private Double otherIncentive;
    private Double epfEmployerEarnings;
    private Double totalEarnings;
    
    // Deductions
    private Double epfEmployeeDeduction;
    private Double epfEmployerDeduction;
    private Double esicDeduction;
    private Double professionalTax;
    private Double tds;
    private Double advanceSalaryRecovery;
    private Double loanRecovery;
    private Double fuelAdvanceRecovery;
    private Double otherDeductions;
    private Double totalStatutoryDeductions;
    private Double totalOtherDeductions;
    private Double totalDeductions;
    
    // Net Salary
    private Double netSalary;
    
    // Rates
    private Double dailyRate;
    private Double hourlyRate;
    private Double overtimeRate;
    
    // Status
    private String status;
    private Long generatedBy;
    private LocalDateTime generatedAt;
    private String notes;
    
    // Metadata
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}


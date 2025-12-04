package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SalaryCalculationResponse {
    
    private SalarySlipResponse salarySlip;
    private CalculationBreakdown breakdown;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CalculationBreakdown {
        // Calendar calculation
        private Integer totalDaysInMonth;
        private Integer workingDays;
        private Integer weeklyOffs;
        
        // Attendance calculation
        private Double totalEffectiveWorkingHours;
        private Double totalOvertimeHours;
        private Double rawPresentDays;
        private Integer presentDays;
        private Integer absentDays;
        private Double prorationFactor;
        
        // Earnings breakdown
        private EarningsBreakdown earnings;
        
        // Deductions breakdown
        private DeductionsBreakdown deductions;
        
        // Rates
        private Double dailyRate;
        private Double hourlyRate;
        private Double overtimeRate;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EarningsBreakdown {
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
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DeductionsBreakdown {
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
    }
}


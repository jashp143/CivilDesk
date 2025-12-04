package com.civiltech.civildesk_backend.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SalaryCalculationRequest {
    
    @NotNull(message = "Employee ID is required")
    private String employeeId;
    
    @NotNull(message = "Year is required")
    @Min(value = 2020, message = "Year must be between 2020 and 2030")
    @Max(value = 2030, message = "Year must be between 2020 and 2030")
    private Integer year;
    
    @NotNull(message = "Month is required")
    @Min(value = 1, message = "Month must be between 1 and 12")
    @Max(value = 12, message = "Month must be between 1 and 12")
    private Integer month;
    
    // Optional deductions (can be entered at slip generation)
    private Double tds = 0.0;
    private Double advanceSalaryRecovery = 0.0;
    private Double loanRecovery = 0.0;
    private Double fuelAdvanceRecovery = 0.0;
    private Double otherDeductions = 0.0;
    
    // Optional: Other Incentive (if different from employee record)
    private Double otherIncentive;
    
    private String notes;
}


package com.civiltech.civildesk_backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.YearMonth;

@Entity
@Table(name = "salary_slips")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class SalarySlip extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    @Column(name = "year", nullable = false)
    private Integer year;

    @Column(name = "month", nullable = false)
    private Integer month; // 1-12

    // Calendar & Working Days
    @Column(name = "total_days_in_month")
    private Integer totalDaysInMonth;

    @Column(name = "working_days")
    private Integer workingDays; // Monday to Saturday

    @Column(name = "weekly_offs")
    private Integer weeklyOffs; // Sundays

    // Attendance Data
    @Column(name = "total_effective_working_hours")
    private Double totalEffectiveWorkingHours;

    @Column(name = "total_overtime_hours")
    private Double totalOvertimeHours;

    @Column(name = "raw_present_days")
    private Double rawPresentDays;

    @Column(name = "present_days")
    private Integer presentDays;

    @Column(name = "absent_days")
    private Integer absentDays;

    @Column(name = "proration_factor")
    private Double prorationFactor;

    // Earnings (Prorated)
    @Column(name = "basic_pay")
    private Double basicPay;

    @Column(name = "hra_amount")
    private Double hraAmount;

    @Column(name = "medical_allowance")
    private Double medicalAllowance;

    @Column(name = "conveyance_allowance")
    private Double conveyanceAllowance;

    @Column(name = "uniform_and_safety_allowance")
    private Double uniformAndSafetyAllowance;

    @Column(name = "bonus")
    private Double bonus;

    @Column(name = "food_allowance")
    private Double foodAllowance;

    @Column(name = "special_allowance")
    private Double specialAllowance; // Prorated special allowance

    @Column(name = "overtime_pay")
    private Double overtimePay;

    @Column(name = "total_special_allowance")
    private Double totalSpecialAllowance; // Special Allowance + Overtime Pay

    @Column(name = "other_incentive")
    private Double otherIncentive; // NOT prorated

    @Column(name = "epf_employer_earnings")
    private Double epfEmployerEarnings;

    @Column(name = "total_earnings")
    private Double totalEarnings;

    // Deductions
    @Column(name = "epf_employee_deduction")
    private Double epfEmployeeDeduction;

    @Column(name = "epf_employer_deduction")
    private Double epfEmployerDeduction;

    @Column(name = "esic_deduction")
    private Double esicDeduction;

    @Column(name = "professional_tax")
    private Double professionalTax;

    @Column(name = "tds")
    private Double tds;

    @Column(name = "advance_salary_recovery")
    private Double advanceSalaryRecovery;

    @Column(name = "loan_recovery")
    private Double loanRecovery;

    @Column(name = "fuel_advance_recovery")
    private Double fuelAdvanceRecovery;

    @Column(name = "other_deductions")
    private Double otherDeductions;

    @Column(name = "total_statutory_deductions")
    private Double totalStatutoryDeductions;

    @Column(name = "total_other_deductions")
    private Double totalOtherDeductions;

    @Column(name = "total_deductions")
    private Double totalDeductions;

    // Net Salary
    @Column(name = "net_salary")
    private Double netSalary;

    // Rates
    @Column(name = "daily_rate")
    private Double dailyRate;

    @Column(name = "hourly_rate")
    private Double hourlyRate;

    @Column(name = "overtime_rate")
    private Double overtimeRate;

    // Status
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private SalarySlipStatus status = SalarySlipStatus.DRAFT;

    @Column(name = "generated_by")
    private Long generatedBy; // User ID who generated the slip

    @Column(name = "generated_at")
    private java.time.LocalDateTime generatedAt;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    public enum SalarySlipStatus {
        DRAFT, FINALIZED, PAID, CANCELLED
    }

    // Helper method to get YearMonth
    public YearMonth getYearMonth() {
        return YearMonth.of(year, month);
    }

    // Helper method to get period string
    public String getPeriodString() {
        return String.format("%s %d", getMonthName(), year);
    }

    private String getMonthName() {
        String[] monthNames = {"", "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"};
        return monthNames[month];
    }
}


package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.SalaryCalculationRequest;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.model.Attendance;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.SalarySlip;
import com.civiltech.civildesk_backend.repository.AttendanceRepository;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

/**
 * Service for calculating salary based on attendance and employee salary structure.
 * Implements detailed salary calculation logic as per specifications.
 */
@Service
public class SalaryCalculationService {

    // Configuration constants
    private static final double HOURS_PER_DAY = 8.0;
    private static final double EPF_THRESHOLD = 15000.0;
    private static final double FIXED_EPF_EMPLOYEE_ABOVE_THRESHOLD = 1800.0;
    private static final double FIXED_EPF_EMPLOYER_ABOVE_THRESHOLD = 1950.0;
    private static final int MIN_WORKING_DAYS = 1; // To prevent division by zero

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    /**
     * Calculate salary for an employee for a given month.
     */
    @Transactional
    public SalarySlip calculateSalary(SalaryCalculationRequest request, Long generatedByUserId) {
        // Step 1: Validate and get employee
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(request.getEmployeeId())
                .orElseThrow(() -> new BadRequestException("Employee not found with ID: " + request.getEmployeeId()));

        validateEmployeeSalaryStructure(employee);

        // Step 2: Calculate calendar and working days
        YearMonth yearMonth = YearMonth.of(request.getYear(), request.getMonth());
        CalendarCalculation calendarCalc = calculateCalendar(yearMonth);

        // Step 3: Calculate attendance data
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();
        AttendanceCalculation attendanceCalc = calculateAttendance(employee, startDate, endDate);

        // Validate attendance
        if (attendanceCalc.presentDays > calendarCalc.workingDays) {
            throw new BadRequestException(
                    String.format("Present days (%d) cannot exceed working days (%d)",
                            attendanceCalc.presentDays, calendarCalc.workingDays));
        }

        // Step 4: Calculate proration factor
        double prorationFactor = calculateProrationFactor(attendanceCalc.presentDays, calendarCalc.workingDays);

        // Step 5: Calculate earnings
        EarningsCalculation earningsCalc = calculateEarnings(employee, prorationFactor, attendanceCalc.totalOvertimeHours);

        // Step 6: Calculate deductions
        DeductionsCalculation deductionsCalc = calculateDeductions(
                employee, prorationFactor, earningsCalc.basicPay, request);

        // Step 7: Calculate net salary
        double netSalary = Math.round(earningsCalc.totalEarnings - deductionsCalc.totalDeductions);

        // Step 8: Calculate rates
        RatesCalculation ratesCalc = calculateRates(employee, calendarCalc.workingDays);

        // Step 9: Create and save salary slip
        SalarySlip salarySlip = new SalarySlip();
        salarySlip.setEmployee(employee);
        salarySlip.setYear(request.getYear());
        salarySlip.setMonth(request.getMonth());
        salarySlip.setTotalDaysInMonth(calendarCalc.totalDaysInMonth);
        salarySlip.setWorkingDays(calendarCalc.workingDays);
        salarySlip.setWeeklyOffs(calendarCalc.weeklyOffs);
        salarySlip.setTotalEffectiveWorkingHours(attendanceCalc.totalEffectiveWorkingHours);
        salarySlip.setTotalOvertimeHours(attendanceCalc.totalOvertimeHours);
        salarySlip.setRawPresentDays(attendanceCalc.rawPresentDays);
        salarySlip.setPresentDays(attendanceCalc.presentDays);
        salarySlip.setAbsentDays(attendanceCalc.absentDays);
        salarySlip.setProrationFactor(prorationFactor);
        salarySlip.setBasicPay(earningsCalc.basicPay);
        salarySlip.setHraAmount(earningsCalc.hraAmount);
        salarySlip.setMedicalAllowance(earningsCalc.medicalAllowance);
        salarySlip.setConveyanceAllowance(earningsCalc.conveyanceAllowance);
        salarySlip.setUniformAndSafetyAllowance(earningsCalc.uniformAndSafetyAllowance);
        salarySlip.setBonus(earningsCalc.bonus);
        salarySlip.setFoodAllowance(earningsCalc.foodAllowance);
        salarySlip.setSpecialAllowance(earningsCalc.specialAllowance);
        salarySlip.setOvertimePay(earningsCalc.overtimePay);
        salarySlip.setTotalSpecialAllowance(earningsCalc.totalSpecialAllowance);
        salarySlip.setOtherIncentive(earningsCalc.otherIncentive);
        salarySlip.setEpfEmployerEarnings(earningsCalc.epfEmployerEarnings);
        salarySlip.setTotalEarnings(earningsCalc.totalEarnings);
        salarySlip.setEpfEmployeeDeduction(deductionsCalc.epfEmployeeDeduction);
        salarySlip.setEpfEmployerDeduction(deductionsCalc.epfEmployerDeduction);
        salarySlip.setEsicDeduction(deductionsCalc.esicDeduction);
        salarySlip.setProfessionalTax(deductionsCalc.professionalTax);
        salarySlip.setTds(request.getTds() != null ? request.getTds() : 0.0);
        salarySlip.setAdvanceSalaryRecovery(request.getAdvanceSalaryRecovery() != null ? request.getAdvanceSalaryRecovery() : 0.0);
        salarySlip.setLoanRecovery(request.getLoanRecovery() != null ? request.getLoanRecovery() : 0.0);
        salarySlip.setFuelAdvanceRecovery(request.getFuelAdvanceRecovery() != null ? request.getFuelAdvanceRecovery() : 0.0);
        salarySlip.setOtherDeductions(request.getOtherDeductions() != null ? request.getOtherDeductions() : 0.0);
        salarySlip.setTotalStatutoryDeductions(deductionsCalc.totalStatutoryDeductions);
        salarySlip.setTotalOtherDeductions(deductionsCalc.totalOtherDeductions);
        salarySlip.setTotalDeductions(deductionsCalc.totalDeductions);
        salarySlip.setNetSalary(netSalary);
        salarySlip.setDailyRate(ratesCalc.dailyRate);
        salarySlip.setHourlyRate(ratesCalc.hourlyRate);
        salarySlip.setOvertimeRate(employee.getOvertimeRate() != null ? employee.getOvertimeRate() : 0.0);
        salarySlip.setStatus(SalarySlip.SalarySlipStatus.DRAFT);
        salarySlip.setGeneratedBy(generatedByUserId);
        salarySlip.setGeneratedAt(java.time.LocalDateTime.now());
        salarySlip.setNotes(request.getNotes());
        salarySlip.setDeleted(false);

        // Validate calculated values
        validateSalarySlip(salarySlip);

        return salarySlip;
    }

    /**
     * STEP 1: Calculate calendar and working days
     */
    private CalendarCalculation calculateCalendar(YearMonth yearMonth) {
        int totalDays = yearMonth.lengthOfMonth();
        int workingDays = 0;
        int weeklyOffs = 0;

        LocalDate firstDay = yearMonth.atDay(1);
        LocalDate lastDay = yearMonth.atEndOfMonth();

        LocalDate currentDate = firstDay;
        while (!currentDate.isAfter(lastDay)) {
            DayOfWeek dayOfWeek = currentDate.getDayOfWeek();
            if (dayOfWeek == DayOfWeek.SUNDAY) {
                weeklyOffs++;
            } else {
                // Monday to Saturday are working days
                workingDays++;
            }
            currentDate = currentDate.plusDays(1);
        }

        // Ensure minimum working days
        if (workingDays < MIN_WORKING_DAYS) {
            workingDays = MIN_WORKING_DAYS;
        }

        return new CalendarCalculation(totalDays, workingDays, weeklyOffs);
    }

    /**
     * STEP 2: Calculate attendance data
     */
    private AttendanceCalculation calculateAttendance(Employee employee, LocalDate startDate, LocalDate endDate) {
        List<Attendance> attendances = attendanceRepository.findByEmployeeIdAndDateBetween(
                employee.getId(), startDate, endDate);

        double totalEffectiveWorkingHours = 0.0;
        double totalOvertimeHours = 0.0;

        for (Attendance attendance : attendances) {
            if (attendance.getWorkingHours() != null) {
                totalEffectiveWorkingHours += attendance.getWorkingHours();
            }
            if (attendance.getOvertimeHours() != null) {
                totalOvertimeHours += attendance.getOvertimeHours();
            }
        }

        // Calculate raw present days
        double rawPresentDays = totalEffectiveWorkingHours / HOURS_PER_DAY;

        // Round present days (using standard rounding)
        int presentDays = (int) Math.round(rawPresentDays);

        // Calculate working days for the period
        int workingDays = calculateWorkingDaysInPeriod(startDate, endDate);
        int absentDays = Math.max(0, workingDays - presentDays);

        return new AttendanceCalculation(
                totalEffectiveWorkingHours,
                totalOvertimeHours,
                rawPresentDays,
                presentDays,
                absentDays
        );
    }

    /**
     * Calculate working days in a period (Monday to Saturday)
     */
    private int calculateWorkingDaysInPeriod(LocalDate startDate, LocalDate endDate) {
        int workingDays = 0;
        LocalDate currentDate = startDate;

        while (!currentDate.isAfter(endDate)) {
            DayOfWeek dayOfWeek = currentDate.getDayOfWeek();
            if (dayOfWeek != DayOfWeek.SUNDAY) {
                workingDays++;
            }
            currentDate = currentDate.plusDays(1);
        }

        return Math.max(workingDays, MIN_WORKING_DAYS);
    }

    /**
     * STEP 3: Calculate proration factor
     */
    private double calculateProrationFactor(int presentDays, int workingDays) {
        if (workingDays == 0) {
            return 0.0;
        }
        return (double) presentDays / (double) workingDays;
    }

    /**
     * STEP 4: Calculate earnings
     */
    private EarningsCalculation calculateEarnings(Employee employee, double prorationFactor, double totalOvertimeHours) {
        double basicSalary = employee.getBasicSalary() != null ? employee.getBasicSalary() : 0.0;
        double hraAmount = employee.getHouseRentAllowance() != null ? employee.getHouseRentAllowance() : 0.0;
        double conveyance = employee.getConveyance() != null ? employee.getConveyance() : 0.0;
        double uniformAndSafety = employee.getUniformAndSafety() != null ? employee.getUniformAndSafety() : 0.0;
        double bonus = employee.getBonus() != null ? employee.getBonus() : 0.0;
        double foodAllowance = employee.getFoodAllowance() != null ? employee.getFoodAllowance() : 0.0;
        double otherAllowance = employee.getOtherAllowance() != null ? employee.getOtherAllowance() : 0.0;
        double overtimeRate = employee.getOvertimeRate() != null ? employee.getOvertimeRate() : 0.0;

        // Fixed salary components (prorated)
        double basicPay = basicSalary * prorationFactor;
        double hraAmountProrated = hraAmount * prorationFactor;
        double medicalAllowance = 0.0; // Not in employee model, set to 0
        double conveyanceAllowance = conveyance * prorationFactor;
        double uniformAndSafetyAllowance = uniformAndSafety * prorationFactor;
        double bonusProrated = bonus * prorationFactor;
        double foodAllowanceProrated = foodAllowance * prorationFactor;

        // Special Allowance (prorated)
        double specialAllowanceProrated = otherAllowance * prorationFactor;

        // Overtime Pay
        double overtimePay = totalOvertimeHours * overtimeRate;

        // Total Special Allowance = Prorated Special Allowance + Overtime Pay
        double totalSpecialAllowance = specialAllowanceProrated + overtimePay;

        // Other Incentive (NOT prorated)
        double otherIncentive = otherAllowance; // Using otherAllowance as other incentive

        // EPF Calculation (For Earnings Section)
        double epfEmployerEarnings;
        double proratedBasicSalary = basicPay;
        
        if (proratedBasicSalary > EPF_THRESHOLD) {
            // Above threshold: Fixed amount (NOT prorated)
            epfEmployerEarnings = FIXED_EPF_EMPLOYER_ABOVE_THRESHOLD;
        } else {
            // Below threshold: Percentage of prorated basic salary
            double epfEmployerPercentage = employee.getEpfEmployer() != null ? employee.getEpfEmployer() : 0.0;
            epfEmployerEarnings = proratedBasicSalary * (epfEmployerPercentage / 100.0);
        }

        // Total Earnings
        double totalEarnings = basicPay
                + hraAmountProrated
                + medicalAllowance
                + conveyanceAllowance
                + uniformAndSafetyAllowance
                + bonusProrated
                + foodAllowanceProrated
                + totalSpecialAllowance
                + otherIncentive
                + epfEmployerEarnings;

        return new EarningsCalculation(
                basicPay,
                hraAmountProrated,
                medicalAllowance,
                conveyanceAllowance,
                uniformAndSafetyAllowance,
                bonusProrated,
                foodAllowanceProrated,
                specialAllowanceProrated,
                overtimePay,
                totalSpecialAllowance,
                otherIncentive,
                epfEmployerEarnings,
                totalEarnings
        );
    }

    /**
     * STEP 5: Calculate deductions
     */
    private DeductionsCalculation calculateDeductions(
            Employee employee, double prorationFactor, double proratedBasicSalary, SalaryCalculationRequest request) {
        
        double epfEmployeeDeduction = 0.0;
        double epfEmployerDeduction = 0.0;
        double esicDeduction = 0.0;
        double professionalTax = employee.getProfessionalTax() != null ? employee.getProfessionalTax() : 0.0;

        // EPF Calculation (only if employee has UAN)
        boolean hasUAN = employee.getUanNumber() != null && !employee.getUanNumber().trim().isEmpty();
        
        if (hasUAN) {
            if (proratedBasicSalary > EPF_THRESHOLD) {
                // Above threshold: Fixed amounts (NOT prorated)
                epfEmployeeDeduction = FIXED_EPF_EMPLOYEE_ABOVE_THRESHOLD;
                epfEmployerDeduction = FIXED_EPF_EMPLOYER_ABOVE_THRESHOLD;
            } else {
                // Below threshold: Percentage of prorated basic salary
                double epfEmployeePercentage = employee.getEpfEmployee() != null ? employee.getEpfEmployee() : 0.0;
                double epfEmployerPercentage = employee.getEpfEmployer() != null ? employee.getEpfEmployer() : 0.0;
                epfEmployeeDeduction = proratedBasicSalary * (epfEmployeePercentage / 100.0);
                epfEmployerDeduction = proratedBasicSalary * (epfEmployerPercentage / 100.0);
            }
        }

        // ESIC Calculation (only if employee has ESIC number)
        boolean hasESIC = employee.getEsicNumber() != null && !employee.getEsicNumber().trim().isEmpty();
        
        if (hasESIC) {
            double esicRate = employee.getEsic() != null ? employee.getEsic() : 0.0;
            esicDeduction = proratedBasicSalary * (esicRate / 100.0);
        }

        // Other deductions from request
        double tds = request.getTds() != null ? request.getTds() : 0.0;
        double advanceSalaryRecovery = request.getAdvanceSalaryRecovery() != null ? request.getAdvanceSalaryRecovery() : 0.0;
        double loanRecovery = request.getLoanRecovery() != null ? request.getLoanRecovery() : 0.0;
        double fuelAdvanceRecovery = request.getFuelAdvanceRecovery() != null ? request.getFuelAdvanceRecovery() : 0.0;
        double otherDeductions = request.getOtherDeductions() != null ? request.getOtherDeductions() : 0.0;

        // Total Statutory Deductions
        double totalStatutoryDeductions = epfEmployeeDeduction
                + epfEmployerDeduction
                + esicDeduction
                + professionalTax;

        // Total Other Deductions
        double totalOtherDeductions = tds
                + advanceSalaryRecovery
                + loanRecovery
                + fuelAdvanceRecovery
                + otherDeductions;

        // Total Deductions
        double totalDeductions = totalStatutoryDeductions + totalOtherDeductions;

        return new DeductionsCalculation(
                epfEmployeeDeduction,
                epfEmployerDeduction,
                esicDeduction,
                professionalTax,
                tds,
                advanceSalaryRecovery,
                loanRecovery,
                fuelAdvanceRecovery,
                otherDeductions,
                totalStatutoryDeductions,
                totalOtherDeductions,
                totalDeductions
        );
    }

    /**
     * STEP 6: Calculate rates
     */
    private RatesCalculation calculateRates(Employee employee, int workingDays) {
        double basicSalary = employee.getBasicSalary() != null ? employee.getBasicSalary() : 0.0;
        double dailyRate = workingDays > 0 ? basicSalary / workingDays : 0.0;
        double hourlyRate = dailyRate / HOURS_PER_DAY;
        double overtimeRate = employee.getOvertimeRate() != null ? employee.getOvertimeRate() : 0.0;

        return new RatesCalculation(dailyRate, hourlyRate, overtimeRate);
    }

    /**
     * Validate employee salary structure
     */
    private void validateEmployeeSalaryStructure(Employee employee) {
        double basicSalary = employee.getBasicSalary() != null ? employee.getBasicSalary() : 0.0;
        
        if (basicSalary <= 0 || basicSalary > 1000000) {
            throw new BadRequestException("Basic salary must be > 0 and ≤ ₹10,00,000");
        }

        boolean hasUAN = employee.getUanNumber() != null && !employee.getUanNumber().trim().isEmpty();
        if (hasUAN) {
            double epfRate = employee.getEpfEmployee() != null ? employee.getEpfEmployee() : 0.0;
            if (epfRate < 0 || epfRate > 15) {
                throw new BadRequestException("EPF rate must be between 0% and 15%");
            }
        }

        boolean hasESIC = employee.getEsicNumber() != null && !employee.getEsicNumber().trim().isEmpty();
        if (hasESIC) {
            double esicRate = employee.getEsic() != null ? employee.getEsic() : 0.0;
            if (esicRate < 0 || esicRate > 5) {
                throw new BadRequestException("ESIC rate must be between 0% and 5%");
            }
        }

        double overtimeRate = employee.getOvertimeRate() != null ? employee.getOvertimeRate() : 0.0;
        if (overtimeRate < 1.0) {
            throw new BadRequestException("Overtime multiplier must be ≥ 1.0");
        }
    }

    /**
     * Validate salary slip
     */
    private void validateSalarySlip(SalarySlip salarySlip) {
        if (salarySlip.getNetSalary() < 0) {
            throw new BadRequestException("Net salary cannot be negative");
        }

        if (salarySlip.getTotalEarnings() <= 0) {
            throw new BadRequestException("Total earnings must be > 0");
        }

        if (salarySlip.getTotalEarnings() > 500000) {
            throw new BadRequestException("Total earnings cannot exceed ₹5,00,000");
        }

        if (salarySlip.getNetSalary() > 400000) {
            throw new BadRequestException("Net salary cannot exceed ₹4,00,000");
        }

        if (salarySlip.getBasicPay() > 200000) {
            throw new BadRequestException("Basic pay cannot exceed ₹2,00,000");
        }

        if (salarySlip.getEpfEmployeeDeduction() != null && salarySlip.getEpfEmployeeDeduction() > 50000) {
            throw new BadRequestException("EPF Employee deduction cannot exceed ₹50,000");
        }
    }

    // Inner classes for calculation results
    private static class CalendarCalculation {
        final int totalDaysInMonth;
        final int workingDays;
        final int weeklyOffs;

        CalendarCalculation(int totalDaysInMonth, int workingDays, int weeklyOffs) {
            this.totalDaysInMonth = totalDaysInMonth;
            this.workingDays = workingDays;
            this.weeklyOffs = weeklyOffs;
        }
    }

    private static class AttendanceCalculation {
        final double totalEffectiveWorkingHours;
        final double totalOvertimeHours;
        final double rawPresentDays;
        final int presentDays;
        final int absentDays;

        AttendanceCalculation(double totalEffectiveWorkingHours, double totalOvertimeHours,
                              double rawPresentDays, int presentDays, int absentDays) {
            this.totalEffectiveWorkingHours = totalEffectiveWorkingHours;
            this.totalOvertimeHours = totalOvertimeHours;
            this.rawPresentDays = rawPresentDays;
            this.presentDays = presentDays;
            this.absentDays = absentDays;
        }
    }

    private static class EarningsCalculation {
        final double basicPay;
        final double hraAmount;
        final double medicalAllowance;
        final double conveyanceAllowance;
        final double uniformAndSafetyAllowance;
        final double bonus;
        final double foodAllowance;
        final double specialAllowance;
        final double overtimePay;
        final double totalSpecialAllowance;
        final double otherIncentive;
        final double epfEmployerEarnings;
        final double totalEarnings;

        EarningsCalculation(double basicPay, double hraAmount, double medicalAllowance,
                           double conveyanceAllowance, double uniformAndSafetyAllowance,
                           double bonus, double foodAllowance, double specialAllowance,
                           double overtimePay, double totalSpecialAllowance,
                           double otherIncentive, double epfEmployerEarnings, double totalEarnings) {
            this.basicPay = basicPay;
            this.hraAmount = hraAmount;
            this.medicalAllowance = medicalAllowance;
            this.conveyanceAllowance = conveyanceAllowance;
            this.uniformAndSafetyAllowance = uniformAndSafetyAllowance;
            this.bonus = bonus;
            this.foodAllowance = foodAllowance;
            this.specialAllowance = specialAllowance;
            this.overtimePay = overtimePay;
            this.totalSpecialAllowance = totalSpecialAllowance;
            this.otherIncentive = otherIncentive;
            this.epfEmployerEarnings = epfEmployerEarnings;
            this.totalEarnings = totalEarnings;
        }
    }

    private static class DeductionsCalculation {
        final double epfEmployeeDeduction;
        final double epfEmployerDeduction;
        final double esicDeduction;
        final double professionalTax;
        final double tds;
        final double advanceSalaryRecovery;
        final double loanRecovery;
        final double fuelAdvanceRecovery;
        final double otherDeductions;
        final double totalStatutoryDeductions;
        final double totalOtherDeductions;
        final double totalDeductions;

        DeductionsCalculation(double epfEmployeeDeduction, double epfEmployerDeduction,
                             double esicDeduction, double professionalTax, double tds,
                             double advanceSalaryRecovery, double loanRecovery,
                             double fuelAdvanceRecovery, double otherDeductions,
                             double totalStatutoryDeductions, double totalOtherDeductions,
                             double totalDeductions) {
            this.epfEmployeeDeduction = epfEmployeeDeduction;
            this.epfEmployerDeduction = epfEmployerDeduction;
            this.esicDeduction = esicDeduction;
            this.professionalTax = professionalTax;
            this.tds = tds;
            this.advanceSalaryRecovery = advanceSalaryRecovery;
            this.loanRecovery = loanRecovery;
            this.fuelAdvanceRecovery = fuelAdvanceRecovery;
            this.otherDeductions = otherDeductions;
            this.totalStatutoryDeductions = totalStatutoryDeductions;
            this.totalOtherDeductions = totalOtherDeductions;
            this.totalDeductions = totalDeductions;
        }
    }

    private static class RatesCalculation {
        final double dailyRate;
        final double hourlyRate;
        final double overtimeRate;

        RatesCalculation(double dailyRate, double hourlyRate, double overtimeRate) {
            this.dailyRate = dailyRate;
            this.hourlyRate = hourlyRate;
            this.overtimeRate = overtimeRate;
        }
    }
}


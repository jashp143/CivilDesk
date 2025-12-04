package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.model.Attendance;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Service for calculating attendance working hours and overtime based on business rules.
 */
@Service
public class AttendanceCalculationService {

    // Standard office hours
    private static final LocalTime OFFICE_START_TIME = LocalTime.of(9, 0);  // 09:00 AM
    private static final LocalTime OFFICE_END_TIME = LocalTime.of(18, 0);   // 18:00 PM
    private static final int STANDARD_WORKING_HOURS = 8; // 8 hours per day

    // Check-in time rules
    private static final LocalTime EARLY_CHECK_IN_START = LocalTime.of(0, 1);   // 00:01 AM
    private static final LocalTime EARLY_CHECK_IN_END = LocalTime.of(8, 0);    // 08:00 AM
    private static final LocalTime GRACE_PERIOD_START = LocalTime.of(8, 0);    // 08:00 AM
    private static final LocalTime GRACE_PERIOD_END = LocalTime.of(9, 15);      // 09:15 AM (inclusive)
    private static final LocalTime LATE_CHECK_IN_START = LocalTime.of(9, 16);   // 09:16 AM (after 9:15)

    // Check-out time rules
    private static final LocalTime CHECK_OUT_GRACE_START = LocalTime.of(18, 0); // 18:00 PM
    private static final LocalTime CHECK_OUT_GRACE_END = LocalTime.of(19, 0);    // 19:00 PM
    private static final LocalTime EVENING_OVERTIME_START = LocalTime.of(19, 0); // 19:00 PM (7:00 PM)

    // Lunch break rules
    private static final int MINIMUM_LUNCH_HOURS = 1; // 1 hour minimum
    private static final int STANDARD_LUNCH_HOURS = 1; // 1 hour standard

    /**
     * Calculate working hours and overtime for an attendance record.
     * 
     * @param attendance The attendance record to calculate
     * @return CalculationResult containing working hours and overtime in minutes
     */
    public CalculationResult calculateAttendance(Attendance attendance) {
        if (attendance.getCheckInTime() == null || attendance.getCheckOutTime() == null) {
            return new CalculationResult(0.0, 0.0);
        }

        LocalDate date = attendance.getDate();
        LocalDateTime checkIn = attendance.getCheckInTime();
        LocalDateTime checkOut = attendance.getCheckOutTime();
        LocalDateTime lunchOut = attendance.getLunchOutTime();
        LocalDateTime lunchIn = attendance.getLunchInTime();

        // Check if it's Sunday - all hours worked on Sunday are considered overtime
        // Monday to Saturday are working days, Sunday is non-working day
        DayOfWeek dayOfWeek = date.getDayOfWeek();
        boolean isSunday = dayOfWeek == DayOfWeek.SUNDAY;

        if (isSunday) {
            // For Sunday, all working hours are counted as overtime (Sunday is non-working day)
            double totalMinutes = Duration.between(checkIn, checkOut).toMinutes();
            return new CalculationResult(0.0, totalMinutes / 60.0);
        }

        // Normalize check-in time based on rules
        LocalDateTime normalizedCheckIn = normalizeCheckInTime(checkIn);
        
        // Normalize check-out time based on rules
        LocalDateTime normalizedCheckOut = normalizeCheckOutTime(checkOut);

        // Calculate lunch break duration (always 1 hour)
        double lunchBreakHours = calculateLunchBreak(lunchOut, lunchIn);
        
        // Calculate extra lunch time (beyond 1 hour) to be deducted
        double extraLunchTime = calculateExtraLunchTime(lunchOut, lunchIn);

        // Calculate morning overtime (00:01 - 08:00 AM)
        double morningOvertime = calculateMorningOvertime(checkIn, normalizedCheckIn);

        // Calculate evening overtime (after 19:00 PM)
        double eveningOvertime = calculateEveningOvertime(checkOut, normalizedCheckOut);

        // Calculate office working hours (always <= 8 hours)
        double officeWorkingHours = calculateOfficeWorkingHours(
            normalizedCheckIn, 
            normalizedCheckOut, 
            lunchBreakHours,
            extraLunchTime
        );

        // Total overtime
        double totalOvertime = morningOvertime + eveningOvertime;

        return new CalculationResult(officeWorkingHours, totalOvertime);
    }

    /**
     * Normalize check-in time based on rules:
     * - 08:00-09:15 AM (inclusive): treated as 09:00 AM (no late penalty)
     * - 00:01-08:00 AM: treat as 09:00 AM for working hours (overtime calculated separately)
     * - After 09:15 AM (09:16+): keep original (deduct minutes late)
     */
    private LocalDateTime normalizeCheckInTime(LocalDateTime checkIn) {
        LocalTime checkInTime = checkIn.toLocalTime();
        
        // If between 08:00-09:15 (inclusive), treat as 09:00
        if (!checkInTime.isBefore(GRACE_PERIOD_START) && 
            (checkInTime.isBefore(LATE_CHECK_IN_START) || checkInTime.equals(GRACE_PERIOD_END))) {
            return checkIn.toLocalDate().atTime(OFFICE_START_TIME);
        }
        
        // If after 09:15 (09:16+), keep original (late penalty will be applied)
        if (!checkInTime.isBefore(LATE_CHECK_IN_START)) {
            return checkIn;
        }
        
        // If between 00:01-08:00, treat as 09:00 for working hours calculation
        // (overtime from check-in to 08:00 is calculated separately)
        if (!checkInTime.isBefore(EARLY_CHECK_IN_START) && checkInTime.isBefore(EARLY_CHECK_IN_END)) {
            return checkIn.toLocalDate().atTime(OFFICE_START_TIME);
        }
        
        // Default: treat as 09:00
        return checkIn.toLocalDate().atTime(OFFICE_START_TIME);
    }

    /**
     * Normalize check-out time based on rules:
     * - 18:00-19:00: treated as 18:00
     * - Before 18:00: keep original (deduct minutes early)
     * - After 19:00: keep original (overtime)
     */
    private LocalDateTime normalizeCheckOutTime(LocalDateTime checkOut) {
        LocalTime checkOutTime = checkOut.toLocalTime();
        
        // If between 18:00-19:00, treat as 18:00
        if (!checkOutTime.isBefore(CHECK_OUT_GRACE_START) && checkOutTime.isBefore(CHECK_OUT_GRACE_END)) {
            return checkOut.toLocalDate().atTime(OFFICE_END_TIME);
        }
        
        // Otherwise, keep original
        return checkOut;
    }

    /**
     * Calculate lunch break duration:
     * - Window: 11:00 AM to 16:00 PM
     * - Minimum: 1 hour (if less, treat as 1 hour)
     * - Maximum: If more than 1 hour, deduct the extra time
     * - Compulsory: If no lunch-out/lunch-in recorded, deduct 1 hour automatically
     * 
     * Returns the lunch break hours to be deducted (always 1 hour, but extra time
     * will be handled in working hours calculation).
     */
    private double calculateLunchBreak(LocalDateTime lunchOut, LocalDateTime lunchIn) {
        // Always deduct 1 hour for lunch break
        // If no lunch break recorded, still deduct 1 hour (compulsory)
        // If lunch is more than 1 hour, extra time is handled separately
        return STANDARD_LUNCH_HOURS;
    }
    
    /**
     * Calculate extra lunch time (time beyond 1 hour) to be deducted from working hours.
     */
    private double calculateExtraLunchTime(LocalDateTime lunchOut, LocalDateTime lunchIn) {
        // If no lunch break recorded, no extra time
        if (lunchOut == null || lunchIn == null) {
            return 0.0;
        }

        // Calculate actual lunch duration
        long lunchMinutes = Duration.between(lunchOut, lunchIn).toMinutes();
        
        // If lunch is more than 1 hour, return the extra time
        if (lunchMinutes > MINIMUM_LUNCH_HOURS * 60) {
            return (lunchMinutes - (MINIMUM_LUNCH_HOURS * 60)) / 60.0;
        }
        
        return 0.0;
    }

    /**
     * Calculate morning overtime (work between 00:01-08:00 AM).
     */
    private double calculateMorningOvertime(LocalDateTime checkIn, LocalDateTime normalizedCheckIn) {
        LocalTime checkInTime = checkIn.toLocalTime();
        
        // If check-in is between 00:01-08:00, calculate overtime
        if (!checkInTime.isBefore(EARLY_CHECK_IN_START) && checkInTime.isBefore(EARLY_CHECK_IN_END)) {
            // Calculate overtime from check-in to 08:00
            LocalDateTime overtimeEnd = checkIn.toLocalDate().atTime(EARLY_CHECK_IN_END);
            long overtimeMinutes = Duration.between(checkIn, overtimeEnd).toMinutes();
            return Math.max(0, overtimeMinutes) / 60.0;
        }
        
        return 0.0;
    }

    /**
     * Calculate evening overtime (work after 19:00 PM).
     */
    private double calculateEveningOvertime(LocalDateTime checkOut, LocalDateTime normalizedCheckOut) {
        LocalTime checkOutTime = checkOut.toLocalTime();
        
        // If check-out is after 19:00, calculate overtime
        if (!checkOutTime.isBefore(EVENING_OVERTIME_START)) {
            // Calculate overtime from 19:00 to check-out
            LocalDateTime overtimeStart = checkOut.toLocalDate().atTime(EVENING_OVERTIME_START);
            long overtimeMinutes = Duration.between(overtimeStart, checkOut).toMinutes();
            return Math.max(0, overtimeMinutes) / 60.0;
        }
        
        return 0.0;
    }

    /**
     * Calculate office working hours (always <= 8 hours).
     * This accounts for:
     * - Late check-in (deduct minutes late)
     * - Early check-out (deduct minutes early)
     * - Lunch break (minimum 1 hour, extra time deducted)
     * 
     * The calculation uses standard office hours (9:00-18:00) as the base,
     * then applies penalties for late check-in and early check-out.
     */
    private double calculateOfficeWorkingHours(
            LocalDateTime normalizedCheckIn, 
            LocalDateTime normalizedCheckOut,
            double lunchBreakHours,
            double extraLunchTime) {
        
        // Start with standard office hours (9:00 to 18:00 = 9 hours)
        LocalDate date = normalizedCheckIn.toLocalDate();
        LocalDateTime standardStart = date.atTime(OFFICE_START_TIME); // 09:00
        LocalDateTime standardEnd = date.atTime(OFFICE_END_TIME);     // 18:00
        
        // Calculate total standard working time (excluding lunch)
        long standardMinutes = Duration.between(standardStart, standardEnd).toMinutes();
        double standardHours = standardMinutes / 60.0; // 9.0 hours
        
        // Subtract lunch break (1 hour)
        double workingHours = standardHours - lunchBreakHours; // 9.0 - 1.0 = 8.0 hours
        
        // Deduct extra lunch time (if lunch was more than 1 hour)
        workingHours -= extraLunchTime;
        
        // Apply late check-in penalty (if check-in is after 09:15)
        LocalTime checkInTime = normalizedCheckIn.toLocalTime();
        if (!checkInTime.isBefore(LATE_CHECK_IN_START)) {
            // Calculate minutes late (after 09:00)
            long minutesLate = Duration.between(
                standardStart,
                normalizedCheckIn
            ).toMinutes();
            workingHours -= minutesLate / 60.0;
        }
        
        // Apply early check-out penalty (if check-out is before 18:00)
        LocalTime checkOutTime = normalizedCheckOut.toLocalTime();
        if (checkOutTime.isBefore(OFFICE_END_TIME)) {
            // Calculate minutes early (before 18:00)
            long minutesEarly = Duration.between(
                normalizedCheckOut,
                standardEnd
            ).toMinutes();
            workingHours -= minutesEarly / 60.0;
        }
        
        // Ensure working hours don't exceed 8 hours
        workingHours = Math.min(workingHours, STANDARD_WORKING_HOURS);
        
        // Ensure working hours are not negative
        workingHours = Math.max(0.0, workingHours);
        
        return workingHours;
    }

    /**
     * Result class for attendance calculations.
     */
    public static class CalculationResult {
        private final double workingHours;
        private final double overtimeHours;

        public CalculationResult(double workingHours, double overtimeHours) {
            this.workingHours = workingHours;
            this.overtimeHours = overtimeHours;
        }

        public double getWorkingHours() {
            return workingHours;
        }

        public double getOvertimeHours() {
            return overtimeHours;
        }
    }
}


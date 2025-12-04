package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceAnalyticsResponse {
    
    // Employee information
    private String employeeId;
    private String employeeName;
    private String department;
    
    // Date range
    private LocalDate startDate;
    private LocalDate endDate;
    
    // Summary statistics
    private Double totalWorkingHours;
    private Double totalOvertimeHours;
    private Double attendancePercentage;
    private Integer totalDaysPresent;
    private Integer totalWorkingDays; // Total working days in the date range (excluding weekends)
    private Integer totalAbsentDays;
    private Integer totalLateDays;
    
    // Daily attendance logs
    private List<DailyAttendanceLog> dailyLogs;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyAttendanceLog {
        private Long attendanceId;
        private LocalDate date;
        private String dayOfWeek;
        private java.time.LocalDateTime checkInTime;
        private java.time.LocalDateTime lunchOutTime;
        private java.time.LocalDateTime lunchInTime;
        private java.time.LocalDateTime checkOutTime;
        private String status;
        private Double workingHours;
        private Double overtimeHours;
        private Boolean isLate; // If check-in is after 9:30 AM
        private String notes;
    }
}


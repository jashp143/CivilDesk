package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceResponse {
    private Long id;
    private String employeeId;
    private String employeeName;
    private LocalDate date;
    private LocalDateTime checkInTime;
    private LocalDateTime lunchOutTime;
    private LocalDateTime lunchInTime;
    private LocalDateTime checkOutTime;
    private String status;
    private String recognitionMethod;
    private Double faceRecognitionConfidence;
    private String notes;
    private Double workingHours; // Office working hours (always <= 8 hours)
    private Double overtimeHours; // Overtime hours
}


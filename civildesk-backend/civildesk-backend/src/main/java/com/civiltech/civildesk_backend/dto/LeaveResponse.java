package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Leave;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LeaveResponse {

    private Long id;
    private Long employeeId;
    private String employeeName;
    private String employeeEmail;
    private String employeeId_str;
    private String department;
    private String designation;
    private Leave.LeaveType leaveType;
    private String leaveTypeDisplay;
    private LocalDate startDate;
    private LocalDate endDate;
    private Boolean isHalfDay;
    private Leave.HalfDayPeriod halfDayPeriod;
    private String halfDayPeriodDisplay;
    private String contactNumber;
    private List<HandoverEmployeeInfo> handoverEmployees;
    private String reason;
    private String medicalCertificateUrl;
    private Leave.LeaveStatus status;
    private String statusDisplay;
    private Double totalDays;
    private ReviewerInfo reviewedBy;
    private LocalDateTime reviewedAt;
    private String reviewNote;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class HandoverEmployeeInfo {
        private Long id;
        private String name;
        private String employeeId;
        private String designation;
        private String email;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReviewerInfo {
        private Long id;
        private String name;
        private String email;
        private String role;
    }
}

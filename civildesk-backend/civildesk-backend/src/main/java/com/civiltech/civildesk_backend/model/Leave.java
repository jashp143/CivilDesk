package com.civiltech.civildesk_backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Entity
@Table(name = "leaves")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class Leave extends BaseEntity {

    // Employee who is applying for leave
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    @NotNull(message = "Employee is required")
    private Employee employee;

    // Leave Type
    @Enumerated(EnumType.STRING)
    @Column(name = "leave_type", nullable = false)
    @NotNull(message = "Leave type is required")
    private LeaveType leaveType;

    // Date Range
    @Column(name = "start_date", nullable = false)
    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    @NotNull(message = "End date is required")
    private LocalDate endDate;

    // Half Day Options
    @Column(name = "is_half_day", nullable = false)
    private Boolean isHalfDay = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "half_day_period")
    private HalfDayPeriod halfDayPeriod;

    // Contact Information
    @NotBlank(message = "Contact number is required")
    @Column(name = "contact_number", nullable = false, length = 15)
    private String contactNumber;

    // Hand over Responsibilities - Store employee IDs as comma-separated string
    @Column(name = "handover_employee_ids", columnDefinition = "TEXT")
    private String handoverEmployeeIds;

    // Reason for Leave
    @NotBlank(message = "Reason is required")
    @Column(name = "reason", nullable = false, columnDefinition = "TEXT")
    private String reason;

    // Medical Certificate URL (for medical leave)
    @Column(name = "medical_certificate_url")
    private String medicalCertificateUrl;

    // Leave Status
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private LeaveStatus status = LeaveStatus.PENDING;

    // Approval/Rejection Details
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    private User reviewedBy;

    @Column(name = "reviewed_at")
    private java.time.LocalDateTime reviewedAt;

    @Column(name = "review_note", columnDefinition = "TEXT")
    private String reviewNote;

    // Total number of days
    @Column(name = "total_days")
    private Double totalDays;

    // Enums
    public enum LeaveType {
        SICK_LEAVE("Sick Leave"),
        CASUAL_LEAVE("Casual Leave"),
        ANNUAL_LEAVE("Annual Leave"),
        MATERNITY_LEAVE("Maternity Leave"),
        PATERNITY_LEAVE("Paternity Leave"),
        MEDICAL_LEAVE("Medical Leave"),
        EMERGENCY_LEAVE("Emergency Leave"),
        UNPAID_LEAVE("Unpaid Leave"),
        COMPENSATORY_OFF("Compensatory Off");

        private final String displayName;

        LeaveType(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    public enum HalfDayPeriod {
        FIRST_HALF("First Half - Morning"),
        SECOND_HALF("Second Half - Afternoon");

        private final String displayName;

        HalfDayPeriod(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    public enum LeaveStatus {
        PENDING("Pending"),
        APPROVED("Approved"),
        REJECTED("Rejected"),
        CANCELLED("Cancelled");

        private final String displayName;

        LeaveStatus(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }
}

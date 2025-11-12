package com.civiltech.civildesk_backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "attendance", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"employee_id", "date"})
})
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class Attendance extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    @Column(name = "date", nullable = false)
    private java.time.LocalDate date;

    @Column(name = "check_in_time")
    private LocalDateTime checkInTime;

    @Column(name = "lunch_out_time")
    private LocalDateTime lunchOutTime;

    @Column(name = "lunch_in_time")
    private LocalDateTime lunchInTime;

    @Column(name = "check_out_time")
    private LocalDateTime checkOutTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private AttendanceStatus status = AttendanceStatus.PRESENT;

    @Column(name = "recognition_method")
    private String recognitionMethod; // "FACE_RECOGNITION", "MANUAL", etc.

    @Column(name = "face_recognition_confidence")
    private Double faceRecognitionConfidence;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    public enum AttendanceStatus {
        PRESENT, ABSENT, ON_LEAVE, HALF_DAY, LATE
    }
}


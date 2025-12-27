package com.civiltech.civildesk_backend.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Entity
@Table(name = "tasks")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class Task extends BaseEntity {

    // Task Date Range
    @Column(name = "start_date", nullable = false)
    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    @NotNull(message = "End date is required")
    private LocalDate endDate;

    // Location
    @NotBlank(message = "Location is required")
    @Column(name = "location", nullable = false)
    private String location;

    // Task Description
    @NotBlank(message = "Task description is required")
    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    // Mode of Travel
    @NotBlank(message = "Mode of travel is required")
    @Column(name = "mode_of_travel", nullable = false)
    private String modeOfTravel;

    // Site Information (Optional)
    @Column(name = "site_name")
    private String siteName;

    @Column(name = "site_contact_person_name")
    private String siteContactPersonName;

    @Column(name = "site_contact_phone")
    private String siteContactPhone;

    // Assigned by (Admin/HR)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_by", nullable = false)
    @NotNull(message = "Assigned by is required")
    private User assignedBy;

    // Task Status
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private TaskStatus status = TaskStatus.PENDING;

    // Review details (when employee approves/rejects)
    @Column(name = "reviewed_at")
    private java.time.LocalDateTime reviewedAt;

    @Column(name = "review_note", columnDefinition = "TEXT")
    private String reviewNote;

    // Enums
    public enum TaskStatus {
        PENDING("Pending"),
        APPROVED("Approved"),
        REJECTED("Rejected");

        private final String displayName;

        TaskStatus(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }

        @JsonValue
        public String toValue() {
            return name();
        }

        @JsonCreator
        public static TaskStatus fromValue(String value) {
            if (value == null) {
                return null;
            }
            // Case-insensitive lookup
            for (TaskStatus status : TaskStatus.values()) {
                if (status.name().equalsIgnoreCase(value)) {
                    return status;
                }
            }
            throw new IllegalArgumentException("Unknown TaskStatus value: " + value);
        }
    }
}

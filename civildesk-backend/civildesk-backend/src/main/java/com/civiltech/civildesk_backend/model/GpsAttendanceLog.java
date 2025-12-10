package com.civiltech.civildesk_backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "gps_attendance_logs")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class GpsAttendanceLog extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "attendance_id")
    private Attendance attendance;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "site_id")
    private Site site;

    // Punch Details
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "punch_type", nullable = false, length = 20)
    private PunchType punchType;

    @NotNull
    @Column(name = "punch_time", nullable = false)
    private LocalDateTime punchTime;

    @Column(name = "server_timestamp")
    private LocalDateTime serverTimestamp;

    // GPS Data
    @NotNull
    @Column(name = "latitude", nullable = false, columnDefinition = "DECIMAL(10, 8)")
    private Double latitude;

    @NotNull
    @Column(name = "longitude", nullable = false, columnDefinition = "DECIMAL(11, 8)")
    private Double longitude;

    @Column(name = "accuracy_meters", columnDefinition = "DECIMAL(10, 2)")
    private Double accuracyMeters;

    @Column(name = "altitude", columnDefinition = "DECIMAL(10, 2)")
    private Double altitude;

    // Device Information
    @Column(name = "device_id")
    private String deviceId;

    @Column(name = "device_name")
    private String deviceName;

    @Column(name = "device_model")
    private String deviceModel;

    @Column(name = "os_version", length = 50)
    private String osVersion;

    @Column(name = "app_version", length = 20)
    private String appVersion;

    // Validation
    @Column(name = "is_mock_location")
    private Boolean isMockLocation = false;

    @Column(name = "is_inside_geofence")
    private Boolean isInsideGeofence = true;

    @Column(name = "distance_from_site", columnDefinition = "DECIMAL(10, 2)")
    private Double distanceFromSite;

    // Network
    @Enumerated(EnumType.STRING)
    @Column(name = "network_status", length = 20)
    private NetworkStatus networkStatus;

    @Column(name = "ip_address", length = 50)
    private String ipAddress;

    // Sync
    @Enumerated(EnumType.STRING)
    @Column(name = "sync_status", length = 20)
    private SyncStatus syncStatus = SyncStatus.SYNCED;

    @Column(name = "offline_timestamp")
    private LocalDateTime offlineTimestamp;

    @Column(name = "synced_at")
    private LocalDateTime syncedAt;

    // Enums
    public enum PunchType {
        CHECK_IN, LUNCH_OUT, LUNCH_IN, CHECK_OUT
    }

    public enum NetworkStatus {
        ONLINE, OFFLINE
    }

    public enum SyncStatus {
        SYNCED, PENDING
    }
}


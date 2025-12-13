package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.GpsAttendanceLog;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GpsAttendanceRequest {

    @NotBlank(message = "Employee ID is required")
    private String employeeId;

    @NotNull(message = "Punch type is required")
    private GpsAttendanceLog.PunchType punchType;

    @NotNull(message = "Latitude is required")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    private Double longitude;

    private Double accuracyMeters;
    private Double altitude;

    // Device Information
    private String deviceId;
    private String deviceName;
    private String deviceModel;
    private String osVersion;
    private String appVersion;

    // Mock location detection flag from mobile
    private Boolean isMockLocation = false;

    // Network status
    private String networkStatus; // ONLINE, OFFLINE

    // For offline attendance - original timestamp from device
    private LocalDateTime offlineTimestamp;

    // Timestamp when location was captured (to validate location freshness)
    private LocalDateTime locationTimestamp;

    // Site ID if known
    private Long siteId;
}


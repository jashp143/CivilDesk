package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.GpsAttendanceLog;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GpsAttendanceResponse {

    private Long id;
    private Long attendanceId;
    private String employeeId;
    private String employeeName;

    private String punchType;
    private LocalDateTime punchTime;
    private LocalDateTime serverTimestamp;

    private Double latitude;
    private Double longitude;
    private Double accuracyMeters;

    private String deviceId;
    private String deviceName;

    private Boolean isMockLocation;
    private Boolean isInsideGeofence;
    private Double distanceFromSite;

    private Long siteId;
    private String siteName;
    private String siteCode;

    private String networkStatus;
    private String syncStatus;

    private LocalDateTime createdAt;

    public static GpsAttendanceResponse fromEntity(GpsAttendanceLog log) {
        GpsAttendanceResponse response = new GpsAttendanceResponse();
        response.setId(log.getId());
        if (log.getAttendance() != null) {
            response.setAttendanceId(log.getAttendance().getId());
        }
        if (log.getEmployee() != null) {
            response.setEmployeeId(log.getEmployee().getEmployeeId());
            response.setEmployeeName(log.getEmployee().getFirstName() + " " + log.getEmployee().getLastName());
        }
        response.setPunchType(log.getPunchType() != null ? log.getPunchType().name() : null);
        response.setPunchTime(log.getPunchTime());
        response.setServerTimestamp(log.getServerTimestamp());
        response.setLatitude(log.getLatitude());
        response.setLongitude(log.getLongitude());
        response.setAccuracyMeters(log.getAccuracyMeters());
        response.setDeviceId(log.getDeviceId());
        response.setDeviceName(log.getDeviceName());
        response.setIsMockLocation(log.getIsMockLocation());
        response.setIsInsideGeofence(log.getIsInsideGeofence());
        response.setDistanceFromSite(log.getDistanceFromSite());
        if (log.getSite() != null) {
            response.setSiteId(log.getSite().getId());
            response.setSiteName(log.getSite().getSiteName());
            response.setSiteCode(log.getSite().getSiteCode());
        }
        response.setNetworkStatus(log.getNetworkStatus() != null ? log.getNetworkStatus().name() : null);
        response.setSyncStatus(log.getSyncStatus() != null ? log.getSyncStatus().name() : null);
        response.setCreatedAt(log.getCreatedAt());
        return response;
    }
}


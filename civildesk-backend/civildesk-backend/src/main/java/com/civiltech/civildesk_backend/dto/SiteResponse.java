package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Site;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SiteResponse {

    private Long id;
    private String siteCode;
    private String siteName;
    private String description;
    private String address;
    private String city;
    private String state;
    private String pincode;

    private Double latitude;
    private Double longitude;

    private String geofenceType;
    private Integer geofenceRadiusMeters;
    private String geofencePolygon;

    private Boolean isActive;
    private LocalDate startDate;
    private LocalDate endDate;

    private LocalTime shiftStartTime;
    private LocalTime shiftEndTime;
    private LocalTime lunchStartTime;
    private LocalTime lunchEndTime;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Count of assigned employees
    private Integer assignedEmployeeCount;

    public static SiteResponse fromEntity(Site site) {
        SiteResponse response = new SiteResponse();
        response.setId(site.getId());
        response.setSiteCode(site.getSiteCode());
        response.setSiteName(site.getSiteName());
        response.setDescription(site.getDescription());
        response.setAddress(site.getAddress());
        response.setCity(site.getCity());
        response.setState(site.getState());
        response.setPincode(site.getPincode());
        response.setLatitude(site.getLatitude());
        response.setLongitude(site.getLongitude());
        response.setGeofenceType(site.getGeofenceType() != null ? site.getGeofenceType().name() : null);
        response.setGeofenceRadiusMeters(site.getGeofenceRadiusMeters());
        response.setGeofencePolygon(site.getGeofencePolygon());
        response.setIsActive(site.getIsActive());
        response.setStartDate(site.getStartDate());
        response.setEndDate(site.getEndDate());
        response.setShiftStartTime(site.getShiftStartTime());
        response.setShiftEndTime(site.getShiftEndTime());
        response.setLunchStartTime(site.getLunchStartTime());
        response.setLunchEndTime(site.getLunchEndTime());
        response.setCreatedAt(site.getCreatedAt());
        response.setUpdatedAt(site.getUpdatedAt());
        return response;
    }
}


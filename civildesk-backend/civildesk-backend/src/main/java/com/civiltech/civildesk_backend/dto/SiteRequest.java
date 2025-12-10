package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Site;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SiteRequest {

    private String siteCode;

    @NotBlank(message = "Site name is required")
    private String siteName;

    private String description;
    private String address;
    private String city;
    private String state;
    private String pincode;

    @NotNull(message = "Latitude is required")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    private Double longitude;

    private Site.GeofenceType geofenceType = Site.GeofenceType.RADIUS;
    private Integer geofenceRadiusMeters = 100;
    private String geofencePolygon;

    private Boolean isActive = true;
    private LocalDate startDate;
    private LocalDate endDate;

    private LocalTime shiftStartTime;
    private LocalTime shiftEndTime;
    private LocalTime lunchStartTime;
    private LocalTime lunchEndTime;
}


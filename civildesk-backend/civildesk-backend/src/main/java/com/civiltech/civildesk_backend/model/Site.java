package com.civiltech.civildesk_backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "sites")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class Site extends BaseEntity {

    @NotBlank(message = "Site code is required")
    @Column(name = "site_code", nullable = false, unique = true, length = 50)
    private String siteCode;

    @NotBlank(message = "Site name is required")
    @Column(name = "site_name", nullable = false)
    private String siteName;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "address", columnDefinition = "TEXT")
    private String address;

    @Column(name = "city", length = 100)
    private String city;

    @Column(name = "state", length = 100)
    private String state;

    @Column(name = "pincode", length = 10)
    private String pincode;

    // Location Center Point
    @NotNull(message = "Latitude is required")
    @Column(name = "latitude", nullable = false, columnDefinition = "DECIMAL(10, 8)")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    @Column(name = "longitude", nullable = false, columnDefinition = "DECIMAL(11, 8)")
    private Double longitude;

    // Geofence Configuration
    @Enumerated(EnumType.STRING)
    @Column(name = "geofence_type", length = 20)
    private GeofenceType geofenceType = GeofenceType.RADIUS;

    @Column(name = "geofence_radius_meters")
    private Integer geofenceRadiusMeters = 100;

    @Column(name = "geofence_polygon", columnDefinition = "TEXT")
    private String geofencePolygon; // JSON array of coordinates

    // Site Status
    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    // Shift Configuration
    @Column(name = "shift_start_time")
    private LocalTime shiftStartTime;

    @Column(name = "shift_end_time")
    private LocalTime shiftEndTime;

    @Column(name = "lunch_start_time")
    private LocalTime lunchStartTime;

    @Column(name = "lunch_end_time")
    private LocalTime lunchEndTime;

    // Enums
    public enum GeofenceType {
        RADIUS, POLYGON
    }
}


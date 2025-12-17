package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.GpsAttendanceRequest;
import com.civiltech.civildesk_backend.dto.GpsAttendanceResponse;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.model.*;
import com.civiltech.civildesk_backend.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class GpsAttendanceService {

    @Autowired
    private GpsAttendanceLogRepository gpsLogRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private SiteRepository siteRepository;

    @Autowired
    private EmployeeSiteAssignmentRepository assignmentRepository;

    @Autowired
    private GeofenceService geofenceService;

    /**
     * Mark GPS-based attendance
     */
    @Transactional
    public GpsAttendanceResponse markGpsAttendance(GpsAttendanceRequest request) {
        // Validate coordinates
        if (!geofenceService.isValidCoordinates(request.getLatitude(), request.getLongitude())) {
            throw new BadRequestException("Invalid GPS coordinates");
        }

        // Block mock location
        if (Boolean.TRUE.equals(request.getIsMockLocation())) {
            throw new BadRequestException("Mock location detected. Please disable mock location and try again.");
        }

        // Validate location timestamp freshness (must be within last 60 seconds)
        // This prevents using stale/cached location data
        // Allow up to 10 seconds in the future to account for clock drift and network latency
        if (request.getLocationTimestamp() != null) {
            LocalDateTime now = LocalDateTime.now();
            long secondsSinceLocationCapture = ChronoUnit.SECONDS.between(request.getLocationTimestamp(), now);
            
            // Allow up to 10 seconds in the future to account for:
            // - Clock drift between device and server
            // - Network latency
            // - Processing time
            if (secondsSinceLocationCapture < -10) {
                throw new BadRequestException(String.format(
                    "Location timestamp is too far in the future (%d seconds ahead). Please check your device time settings and ensure it's synchronized with network time.",
                    Math.abs(secondsSinceLocationCapture)
                ));
            }
            
            if (secondsSinceLocationCapture > 60) {
                throw new BadRequestException(String.format(
                    "Location data is too old (%d seconds). Please refresh your location and try again. Location must be captured within the last 60 seconds.",
                    secondsSinceLocationCapture
                ));
            }
        } else {
            // If timestamp is not provided, log a warning but don't reject (for backward compatibility)
            // In production, you might want to make this required
        }

        // Find employee
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(request.getEmployeeId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found: " + request.getEmployeeId()));

        // Check if employee is assigned to GPS-based attendance
        if (employee.getAttendanceMethod() != Employee.AttendanceMethod.GPS_BASED) {
            throw new BadRequestException("Employee is not assigned to GPS-based attendance. Current method: " + 
                    employee.getAttendanceMethod());
        }

        // Find assigned site for employee
        Site site = findAssignedSiteForLocation(employee, request.getLatitude(), request.getLongitude());
        
        if (site == null && request.getSiteId() != null) {
            site = siteRepository.findById(request.getSiteId())
                    .orElseThrow(() -> new ResourceNotFoundException("Site not found: " + request.getSiteId()));
        }

        // Require that employee must be assigned to a site
        if (site == null) {
            throw new BadRequestException("You are not assigned to any site or you are outside all assigned sites. Please contact your administrator or move to an assigned site to mark attendance.");
        }

        // Calculate distance from site
        Double distanceFromSite = geofenceService.getDistanceFromSite(site, request.getLatitude(), request.getLongitude());
        boolean isInsideGeofence = geofenceService.isInsideGeofence(site, request.getLatitude(), request.getLongitude());
        
        // Reject if outside geofence - attendance can only be marked inside the site
        if (!isInsideGeofence) {
            throw new BadRequestException(String.format(
                    "You are %.0f meters away from the site boundary. You must be inside the site (within %d meters) to mark attendance. Please move closer to the site.",
                    distanceFromSite - (site.getGeofenceRadiusMeters() != null ? site.getGeofenceRadiusMeters() : 0),
                    site.getGeofenceRadiusMeters() != null ? site.getGeofenceRadiusMeters() : 0
            ));
        }

        // Validate punch sequence
        validatePunchSequence(employee.getEmployeeId(), request.getPunchType());

        // Get or create attendance record for today
        LocalDate today = LocalDate.now();
        Attendance attendance = attendanceRepository.findByEmployeeAndDate(employee, today)
                .orElseGet(() -> createNewAttendance(employee, today));

        // Create GPS attendance log
        GpsAttendanceLog log = new GpsAttendanceLog();
        log.setAttendance(attendance);
        log.setEmployee(employee);
        log.setSite(site);
        log.setPunchType(request.getPunchType());
        log.setPunchTime(LocalDateTime.now());
        log.setServerTimestamp(LocalDateTime.now());
        log.setLatitude(request.getLatitude());
        log.setLongitude(request.getLongitude());
        log.setAccuracyMeters(request.getAccuracyMeters());
        log.setAltitude(request.getAltitude());
        log.setDeviceId(request.getDeviceId());
        log.setDeviceName(request.getDeviceName());
        log.setDeviceModel(request.getDeviceModel());
        log.setOsVersion(request.getOsVersion());
        log.setAppVersion(request.getAppVersion());
        log.setIsMockLocation(request.getIsMockLocation());
        log.setIsInsideGeofence(isInsideGeofence);
        log.setDistanceFromSite(distanceFromSite);
        log.setNetworkStatus(request.getNetworkStatus() != null ? 
                GpsAttendanceLog.NetworkStatus.valueOf(request.getNetworkStatus()) : 
                GpsAttendanceLog.NetworkStatus.ONLINE);
        log.setOfflineTimestamp(request.getOfflineTimestamp());
        log.setSyncStatus(GpsAttendanceLog.SyncStatus.SYNCED);
        log.setSyncedAt(LocalDateTime.now());

        log = gpsLogRepository.save(log);

        // Update attendance record based on punch type
        updateAttendanceFromPunch(attendance, request.getPunchType(), log.getPunchTime(), site);
        attendanceRepository.save(attendance);

        return GpsAttendanceResponse.fromEntity(log);
    }

    /**
     * Sync offline attendance punches
     */
    @Transactional
    public List<GpsAttendanceResponse> syncOfflineAttendance(List<GpsAttendanceRequest> requests) {
        return requests.stream()
                .map(this::markGpsAttendance)
                .collect(Collectors.toList());
    }

    /**
     * Get attendance logs for an employee on a specific date
     */
    public List<GpsAttendanceResponse> getEmployeeAttendanceForDate(String employeeId, LocalDate date) {
        return gpsLogRepository.findByEmployeeIdAndDate(employeeId, date).stream()
                .map(GpsAttendanceResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Get attendance logs for a site on a specific date
     */
    public List<GpsAttendanceResponse> getSiteAttendanceForDate(Long siteId, LocalDate date) {
        return gpsLogRepository.findBySiteIdAndDate(siteId, date).stream()
                .map(GpsAttendanceResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Get all attendance logs for a date (for map dashboard)
     */
    public List<GpsAttendanceResponse> getAllAttendanceForDate(LocalDate date) {
        return gpsLogRepository.findAllPunchesForDateWithDetails(date).stream()
                .map(GpsAttendanceResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Get all attendance logs for a date, optionally filtered by employee (for map dashboard)
     */
    public List<GpsAttendanceResponse> getAllAttendanceForDate(LocalDate date, String employeeId) {
        if (employeeId != null && !employeeId.isEmpty() && !employeeId.equals("all")) {
            return gpsLogRepository.findAllPunchesForDateWithDetailsAndEmployee(date, employeeId).stream()
                    .map(GpsAttendanceResponse::fromEntity)
                    .collect(Collectors.toList());
        }
        return getAllAttendanceForDate(date);
    }

    /**
     * Get attendance logs for date range
     */
    public Page<GpsAttendanceResponse> getAttendanceForDateRange(
            LocalDateTime startDateTime, LocalDateTime endDateTime, Pageable pageable) {
        return gpsLogRepository.findByDateRange(startDateTime, endDateTime, pageable)
                .map(GpsAttendanceResponse::fromEntity);
    }

    /**
     * Get attendance summary for a date
     */
    public List<Object[]> getAttendanceSummaryForDate(LocalDate date) {
        return gpsLogRepository.countPunchesByTypeForDate(date);
    }

    // ==================== Helper Methods ====================

    private Site findAssignedSiteForLocation(Employee employee, double latitude, double longitude) {
        List<EmployeeSiteAssignment> assignments = 
                assignmentRepository.findActiveAssignmentsByEmployeeIdAndDate(employee.getId(), LocalDate.now());

        for (EmployeeSiteAssignment assignment : assignments) {
            Site site = assignment.getSite();
            if (geofenceService.isInsideGeofence(site, latitude, longitude)) {
                return site;
            }
        }

        // If no exact match, return primary assignment's site
        return assignmentRepository.findPrimaryAssignmentByEmployeeId(employee.getId())
                .map(EmployeeSiteAssignment::getSite)
                .orElse(null);
    }

    private void validatePunchSequence(String employeeId, GpsAttendanceLog.PunchType punchType) {
        LocalDate today = LocalDate.now();
        List<GpsAttendanceLog> todayLogs = gpsLogRepository.findByEmployeeIdAndDate(employeeId, today);

        boolean hasCheckIn = todayLogs.stream()
                .anyMatch(log -> log.getPunchType() == GpsAttendanceLog.PunchType.CHECK_IN);
        boolean hasLunchOut = todayLogs.stream()
                .anyMatch(log -> log.getPunchType() == GpsAttendanceLog.PunchType.LUNCH_OUT);
        boolean hasLunchIn = todayLogs.stream()
                .anyMatch(log -> log.getPunchType() == GpsAttendanceLog.PunchType.LUNCH_IN);
        boolean hasCheckOut = todayLogs.stream()
                .anyMatch(log -> log.getPunchType() == GpsAttendanceLog.PunchType.CHECK_OUT);

        switch (punchType) {
            case CHECK_IN:
                if (hasCheckIn) {
                    throw new BadRequestException("Check-in already recorded for today");
                }
                break;
            case LUNCH_OUT:
                if (!hasCheckIn) {
                    throw new BadRequestException("Please check-in first before marking lunch out");
                }
                if (hasLunchOut) {
                    throw new BadRequestException("Lunch out already recorded for today");
                }
                break;
            case LUNCH_IN:
                if (!hasLunchOut) {
                    throw new BadRequestException("Please mark lunch out first before marking lunch in");
                }
                if (hasLunchIn) {
                    throw new BadRequestException("Lunch in already recorded for today");
                }
                break;
            case CHECK_OUT:
                if (!hasCheckIn) {
                    throw new BadRequestException("Please check-in first before checking out");
                }
                if (hasCheckOut) {
                    throw new BadRequestException("Check-out already recorded for today");
                }
                break;
        }
    }

    private Attendance createNewAttendance(Employee employee, LocalDate date) {
        Attendance attendance = new Attendance();
        attendance.setEmployee(employee);
        attendance.setDate(date);
        attendance.setStatus(Attendance.AttendanceStatus.PRESENT);
        attendance.setRecognitionMethod("GPS_BASED");
        return attendanceRepository.save(attendance);
    }

    private void updateAttendanceFromPunch(Attendance attendance, GpsAttendanceLog.PunchType punchType, 
                                           LocalDateTime punchTime, Site site) {
        switch (punchType) {
            case CHECK_IN:
                attendance.setCheckInTime(punchTime);
                break;
            case LUNCH_OUT:
                attendance.setLunchOutTime(punchTime);
                break;
            case LUNCH_IN:
                attendance.setLunchInTime(punchTime);
                break;
            case CHECK_OUT:
                attendance.setCheckOutTime(punchTime);
                calculateWorkingHours(attendance);
                break;
        }

        // Update site info on attendance record
        if (site != null) {
            // Store the site ID and distance in the attendance record
            // These fields would need to be added to the Attendance model if not present
        }
    }

    private void calculateWorkingHours(Attendance attendance) {
        if (attendance.getCheckInTime() == null || attendance.getCheckOutTime() == null) {
            return;
        }

        LocalDateTime checkIn = attendance.getCheckInTime();
        LocalDateTime checkOut = attendance.getCheckOutTime();

        // Calculate total hours
        double totalMinutes = java.time.Duration.between(checkIn, checkOut).toMinutes();

        // Subtract lunch break if recorded
        if (attendance.getLunchOutTime() != null && attendance.getLunchInTime() != null) {
            double lunchMinutes = java.time.Duration.between(
                    attendance.getLunchOutTime(), attendance.getLunchInTime()).toMinutes();
            totalMinutes -= lunchMinutes;
        }

        double totalHours = totalMinutes / 60.0;

        // Cap working hours at 8, rest is overtime
        if (totalHours > 8) {
            attendance.setWorkingHours(8.0);
            attendance.setOvertimeHours(totalHours - 8.0);
        } else {
            attendance.setWorkingHours(totalHours);
            attendance.setOvertimeHours(0.0);
        }
    }
}


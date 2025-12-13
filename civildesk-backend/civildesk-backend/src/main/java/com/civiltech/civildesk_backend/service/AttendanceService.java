package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.AttendanceRequest;
import com.civiltech.civildesk_backend.dto.AttendanceResponse;
import com.civiltech.civildesk_backend.dto.AttendanceAnalyticsResponse;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.model.Attendance;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.repository.AttendanceRepository;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
public class AttendanceService {

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private AttendanceCalculationService calculationService;

    public Employee getEmployeeByUserId(Long userId) {
        return employeeRepository.findByUserIdAndDeletedFalse(userId).orElse(null);
    }

    @Transactional
    public AttendanceResponse markAttendance(AttendanceRequest request) {
        try {
            System.out.println("=== Marking Attendance ===");
            System.out.println("Employee ID: " + request.getEmployeeId());
            System.out.println("Attendance Type: " + request.getAttendanceType());
            System.out.println("Recognition Method: " + request.getRecognitionMethod());
            
            Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(request.getEmployeeId())
                    .orElseThrow(() -> {
                        System.err.println("Employee not found with ID: " + request.getEmployeeId());
                        return new ResourceNotFoundException("Employee not found with ID: " + request.getEmployeeId());
                    });

            System.out.println("Employee found: " + employee.getFirstName() + " " + employee.getLastName());

            LocalDate today = LocalDate.now();
            Attendance attendance = attendanceRepository.findByEmployeeAndDate(employee, today)
                    .orElse(new Attendance());

            System.out.println("Existing attendance record: " + (attendance.getId() != null ? "Found (ID: " + attendance.getId() + ")" : "New"));

            // Ensure BaseEntity fields are set for new records
            if (attendance.getId() == null) {
                attendance.setDeleted(false);
                System.out.println("Initialized new attendance record");
            }

            attendance.setEmployee(employee);
            attendance.setDate(today);
            
            LocalDateTime now = LocalDateTime.now();
            String attendanceType = request.getAttendanceType() != null ? request.getAttendanceType() : "PUNCH_IN";
            
            switch (attendanceType.toUpperCase()) {
                case "PUNCH_IN":
                    if (attendance.getCheckInTime() == null) {
                        attendance.setCheckInTime(now);
                        System.out.println("Setting check-in time: " + now);
                    }
                    attendance.setStatus(Attendance.AttendanceStatus.PRESENT);
                    break;
                case "LUNCH_OUT":
                    attendance.setLunchOutTime(now);
                    System.out.println("Setting lunch out time: " + now);
                    if (attendance.getCheckInTime() == null) {
                        attendance.setCheckInTime(now);
                    }
                    break;
                case "LUNCH_IN":
                    attendance.setLunchInTime(now);
                    System.out.println("Setting lunch in time: " + now);
                    break;
                case "PUNCH_OUT":
                    attendance.setCheckOutTime(now);
                    System.out.println("Setting check-out time: " + now);
                    break;
            }
            
            attendance.setRecognitionMethod(request.getRecognitionMethod());
            attendance.setFaceRecognitionConfidence(request.getFaceRecognitionConfidence());
            
            // Calculate working hours and overtime if check-in and check-out are available
            if (attendance.getCheckInTime() != null && attendance.getCheckOutTime() != null) {
                AttendanceCalculationService.CalculationResult result = 
                    calculationService.calculateAttendance(attendance);
                attendance.setWorkingHours(result.getWorkingHours());
                attendance.setOvertimeHours(result.getOvertimeHours());
            }
            
            System.out.println("Saving attendance record...");
            System.out.println("Before save - Employee ID: " + attendance.getEmployee().getId());
            System.out.println("Before save - Date: " + attendance.getDate());
            System.out.println("Before save - Status: " + attendance.getStatus());
            System.out.println("Before save - Check-in time: " + attendance.getCheckInTime());
            
            attendance = attendanceRepository.saveAndFlush(attendance);
            
            System.out.println("After save - Attendance ID: " + attendance.getId());
            System.out.println("After save - Created at: " + attendance.getCreatedAt());
            System.out.println("Attendance saved and flushed to database successfully!");
            
            return mapToResponse(attendance);
        } catch (Exception e) {
            System.err.println("Error in markAttendance: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    @Transactional
    public AttendanceResponse checkOut(String employeeId) {
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + employeeId));

        LocalDate today = LocalDate.now();
        Attendance attendance = attendanceRepository.findByEmployeeAndDate(employee, today)
                .orElseThrow(() -> new ResourceNotFoundException("No attendance record found for today"));

        attendance.setCheckOutTime(LocalDateTime.now());
        
        // Calculate working hours and overtime after check-out
        if (attendance.getCheckInTime() != null && attendance.getCheckOutTime() != null) {
            AttendanceCalculationService.CalculationResult result = 
                calculationService.calculateAttendance(attendance);
            attendance.setWorkingHours(result.getWorkingHours());
            attendance.setOvertimeHours(result.getOvertimeHours());
        }
        
        attendance = attendanceRepository.save(attendance);
        
        return mapToResponse(attendance);
    }

    public AttendanceResponse getTodayAttendance(String employeeId) {
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + employeeId));

        LocalDate today = LocalDate.now();
        Attendance attendance = attendanceRepository.findByEmployeeAndDate(employee, today)
                .orElse(null);

        if (attendance == null) {
            return null;
        }

        return mapToResponse(attendance);
    }

    @Transactional(readOnly = true)
    public List<AttendanceResponse> getEmployeeAttendance(String employeeId, LocalDate startDate, LocalDate endDate) {
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + employeeId));

        List<Attendance> attendances = attendanceRepository.findByEmployeeIdAndDateBetween(
                employee.getId(), startDate, endDate);

        return attendances.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public List<AttendanceResponse> getDailyAttendance(LocalDate date) {
        List<Attendance> attendances = attendanceRepository.findAllByDate(date);
        return attendances.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public AttendanceResponse updatePunchTime(Long attendanceId, String punchType, LocalDateTime newTime) {
        Attendance attendance = attendanceRepository.findById(attendanceId)
                .orElseThrow(() -> new ResourceNotFoundException("Attendance record not found with ID: " + attendanceId));

        // Update the appropriate punch time based on punch type
        switch (punchType.toUpperCase()) {
            case "CHECK_IN":
                attendance.setCheckInTime(newTime);
                if (attendance.getStatus() == Attendance.AttendanceStatus.ABSENT) {
                    attendance.setStatus(Attendance.AttendanceStatus.PRESENT);
                }
                break;
            case "LUNCH_OUT":
                attendance.setLunchOutTime(newTime);
                break;
            case "LUNCH_IN":
                attendance.setLunchInTime(newTime);
                break;
            case "CHECK_OUT":
                attendance.setCheckOutTime(newTime);
                break;
            default:
                throw new IllegalArgumentException("Invalid punch type: " + punchType);
        }

        // Recalculate working hours and overtime after updating punch time
        if (attendance.getCheckInTime() != null && attendance.getCheckOutTime() != null) {
            AttendanceCalculationService.CalculationResult result = 
                calculationService.calculateAttendance(attendance);
            attendance.setWorkingHours(result.getWorkingHours());
            attendance.setOvertimeHours(result.getOvertimeHours());
        }

        attendance = attendanceRepository.save(attendance);
        return mapToResponse(attendance);
    }

    public AttendanceAnalyticsResponse getAttendanceAnalytics(String employeeId, LocalDate startDate, LocalDate endDate) {
        // Validate employee exists
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + employeeId));
        
        // Get all attendance records for the date range
        List<Attendance> attendances = attendanceRepository.findEmployeeAttendanceForAnalytics(employeeId, startDate, endDate);
        
        // Calculate summary statistics
        Double totalWorkingHours = attendanceRepository.sumWorkingHours(employeeId, startDate, endDate);
        Double totalOvertimeHours = attendanceRepository.sumOvertimeHours(employeeId, startDate, endDate);
        Long presentDays = attendanceRepository.countPresentDaysByEmployeeId(employeeId, startDate, endDate);
        Long absentDays = attendanceRepository.countAbsentDays(employeeId, startDate, endDate);
        Long lateDays = attendanceRepository.countLateDays(employeeId, startDate, endDate);
        
        // Calculate total working days (Monday to Saturday, excluding Sunday)
        int totalWorkingDays = calculateWorkingDays(startDate, endDate);
        
        // Calculate attendance percentage
        double attendancePercentage = totalWorkingDays > 0 
            ? (presentDays.doubleValue() / totalWorkingDays) * 100.0 
            : 0.0;
        
        // Calculate total days present from working hours (working_hours / 8)
        int calculatedDaysPresent = totalWorkingHours != null && totalWorkingHours > 0 
            ? (int) Math.round(totalWorkingHours.doubleValue() / 8.0) 
            : 0;
        
        // Create daily logs
        List<AttendanceAnalyticsResponse.DailyAttendanceLog> dailyLogs = new ArrayList<>();
        for (Attendance attendance : attendances) {
            AttendanceAnalyticsResponse.DailyAttendanceLog log = new AttendanceAnalyticsResponse.DailyAttendanceLog();
            log.setAttendanceId(attendance.getId());
            log.setDate(attendance.getDate());
            log.setDayOfWeek(attendance.getDate().getDayOfWeek().getDisplayName(TextStyle.FULL, Locale.ENGLISH));
            log.setCheckInTime(attendance.getCheckInTime());
            log.setLunchOutTime(attendance.getLunchOutTime());
            log.setLunchInTime(attendance.getLunchInTime());
            log.setCheckOutTime(attendance.getCheckOutTime());
            log.setStatus(attendance.getStatus().name());
            log.setWorkingHours(attendance.getWorkingHours());
            log.setOvertimeHours(attendance.getOvertimeHours());
            log.setNotes(attendance.getNotes());
            
            // Check if late (check-in after 9:30 AM)
            if (attendance.getCheckInTime() != null) {
                LocalTime checkInTime = attendance.getCheckInTime().toLocalTime();
                LocalTime lateThreshold = LocalTime.of(9, 30);
                log.setIsLate(checkInTime.isAfter(lateThreshold));
            } else {
                log.setIsLate(false);
            }
            
            dailyLogs.add(log);
        }
        
        // Build response
        AttendanceAnalyticsResponse response = new AttendanceAnalyticsResponse();
        response.setEmployeeId(employeeId);
        response.setEmployeeName(employee.getFirstName() + " " + employee.getLastName());
        response.setDepartment(employee.getDepartment());
        response.setStartDate(startDate);
        response.setEndDate(endDate);
        response.setTotalWorkingHours(totalWorkingHours != null ? totalWorkingHours : 0.0);
        response.setTotalOvertimeHours(totalOvertimeHours != null ? totalOvertimeHours : 0.0);
        response.setAttendancePercentage(Math.round(attendancePercentage * 100.0) / 100.0);
        response.setTotalDaysPresent(calculatedDaysPresent);
        response.setTotalWorkingDays(totalWorkingDays);
        response.setTotalAbsentDays(absentDays.intValue());
        response.setTotalLateDays(lateDays.intValue());
        response.setDailyLogs(dailyLogs);
        
        return response;
    }
    
    private int calculateWorkingDays(LocalDate startDate, LocalDate endDate) {
        int workingDays = 0;
        LocalDate currentDate = startDate;
        
        while (!currentDate.isAfter(endDate)) {
            DayOfWeek dayOfWeek = currentDate.getDayOfWeek();
            // Monday to Saturday are working days, Sunday is non-working day
            if (dayOfWeek != DayOfWeek.SUNDAY) {
                workingDays++;
            }
            currentDate = currentDate.plusDays(1);
        }
        
        return workingDays;
    }

    private AttendanceResponse mapToResponse(Attendance attendance) {
        AttendanceResponse response = new AttendanceResponse();
        response.setId(attendance.getId());
        response.setEmployeeId(attendance.getEmployee().getEmployeeId());
        response.setEmployeeName(attendance.getEmployee().getFirstName() + " " + attendance.getEmployee().getLastName());
        response.setDate(attendance.getDate());
        response.setCheckInTime(attendance.getCheckInTime());
        response.setLunchOutTime(attendance.getLunchOutTime());
        response.setLunchInTime(attendance.getLunchInTime());
        response.setCheckOutTime(attendance.getCheckOutTime());
        response.setStatus(attendance.getStatus().name());
        response.setRecognitionMethod(attendance.getRecognitionMethod());
        response.setFaceRecognitionConfidence(attendance.getFaceRecognitionConfidence());
        response.setNotes(attendance.getNotes());
        response.setWorkingHours(attendance.getWorkingHours());
        response.setOvertimeHours(attendance.getOvertimeHours());
        return response;
    }
}


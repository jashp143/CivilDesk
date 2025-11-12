package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.AttendanceRequest;
import com.civiltech.civildesk_backend.dto.AttendanceResponse;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.model.Attendance;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.repository.AttendanceRepository;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AttendanceService {

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

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
        return response;
    }
}


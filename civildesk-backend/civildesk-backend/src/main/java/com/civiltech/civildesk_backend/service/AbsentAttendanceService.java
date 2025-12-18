package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.model.Attendance;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.Leave;
import com.civiltech.civildesk_backend.repository.AttendanceRepository;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.HolidayRepository;
import com.civiltech.civildesk_backend.repository.LeaveRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;

/**
 * Service for automatically marking absent employees.
 * Runs daily to mark employees as absent if they haven't marked attendance.
 */
@Service
public class AbsentAttendanceService {

    private static final Logger logger = LoggerFactory.getLogger(AbsentAttendanceService.class);

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private HolidayRepository holidayRepository;

    @Autowired
    private LeaveRepository leaveRepository;

    /**
     * Scheduled job to mark absent employees.
     * Runs daily at 11:59 PM to mark absent for the current day.
     * Also runs at 9:00 AM to mark absent for the previous day (if not already marked).
     */
    @Scheduled(cron = "0 59 23 * * *") // Every day at 11:59 PM
    @Transactional
    public void markAbsentForToday() {
        LocalDate today = LocalDate.now();
        logger.info("Starting absent marking job for date: {}", today);
        markAbsentForDate(today);
    }

    /**
     * Scheduled job to mark absent for previous day (catch-up).
     * Runs daily at 9:00 AM to ensure previous day's absent records are created.
     */
    @Scheduled(cron = "0 0 9 * * *") // Every day at 9:00 AM
    @Transactional
    public void markAbsentForPreviousDay() {
        LocalDate yesterday = LocalDate.now().minusDays(1);
        logger.info("Starting catch-up absent marking job for date: {}", yesterday);
        markAbsentForDate(yesterday);
    }

    /**
     * Manually trigger absent marking for a specific date.
     * Useful for admin operations or backfilling missing records.
     *
     * @param date The date to mark absent for
     * @return Number of absent records created
     */
    @Transactional
    public int markAbsentForDate(LocalDate date) {
        logger.info("Marking absent employees for date: {}", date);

        // Skip if date is Sunday (non-working day)
        if (date.getDayOfWeek() == DayOfWeek.SUNDAY) {
            logger.info("Skipping absent marking for {} - Sunday is a non-working day", date);
            return 0;
        }

        // Skip if date is a holiday
        if (holidayRepository.existsByDateAndDeletedFalse(date)) {
            logger.info("Skipping absent marking for {} - It is a holiday", date);
            return 0;
        }

        // Get all active employees
        List<Employee> activeEmployees = employeeRepository
                .findByEmploymentStatusAndDeletedFalse(Employee.EmploymentStatus.ACTIVE);

        int absentCount = 0;

        for (Employee employee : activeEmployees) {
            try {
                // Check if attendance record already exists
                Attendance existingAttendance = attendanceRepository
                        .findByEmployeeAndDate(employee, date)
                        .orElse(null);

                if (existingAttendance != null) {
                    // Attendance already exists, skip
                    continue;
                }

                // Check if employee is on approved leave for this date
                if (isEmployeeOnLeave(employee, date)) {
                    // Create ON_LEAVE attendance record instead of ABSENT
                    createLeaveAttendanceRecord(employee, date);
                    logger.debug("Created ON_LEAVE record for employee {} on {}", 
                            employee.getEmployeeId(), date);
                    continue;
                }

                // Create ABSENT attendance record
                Attendance absentAttendance = new Attendance();
                absentAttendance.setEmployee(employee);
                absentAttendance.setDate(date);
                absentAttendance.setStatus(Attendance.AttendanceStatus.ABSENT);
                absentAttendance.setRecognitionMethod("AUTO_ABSENT");
                absentAttendance.setNotes("Automatically marked as absent - no attendance recorded");
                absentAttendance.setDeleted(false);

                attendanceRepository.save(absentAttendance);
                absentCount++;

                logger.debug("Marked absent: {} ({}) for date {}", 
                        employee.getEmployeeId(), 
                        employee.getFirstName() + " " + employee.getLastName(), 
                        date);

            } catch (Exception e) {
                logger.error("Error marking absent for employee {} on date {}: {}", 
                        employee.getEmployeeId(), date, e.getMessage(), e);
                // Continue with next employee instead of failing entire job
            }
        }

        logger.info("Completed absent marking for date: {}. Created {} absent records", date, absentCount);
        return absentCount;
    }

    /**
     * Check if employee is on approved leave for a specific date.
     *
     * @param employee The employee to check
     * @param date The date to check
     * @return true if employee is on approved leave, false otherwise
     */
    private boolean isEmployeeOnLeave(Employee employee, LocalDate date) {
        List<Leave> leaves = leaveRepository.findLeavesByEmployeeAndDateRange(
                employee.getId(), date, date);

        return leaves.stream()
                .anyMatch(leave -> leave.getStatus() == Leave.LeaveStatus.APPROVED
                        && !leave.getDeleted()
                        && !date.isBefore(leave.getStartDate())
                        && !date.isAfter(leave.getEndDate()));
    }

    /**
     * Create an ON_LEAVE attendance record for an employee.
     *
     * @param employee The employee
     * @param date The date
     */
    private void createLeaveAttendanceRecord(Employee employee, LocalDate date) {
        // Find the leave record
        List<Leave> leaves = leaveRepository.findLeavesByEmployeeAndDateRange(
                employee.getId(), date, date);

        Leave leave = leaves.stream()
                .filter(l -> l.getStatus() == Leave.LeaveStatus.APPROVED
                        && !l.getDeleted()
                        && !date.isBefore(l.getStartDate())
                        && !date.isAfter(l.getEndDate()))
                .findFirst()
                .orElse(null);

        if (leave == null) {
            return;
        }

        Attendance leaveAttendance = new Attendance();
        leaveAttendance.setEmployee(employee);
        leaveAttendance.setDate(date);
        leaveAttendance.setStatus(Attendance.AttendanceStatus.ON_LEAVE);
        leaveAttendance.setRecognitionMethod("AUTO_LEAVE");
        leaveAttendance.setNotes("On leave: " + leave.getLeaveType().getDisplayName());
        leaveAttendance.setDeleted(false);

        // If half-day leave, set appropriate status
        if (leave.getIsHalfDay()) {
            leaveAttendance.setStatus(Attendance.AttendanceStatus.HALF_DAY);
        }

        attendanceRepository.save(leaveAttendance);
    }

    /**
     * Check if a date is a working day (not Sunday and not a holiday).
     *
     * @param date The date to check
     * @return true if it's a working day, false otherwise
     */
    public boolean isWorkingDay(LocalDate date) {
        // Sunday is not a working day
        if (date.getDayOfWeek() == DayOfWeek.SUNDAY) {
            return false;
        }

        // Check if it's a holiday
        return !holidayRepository.existsByDateAndDeletedFalse(date);
    }

    /**
     * Manually mark an employee as absent for a specific date.
     * This method allows admins to manually mark absent.
     *
     * @param employeeId The employee ID
     * @param date The date
     * @return The created/updated attendance record
     */
    @Transactional
    public Attendance markEmployeeAbsent(String employeeId, LocalDate date) {
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(employeeId)
                .orElseThrow(() -> new RuntimeException("Employee not found: " + employeeId));

        // Check if attendance already exists
        Attendance attendance = attendanceRepository
                .findByEmployeeAndDate(employee, date)
                .orElse(new Attendance());

        // If attendance exists and is PRESENT, don't override (admin should use update status)
        if (attendance.getId() != null && attendance.getStatus() == Attendance.AttendanceStatus.PRESENT) {
            throw new RuntimeException("Employee already marked as PRESENT for this date. Use update status instead.");
        }

        attendance.setEmployee(employee);
        attendance.setDate(date);
        attendance.setStatus(Attendance.AttendanceStatus.ABSENT);
        attendance.setRecognitionMethod("MANUAL");
        attendance.setNotes("Manually marked as absent by admin");
        attendance.setDeleted(false);

        return attendanceRepository.save(attendance);
    }

    /**
     * Bulk mark absent for multiple employees on a specific date.
     *
     * @param employeeIds List of employee IDs
     * @param date The date
     * @return Number of records created/updated
     */
    @Transactional
    public int bulkMarkAbsent(List<String> employeeIds, LocalDate date) {
        int count = 0;
        for (String employeeId : employeeIds) {
            try {
                markEmployeeAbsent(employeeId, date);
                count++;
            } catch (Exception e) {
                logger.error("Error marking absent for employee {} on date {}: {}", 
                        employeeId, date, e.getMessage());
            }
        }
        return count;
    }
}


package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.HolidayRequest;
import com.civiltech.civildesk_backend.dto.HolidayResponse;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.model.Attendance;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.Holiday;
import com.civiltech.civildesk_backend.repository.AttendanceRepository;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.HolidayRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class HolidayService {

    @Autowired
    private HolidayRepository holidayRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private AttendanceCalculationService calculationService;

    // Normalized holiday attendance times
    private static final LocalTime HOLIDAY_CHECK_IN = LocalTime.of(9, 0);   // 09:00
    private static final LocalTime HOLIDAY_LUNCH_OUT = LocalTime.of(13, 0); // 13:00
    private static final LocalTime HOLIDAY_LUNCH_IN = LocalTime.of(14, 0);   // 14:00
    private static final LocalTime HOLIDAY_CHECK_OUT = LocalTime.of(18, 0);  // 18:00

    @Transactional
    @CacheEvict(value = "holidays", allEntries = true)
    public HolidayResponse createHoliday(HolidayRequest request) {
        // Validate date
        if (request.getDate() == null) {
            throw new BadRequestException("Holiday date is required");
        }

        if (request.getName() == null || request.getName().trim().isEmpty()) {
            throw new BadRequestException("Holiday name is required");
        }

        // Check if holiday already exists for this date
        if (holidayRepository.existsByDateAndDeletedFalse(request.getDate())) {
            throw new BadRequestException("Holiday already exists for date: " + request.getDate());
        }

        // Create holiday
        Holiday holiday = new Holiday();
        holiday.setDate(request.getDate());
        holiday.setName(request.getName().trim());
        holiday.setDescription(request.getDescription() != null ? request.getDescription().trim() : null);
        holiday.setIsActive(request.getIsActive() != null ? request.getIsActive() : true);
        holiday.setDeleted(false);

        holiday = holidayRepository.save(holiday);

        // Mark normalized attendance for all employees (if not Sunday)
        if (holiday.getIsActive()) {
            markNormalizedAttendanceForHoliday(holiday.getDate());
        }

        return mapToResponse(holiday);
    }

    @Transactional
    @CacheEvict(value = "holidays", allEntries = true)
    public HolidayResponse updateHoliday(Long id, HolidayRequest request) {
        Long holidayId = Objects.requireNonNull(id, "Holiday ID cannot be null");
        Holiday holiday = holidayRepository.findById(holidayId)
                .orElseThrow(() -> new ResourceNotFoundException("Holiday not found with id: " + holidayId));

        if (holiday.getDeleted()) {
            throw new ResourceNotFoundException("Holiday not found with id: " + id);
        }

        // If date is being changed, check for conflicts
        if (request.getDate() != null && !request.getDate().equals(holiday.getDate())) {
            if (holidayRepository.existsByDateAndDeletedFalse(request.getDate())) {
                throw new BadRequestException("Holiday already exists for date: " + request.getDate());
            }
        }

        // Update fields
        if (request.getDate() != null) {
            LocalDate oldDate = holiday.getDate();
            holiday.setDate(request.getDate());
            
            // If date changed and was active, remove old attendance and mark new
            if (holiday.getIsActive() && !oldDate.equals(request.getDate())) {
                // Remove normalized attendance from old date
                removeNormalizedAttendanceForDate(oldDate);
                // Mark normalized attendance for new date
                markNormalizedAttendanceForHoliday(request.getDate());
            }
        }

        if (request.getName() != null) {
            holiday.setName(request.getName().trim());
        }

        if (request.getDescription() != null) {
            holiday.setDescription(request.getDescription().trim());
        }

        if (request.getIsActive() != null) {
            boolean wasActive = holiday.getIsActive();
            holiday.setIsActive(request.getIsActive());
            
            // If status changed, update attendance accordingly
            if (wasActive && !request.getIsActive()) {
                // Deactivated: remove normalized attendance
                removeNormalizedAttendanceForDate(holiday.getDate());
            } else if (!wasActive && request.getIsActive()) {
                // Activated: mark normalized attendance
                markNormalizedAttendanceForHoliday(holiday.getDate());
            }
        }

        holiday = holidayRepository.save(holiday);
        return mapToResponse(holiday);
    }

    @Transactional
    @CacheEvict(value = "holidays", allEntries = true)
    public void deleteHoliday(Long id) {
        Long holidayId = Objects.requireNonNull(id, "Holiday ID cannot be null");
        Holiday holiday = holidayRepository.findById(holidayId)
                .orElseThrow(() -> new ResourceNotFoundException("Holiday not found with id: " + holidayId));

        if (holiday.getDeleted()) {
            throw new ResourceNotFoundException("Holiday not found with id: " + id);
        }

        // Remove normalized attendance if holiday was active
        if (holiday.getIsActive()) {
            removeNormalizedAttendanceForDate(holiday.getDate());
        }

        // Soft delete
        holiday.setDeleted(true);
        holidayRepository.save(holiday);
    }

    @Transactional(readOnly = true)
    public HolidayResponse getHolidayById(Long id) {
        Long holidayId = Objects.requireNonNull(id, "Holiday ID cannot be null");
        Holiday holiday = holidayRepository.findById(holidayId)
                .orElseThrow(() -> new ResourceNotFoundException("Holiday not found with id: " + holidayId));

        if (holiday.getDeleted()) {
            throw new ResourceNotFoundException("Holiday not found with id: " + id);
        }

        return mapToResponse(holiday);
    }

    @Transactional(readOnly = true)
    public HolidayResponse getHolidayByDate(LocalDate date) {
        Holiday holiday = holidayRepository.findByDateAndDeletedFalse(date)
                .orElseThrow(() -> new ResourceNotFoundException("Holiday not found for date: " + date));

        return mapToResponse(holiday);
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "holidays", key = "'all'")
    public List<HolidayResponse> getAllHolidays() {
        return holidayRepository.findByIsActiveTrueAndDeletedFalseOrderByDateAsc()
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<HolidayResponse> getAllHolidaysPaginated(Pageable pageable) {
        Page<Holiday> holidays = holidayRepository.findByIsActiveTrueAndDeletedFalseOrderByDateAsc(pageable);
        return holidays.map(this::mapToResponse);
    }

    @Transactional(readOnly = true)
    public List<HolidayResponse> getHolidaysInRange(LocalDate startDate, LocalDate endDate) {
        return holidayRepository.findActiveHolidaysInRange(startDate, endDate)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "holidays", key = "'upcoming'")
    public List<HolidayResponse> getUpcomingHolidays() {
        LocalDate today = LocalDate.now();
        return holidayRepository.findUpcomingHolidays(today)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Mark normalized attendance for all employees on a holiday date.
     * If the date is Sunday, no attendance is marked (Sunday is already non-working).
     */
    private void markNormalizedAttendanceForHoliday(LocalDate holidayDate) {
        // Check if it's Sunday - no marking needed as Sunday is already non-working
        DayOfWeek dayOfWeek = holidayDate.getDayOfWeek();
        if (dayOfWeek == DayOfWeek.SUNDAY) {
            // Sunday is already a non-working day, no need to mark attendance
            return;
        }

        // Get all active employees
        List<Employee> employees = employeeRepository.findByEmploymentStatusAndDeletedFalse(
                Employee.EmploymentStatus.ACTIVE);

        // Create normalized attendance for each employee
        for (Employee employee : employees) {
            // Check if attendance already exists for this date
            Attendance existingAttendance = attendanceRepository
                    .findByEmployeeAndDate(employee, holidayDate)
                    .orElse(null);

            Attendance attendance;
            if (existingAttendance != null) {
                // Update existing attendance
                attendance = existingAttendance;
            } else {
                // Create new attendance
                attendance = new Attendance();
                attendance.setDeleted(false);
            }

            // Set normalized times
            attendance.setEmployee(employee);
            attendance.setDate(holidayDate);
            attendance.setCheckInTime(holidayDate.atTime(HOLIDAY_CHECK_IN));
            attendance.setLunchOutTime(holidayDate.atTime(HOLIDAY_LUNCH_OUT));
            attendance.setLunchInTime(holidayDate.atTime(HOLIDAY_LUNCH_IN));
            attendance.setCheckOutTime(holidayDate.atTime(HOLIDAY_CHECK_OUT));
            attendance.setStatus(Attendance.AttendanceStatus.PRESENT);
            attendance.setRecognitionMethod("HOLIDAY");
            attendance.setNotes("Holiday: Normalized attendance");

            // Calculate working hours (should be 8 hours)
            AttendanceCalculationService.CalculationResult result = 
                    calculationService.calculateAttendance(attendance);
            attendance.setWorkingHours(result.getWorkingHours());
            attendance.setOvertimeHours(result.getOvertimeHours());

            attendanceRepository.save(attendance);
        }
    }

    /**
     * Remove normalized attendance for a holiday date.
     * Only removes attendance marked with recognitionMethod = "HOLIDAY"
     */
    private void removeNormalizedAttendanceForDate(LocalDate date) {
        // Find all attendance records for this date marked as holiday
        List<Attendance> holidayAttendances = attendanceRepository.findAllByDate(date)
                .stream()
                .filter(a -> "HOLIDAY".equals(a.getRecognitionMethod()))
                .collect(Collectors.toList());

        // Delete these attendance records
        for (Attendance attendance : holidayAttendances) {
            attendance.setDeleted(true);
            attendanceRepository.save(attendance);
        }
    }

    private HolidayResponse mapToResponse(Holiday holiday) {
        HolidayResponse response = new HolidayResponse();
        response.setId(holiday.getId());
        response.setDate(holiday.getDate());
        response.setName(holiday.getName());
        response.setDescription(holiday.getDescription());
        response.setIsActive(holiday.getIsActive());
        response.setCreatedAt(holiday.getCreatedAt());
        response.setUpdatedAt(holiday.getUpdatedAt());
        return response;
    }
}


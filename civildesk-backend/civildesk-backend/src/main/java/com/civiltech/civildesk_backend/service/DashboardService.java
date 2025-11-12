package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.DashboardStatsResponse;
import com.civiltech.civildesk_backend.dto.EmployeeDashboardStatsResponse;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@Transactional
public class DashboardService {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private UserRepository userRepository;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    public DashboardStatsResponse getAdminDashboardStats() {
        DashboardStatsResponse response = new DashboardStatsResponse();

        // Employee Stats
        DashboardStatsResponse.EmployeeStats employeeStats = new DashboardStatsResponse.EmployeeStats();
        long totalEmployees = employeeRepository.count();
        long activeEmployees = employeeRepository.countByEmploymentStatusAndDeletedFalse(Employee.EmploymentStatus.ACTIVE);
        long inactiveEmployees = employeeRepository.countByEmploymentStatusAndDeletedFalse(Employee.EmploymentStatus.INACTIVE);

        // Get employees by type
        List<Employee> allEmployees = employeeRepository.findAll();
        long fullTimeCount = allEmployees.stream()
                .filter(e -> !e.getDeleted() && e.getEmploymentType() == Employee.EmploymentType.FULL_TIME)
                .count();
        long partTimeCount = allEmployees.stream()
                .filter(e -> !e.getDeleted() && e.getEmploymentType() == Employee.EmploymentType.PART_TIME)
                .count();
        long contractCount = allEmployees.stream()
                .filter(e -> !e.getDeleted() && e.getEmploymentType() == Employee.EmploymentType.CONTRACT)
                .count();
        long internCount = allEmployees.stream()
                .filter(e -> !e.getDeleted() && e.getEmploymentType() == Employee.EmploymentType.INTERN)
                .count();

        // New employees this month
        LocalDate firstDayOfMonth = LocalDate.now().withDayOfMonth(1);
        long newEmployeesThisMonth = allEmployees.stream()
                .filter(e -> !e.getDeleted() && 
                        e.getCreatedAt() != null && 
                        e.getCreatedAt().toLocalDate().isAfter(firstDayOfMonth.minusDays(1)))
                .count();

        employeeStats.setTotalEmployees(totalEmployees);
        employeeStats.setActiveEmployees(activeEmployees);
        employeeStats.setInactiveEmployees(inactiveEmployees);
        employeeStats.setNewEmployeesThisMonth(newEmployeesThisMonth);
        employeeStats.setTotalEmployeesByTypeFullTime(fullTimeCount);
        employeeStats.setTotalEmployeesByTypePartTime(partTimeCount);
        employeeStats.setTotalEmployeesByTypeContract(contractCount);
        employeeStats.setTotalEmployeesByTypeIntern(internCount);

        // Department Stats
        DashboardStatsResponse.DepartmentStats departmentStats = new DashboardStatsResponse.DepartmentStats();
        Map<String, Long> departmentMap = allEmployees.stream()
                .filter(e -> !e.getDeleted() && e.getDepartment() != null && !e.getDepartment().isEmpty())
                .collect(Collectors.groupingBy(
                        Employee::getDepartment,
                        Collectors.counting()
                ));

        List<DashboardStatsResponse.DepartmentCount> departmentCounts = departmentMap.entrySet().stream()
                .map(entry -> new DashboardStatsResponse.DepartmentCount(entry.getKey(), entry.getValue()))
                .collect(Collectors.toList());

        departmentStats.setDepartmentCounts(departmentCounts);
        departmentStats.setTotalDepartments((long) departmentMap.size());

        // Attendance Stats (Placeholder - will be implemented in Phase 5)
        DashboardStatsResponse.AttendanceStats attendanceStats = new DashboardStatsResponse.AttendanceStats();
        attendanceStats.setPresentToday(0L);
        attendanceStats.setAbsentToday(0L);
        attendanceStats.setOnLeaveToday(0L);
        attendanceStats.setAttendancePercentageThisMonth(0.0);
        attendanceStats.setWeeklyAttendance(new ArrayList<>());

        // Recent Activity (Placeholder)
        DashboardStatsResponse.RecentActivity recentActivity = new DashboardStatsResponse.RecentActivity();
        recentActivity.setActivities(new ArrayList<>());

        response.setEmployeeStats(employeeStats);
        response.setDepartmentStats(departmentStats);
        response.setAttendanceStats(attendanceStats);
        response.setRecentActivity(recentActivity);

        return response;
    }

    public EmployeeDashboardStatsResponse getEmployeeDashboardStats(Long userId) {
        // Verify user exists
        Long nonNullUserId = Objects.requireNonNull(userId, "User ID cannot be null");
        userRepository.findById(nonNullUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(nonNullUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found"));

        EmployeeDashboardStatsResponse response = new EmployeeDashboardStatsResponse();

        // Personal Info
        EmployeeDashboardStatsResponse.PersonalInfo personalInfo = new EmployeeDashboardStatsResponse.PersonalInfo();
        personalInfo.setEmployeeId(employee.getEmployeeId());
        personalInfo.setFullName(employee.getFirstName() + " " + employee.getLastName());
        personalInfo.setDepartment(employee.getDepartment());
        personalInfo.setDesignation(employee.getDesignation());
        personalInfo.setEmploymentStatus(employee.getEmploymentStatus() != null ? 
                employee.getEmploymentStatus().name() : "ACTIVE");
        personalInfo.setJoiningDate(employee.getJoiningDate() != null ? 
                employee.getJoiningDate().format(DATE_FORMATTER) : null);

        // Attendance Summary (Placeholder - will be implemented in Phase 5)
        EmployeeDashboardStatsResponse.AttendanceSummary attendanceSummary = 
                new EmployeeDashboardStatsResponse.AttendanceSummary();
        attendanceSummary.setDaysPresentThisMonth(0L);
        attendanceSummary.setDaysAbsentThisMonth(0L);
        attendanceSummary.setDaysOnLeaveThisMonth(0L);
        attendanceSummary.setAttendancePercentageThisMonth(0.0);
        attendanceSummary.setCheckedInToday(false);
        attendanceSummary.setCheckInTimeToday(null);
        attendanceSummary.setCheckOutTimeToday(null);
        attendanceSummary.setMonthlyAttendance(new ArrayList<>());

        // Leave Summary (Placeholder - will be implemented in Phase 7)
        EmployeeDashboardStatsResponse.LeaveSummary leaveSummary = 
                new EmployeeDashboardStatsResponse.LeaveSummary();
        leaveSummary.setTotalLeaves(0L);
        leaveSummary.setUsedLeaves(0L);
        leaveSummary.setRemainingLeaves(0L);
        leaveSummary.setPendingLeaveRequests(0L);

        // Upcoming Events (Placeholder)
        EmployeeDashboardStatsResponse.UpcomingEvents upcomingEvents = 
                new EmployeeDashboardStatsResponse.UpcomingEvents();
        upcomingEvents.setEvents(new ArrayList<>());

        response.setPersonalInfo(personalInfo);
        response.setAttendanceSummary(attendanceSummary);
        response.setLeaveSummary(leaveSummary);
        response.setUpcomingEvents(upcomingEvents);

        return response;
    }
}


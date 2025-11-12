package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DashboardStatsResponse {
    private EmployeeStats employeeStats;
    private DepartmentStats departmentStats;
    private AttendanceStats attendanceStats;
    private RecentActivity recentActivity;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EmployeeStats {
        private Long totalEmployees;
        private Long activeEmployees;
        private Long inactiveEmployees;
        private Long newEmployeesThisMonth;
        private Long totalEmployeesByTypeFullTime;
        private Long totalEmployeesByTypePartTime;
        private Long totalEmployeesByTypeContract;
        private Long totalEmployeesByTypeIntern;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DepartmentStats {
        private List<DepartmentCount> departmentCounts;
        private Long totalDepartments;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DepartmentCount {
        private String department;
        private Long count;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AttendanceStats {
        private Long presentToday;
        private Long absentToday;
        private Long onLeaveToday;
        private Double attendancePercentageThisMonth;
        private List<DailyAttendance> weeklyAttendance;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyAttendance {
        private String date;
        private Long present;
        private Long absent;
        private Long onLeave;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RecentActivity {
        private List<ActivityItem> activities;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ActivityItem {
        private String type;
        private String description;
        private String date;
    }
}


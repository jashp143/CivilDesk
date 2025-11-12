package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeDashboardStatsResponse {
    private PersonalInfo personalInfo;
    private AttendanceSummary attendanceSummary;
    private LeaveSummary leaveSummary;
    private UpcomingEvents upcomingEvents;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PersonalInfo {
        private String employeeId;
        private String fullName;
        private String department;
        private String designation;
        private String employmentStatus;
        private String joiningDate;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AttendanceSummary {
        private Long daysPresentThisMonth;
        private Long daysAbsentThisMonth;
        private Long daysOnLeaveThisMonth;
        private Double attendancePercentageThisMonth;
        private Boolean checkedInToday;
        private String checkInTimeToday;
        private String checkOutTimeToday;
        private List<MonthlyAttendance> monthlyAttendance;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MonthlyAttendance {
        private String date;
        private String status; // PRESENT, ABSENT, ON_LEAVE
        private String checkInTime;
        private String checkOutTime;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LeaveSummary {
        private Long totalLeaves;
        private Long usedLeaves;
        private Long remainingLeaves;
        private Long pendingLeaveRequests;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpcomingEvents {
        private List<EventItem> events;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EventItem {
        private String type;
        private String title;
        private String date;
        private String description;
    }
}


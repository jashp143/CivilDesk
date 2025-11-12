class DashboardStats {
  final EmployeeStats employeeStats;
  final DepartmentStats departmentStats;
  final AttendanceStats attendanceStats;
  final RecentActivity recentActivity;

  DashboardStats({
    required this.employeeStats,
    required this.departmentStats,
    required this.attendanceStats,
    required this.recentActivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      employeeStats: EmployeeStats.fromJson(json['employeeStats'] as Map<String, dynamic>),
      departmentStats: DepartmentStats.fromJson(json['departmentStats'] as Map<String, dynamic>),
      attendanceStats: AttendanceStats.fromJson(json['attendanceStats'] as Map<String, dynamic>),
      recentActivity: RecentActivity.fromJson(json['recentActivity'] as Map<String, dynamic>),
    );
  }
}

class EmployeeStats {
  final int totalEmployees;
  final int activeEmployees;
  final int inactiveEmployees;
  final int newEmployeesThisMonth;
  final int totalEmployeesByTypeFullTime;
  final int totalEmployeesByTypePartTime;
  final int totalEmployeesByTypeContract;
  final int totalEmployeesByTypeIntern;

  EmployeeStats({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.inactiveEmployees,
    required this.newEmployeesThisMonth,
    required this.totalEmployeesByTypeFullTime,
    required this.totalEmployeesByTypePartTime,
    required this.totalEmployeesByTypeContract,
    required this.totalEmployeesByTypeIntern,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      totalEmployees: (json['totalEmployees'] as num?)?.toInt() ?? 0,
      activeEmployees: (json['activeEmployees'] as num?)?.toInt() ?? 0,
      inactiveEmployees: (json['inactiveEmployees'] as num?)?.toInt() ?? 0,
      newEmployeesThisMonth: (json['newEmployeesThisMonth'] as num?)?.toInt() ?? 0,
      totalEmployeesByTypeFullTime: (json['totalEmployeesByTypeFullTime'] as num?)?.toInt() ?? 0,
      totalEmployeesByTypePartTime: (json['totalEmployeesByTypePartTime'] as num?)?.toInt() ?? 0,
      totalEmployeesByTypeContract: (json['totalEmployeesByTypeContract'] as num?)?.toInt() ?? 0,
      totalEmployeesByTypeIntern: (json['totalEmployeesByTypeIntern'] as num?)?.toInt() ?? 0,
    );
  }
}

class DepartmentStats {
  final List<DepartmentCount> departmentCounts;
  final int totalDepartments;

  DepartmentStats({
    required this.departmentCounts,
    required this.totalDepartments,
  });

  factory DepartmentStats.fromJson(Map<String, dynamic> json) {
    return DepartmentStats(
      departmentCounts: (json['departmentCounts'] as List<dynamic>?)
              ?.map((e) => DepartmentCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalDepartments: (json['totalDepartments'] as num?)?.toInt() ?? 0,
    );
  }
}

class DepartmentCount {
  final String department;
  final int count;

  DepartmentCount({
    required this.department,
    required this.count,
  });

  factory DepartmentCount.fromJson(Map<String, dynamic> json) {
    return DepartmentCount(
      department: json['department'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceStats {
  final int presentToday;
  final int absentToday;
  final int onLeaveToday;
  final double attendancePercentageThisMonth;
  final List<DailyAttendance> weeklyAttendance;

  AttendanceStats({
    required this.presentToday,
    required this.absentToday,
    required this.onLeaveToday,
    required this.attendancePercentageThisMonth,
    required this.weeklyAttendance,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      presentToday: (json['presentToday'] as num?)?.toInt() ?? 0,
      absentToday: (json['absentToday'] as num?)?.toInt() ?? 0,
      onLeaveToday: (json['onLeaveToday'] as num?)?.toInt() ?? 0,
      attendancePercentageThisMonth: (json['attendancePercentageThisMonth'] as num?)?.toDouble() ?? 0.0,
      weeklyAttendance: (json['weeklyAttendance'] as List<dynamic>?)
              ?.map((e) => DailyAttendance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DailyAttendance {
  final String date;
  final int present;
  final int absent;
  final int onLeave;

  DailyAttendance({
    required this.date,
    required this.present,
    required this.absent,
    required this.onLeave,
  });

  factory DailyAttendance.fromJson(Map<String, dynamic> json) {
    return DailyAttendance(
      date: json['date'] as String? ?? '',
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      onLeave: (json['onLeave'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecentActivity {
  final List<ActivityItem> activities;

  RecentActivity({
    required this.activities,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ActivityItem {
  final String type;
  final String description;
  final String date;

  ActivityItem({
    required this.type,
    required this.description,
    required this.date,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }
}

// Employee Dashboard Models
class EmployeeDashboardStats {
  final PersonalInfo personalInfo;
  final AttendanceSummary attendanceSummary;
  final LeaveSummary leaveSummary;
  final UpcomingEvents upcomingEvents;

  EmployeeDashboardStats({
    required this.personalInfo,
    required this.attendanceSummary,
    required this.leaveSummary,
    required this.upcomingEvents,
  });

  factory EmployeeDashboardStats.fromJson(Map<String, dynamic> json) {
    return EmployeeDashboardStats(
      personalInfo: PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>),
      attendanceSummary: AttendanceSummary.fromJson(json['attendanceSummary'] as Map<String, dynamic>),
      leaveSummary: LeaveSummary.fromJson(json['leaveSummary'] as Map<String, dynamic>),
      upcomingEvents: UpcomingEvents.fromJson(json['upcomingEvents'] as Map<String, dynamic>),
    );
  }
}

class PersonalInfo {
  final String employeeId;
  final String fullName;
  final String department;
  final String designation;
  final String employmentStatus;
  final String? joiningDate;

  PersonalInfo({
    required this.employeeId,
    required this.fullName,
    required this.department,
    required this.designation,
    required this.employmentStatus,
    this.joiningDate,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      employeeId: json['employeeId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      department: json['department'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      employmentStatus: json['employmentStatus'] as String? ?? '',
      joiningDate: json['joiningDate'] as String?,
    );
  }
}

class AttendanceSummary {
  final int daysPresentThisMonth;
  final int daysAbsentThisMonth;
  final int daysOnLeaveThisMonth;
  final double attendancePercentageThisMonth;
  final bool checkedInToday;
  final String? checkInTimeToday;
  final String? checkOutTimeToday;
  final List<MonthlyAttendance> monthlyAttendance;

  AttendanceSummary({
    required this.daysPresentThisMonth,
    required this.daysAbsentThisMonth,
    required this.daysOnLeaveThisMonth,
    required this.attendancePercentageThisMonth,
    required this.checkedInToday,
    this.checkInTimeToday,
    this.checkOutTimeToday,
    required this.monthlyAttendance,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      daysPresentThisMonth: (json['daysPresentThisMonth'] as num?)?.toInt() ?? 0,
      daysAbsentThisMonth: (json['daysAbsentThisMonth'] as num?)?.toInt() ?? 0,
      daysOnLeaveThisMonth: (json['daysOnLeaveThisMonth'] as num?)?.toInt() ?? 0,
      attendancePercentageThisMonth: (json['attendancePercentageThisMonth'] as num?)?.toDouble() ?? 0.0,
      checkedInToday: json['checkedInToday'] as bool? ?? false,
      checkInTimeToday: json['checkInTimeToday'] as String?,
      checkOutTimeToday: json['checkOutTimeToday'] as String?,
      monthlyAttendance: (json['monthlyAttendance'] as List<dynamic>?)
              ?.map((e) => MonthlyAttendance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MonthlyAttendance {
  final String date;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;

  MonthlyAttendance({
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
  });

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendance(
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      checkInTime: json['checkInTime'] as String?,
      checkOutTime: json['checkOutTime'] as String?,
    );
  }
}

class LeaveSummary {
  final int totalLeaves;
  final int usedLeaves;
  final int remainingLeaves;
  final int pendingLeaveRequests;

  LeaveSummary({
    required this.totalLeaves,
    required this.usedLeaves,
    required this.remainingLeaves,
    required this.pendingLeaveRequests,
  });

  factory LeaveSummary.fromJson(Map<String, dynamic> json) {
    return LeaveSummary(
      totalLeaves: (json['totalLeaves'] as num?)?.toInt() ?? 0,
      usedLeaves: (json['usedLeaves'] as num?)?.toInt() ?? 0,
      remainingLeaves: (json['remainingLeaves'] as num?)?.toInt() ?? 0,
      pendingLeaveRequests: (json['pendingLeaveRequests'] as num?)?.toInt() ?? 0,
    );
  }
}

class UpcomingEvents {
  final List<EventItem> events;

  UpcomingEvents({
    required this.events,
  });

  factory UpcomingEvents.fromJson(Map<String, dynamic> json) {
    return UpcomingEvents(
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => EventItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EventItem {
  final String type;
  final String title;
  final String date;
  final String description;

  EventItem({
    required this.type,
    required this.title,
    required this.date,
    required this.description,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}


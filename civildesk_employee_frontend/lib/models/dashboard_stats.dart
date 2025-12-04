class EmployeeDashboardStats {
  final PersonalInfo personalInfo;
  final AttendanceSummary attendanceSummary;
  final LeaveSummary leaveSummary;
  final List<MonthlyAttendance> monthlyAttendance;
  final UpcomingEvents upcomingEvents;

  EmployeeDashboardStats({
    required this.personalInfo,
    required this.attendanceSummary,
    required this.leaveSummary,
    required this.monthlyAttendance,
    required this.upcomingEvents,
  });

  factory EmployeeDashboardStats.fromJson(Map<String, dynamic> json) {
    return EmployeeDashboardStats(
      personalInfo: PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>),
      attendanceSummary: AttendanceSummary.fromJson(json['attendanceSummary'] as Map<String, dynamic>),
      leaveSummary: LeaveSummary.fromJson(json['leaveSummary'] as Map<String, dynamic>),
      monthlyAttendance: (json['monthlyAttendance'] as List<dynamic>)
          .map((e) => MonthlyAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingEvents: UpcomingEvents.fromJson(json['upcomingEvents'] as Map<String, dynamic>),
    );
  }
}

class PersonalInfo {
  final String name;
  final String employeeCode;
  final String department;
  final String designation;
  final String email;

  PersonalInfo({
    required this.name,
    required this.employeeCode,
    required this.department,
    required this.designation,
    required this.email,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      name: json['name'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      department: json['department'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class AttendanceSummary {
  final int totalPresent;
  final int totalAbsent;
  final int totalLeaves;
  final double attendancePercentage;
  final int workingDays;

  AttendanceSummary({
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLeaves,
    required this.attendancePercentage,
    required this.workingDays,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalPresent: json['totalPresent'] as int? ?? 0,
      totalAbsent: json['totalAbsent'] as int? ?? 0,
      totalLeaves: json['totalLeaves'] as int? ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      workingDays: json['workingDays'] as int? ?? 0,
    );
  }
}

class LeaveSummary {
  final int totalLeaves;
  final int usedLeaves;
  final int remainingLeaves;
  final int pendingRequests;

  LeaveSummary({
    required this.totalLeaves,
    required this.usedLeaves,
    required this.remainingLeaves,
    required this.pendingRequests,
  });

  factory LeaveSummary.fromJson(Map<String, dynamic> json) {
    return LeaveSummary(
      totalLeaves: json['totalLeaves'] as int? ?? 0,
      usedLeaves: json['usedLeaves'] as int? ?? 0,
      remainingLeaves: json['remainingLeaves'] as int? ?? 0,
      pendingRequests: json['pendingRequests'] as int? ?? 0,
    );
  }
}

class MonthlyAttendance {
  final String month;
  final int present;
  final int absent;
  final int leaves;

  MonthlyAttendance({
    required this.month,
    required this.present,
    required this.absent,
    required this.leaves,
  });

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendance(
      month: json['month'] as String? ?? '',
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      leaves: json['leaves'] as int? ?? 0,
    );
  }
}

class UpcomingEvents {
  final List<EventItem> events;

  UpcomingEvents({required this.events});

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
  final String title;
  final DateTime date;
  final String type;

  EventItem({
    required this.title,
    required this.date,
    required this.type,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      title: json['title'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String? ?? '',
    );
  }
}


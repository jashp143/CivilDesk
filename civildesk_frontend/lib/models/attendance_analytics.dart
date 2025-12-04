class AttendanceAnalytics {
  final String employeeId;
  final String employeeName;
  final String department;
  final DateTime startDate;
  final DateTime endDate;
  final double totalWorkingHours;
  final double totalOvertimeHours;
  final double attendancePercentage;
  final int totalDaysPresent;
  final int totalWorkingDays;
  final int totalAbsentDays;
  final int totalLateDays;
  final List<DailyAttendanceLog> dailyLogs;

  AttendanceAnalytics({
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.startDate,
    required this.endDate,
    required this.totalWorkingHours,
    required this.totalOvertimeHours,
    required this.attendancePercentage,
    required this.totalDaysPresent,
    required this.totalWorkingDays,
    required this.totalAbsentDays,
    required this.totalLateDays,
    required this.dailyLogs,
  });

  factory AttendanceAnalytics.fromJson(Map<String, dynamic> json) {
    return AttendanceAnalytics(
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      department: json['department'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalWorkingHours: (json['totalWorkingHours'] ?? 0).toDouble(),
      totalOvertimeHours: (json['totalOvertimeHours'] ?? 0).toDouble(),
      attendancePercentage: (json['attendancePercentage'] ?? 0).toDouble(),
      totalDaysPresent: json['totalDaysPresent'] ?? 0,
      totalWorkingDays: json['totalWorkingDays'] ?? 0,
      totalAbsentDays: json['totalAbsentDays'] ?? 0,
      totalLateDays: json['totalLateDays'] ?? 0,
      dailyLogs: (json['dailyLogs'] as List<dynamic>?)
              ?.map((log) => DailyAttendanceLog.fromJson(log))
              .toList() ??
          [],
    );
  }
}

class DailyAttendanceLog {
  final int? attendanceId;
  final DateTime date;
  final String dayOfWeek;
  final DateTime? checkInTime;
  final DateTime? lunchOutTime;
  final DateTime? lunchInTime;
  final DateTime? checkOutTime;
  final String status;
  final double? workingHours;
  final double? overtimeHours;
  final bool isLate;
  final String? notes;

  DailyAttendanceLog({
    this.attendanceId,
    required this.date,
    required this.dayOfWeek,
    this.checkInTime,
    this.lunchOutTime,
    this.lunchInTime,
    this.checkOutTime,
    required this.status,
    this.workingHours,
    this.overtimeHours,
    required this.isLate,
    this.notes,
  });

  factory DailyAttendanceLog.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceLog(
      attendanceId: json['attendanceId'],
      date: DateTime.parse(json['date']),
      dayOfWeek: json['dayOfWeek'] ?? '',
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      lunchOutTime: json['lunchOutTime'] != null
          ? DateTime.parse(json['lunchOutTime'])
          : null,
      lunchInTime: json['lunchInTime'] != null
          ? DateTime.parse(json['lunchInTime'])
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      status: json['status'] ?? 'ABSENT',
      workingHours: json['workingHours'] != null
          ? (json['workingHours'] as num).toDouble()
          : null,
      overtimeHours: json['overtimeHours'] != null
          ? (json['overtimeHours'] as num).toDouble()
          : null,
      isLate: json['isLate'] ?? false,
      notes: json['notes'],
    );
  }
}


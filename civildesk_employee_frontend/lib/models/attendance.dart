class Attendance {
  final int? id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime? lunchOutTime;
  final DateTime? lunchInTime;
  final String status;
  final String? remarks;
  final Duration? workDuration;
  final double? workingHours; // Office working hours from backend (always <= 8 hours)
  final double? overtimeHours; // Overtime hours from backend

  Attendance({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.lunchOutTime,
    this.lunchInTime,
    required this.status,
    this.remarks,
    this.workDuration,
    this.workingHours,
    this.overtimeHours,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as int?,
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime'] as String) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime'] as String) : null,
      lunchOutTime: json['lunchOutTime'] != null ? DateTime.parse(json['lunchOutTime'] as String) : null,
      lunchInTime: json['lunchInTime'] != null ? DateTime.parse(json['lunchInTime'] as String) : null,
      status: json['status'] as String? ?? '',
      remarks: json['remarks'] as String?,
      workDuration: json['workDuration'] != null
          ? Duration(milliseconds: json['workDuration'] as int)
          : null,
      workingHours: json['workingHours'] != null
          ? (json['workingHours'] as num).toDouble()
          : json['working_hours'] != null
              ? (json['working_hours'] as num).toDouble()
              : null,
      overtimeHours: json['overtimeHours'] != null
          ? (json['overtimeHours'] as num).toDouble()
          : json['overtime_hours'] != null
              ? (json['overtime_hours'] as num).toDouble()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'lunchOutTime': lunchOutTime?.toIso8601String(),
      'lunchInTime': lunchInTime?.toIso8601String(),
      'status': status,
      'remarks': remarks,
      'workDuration': workDuration?.inMilliseconds,
      'workingHours': workingHours,
      'overtimeHours': overtimeHours,
    };
  }

  /// Get formatted working hours string from backend calculated value
  String? get formattedWorkingHours {
    if (workingHours == null) return null;
    final hours = workingHours!.floor();
    final minutes = ((workingHours! - hours) * 60).round();
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  /// Get formatted overtime hours string from backend calculated value
  String? get formattedOvertimeHours {
    if (overtimeHours == null || overtimeHours == 0) return null;
    final hours = overtimeHours!.floor();
    final minutes = ((overtimeHours! - hours) * 60).round();
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }
}


class Leave {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final String employeeIdStr;
  final String? department;
  final String? designation;
  final LeaveType leaveType;
  final String leaveTypeDisplay;
  final DateTime startDate;
  final DateTime endDate;
  final bool isHalfDay;
  final HalfDayPeriod? halfDayPeriod;
  final String? halfDayPeriodDisplay;
  final String contactNumber;
  final List<HandoverEmployee>? handoverEmployees;
  final String reason;
  final String? medicalCertificateUrl;
  final LeaveStatus status;
  final String statusDisplay;
  final double totalDays;
  final Reviewer? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final bool hasConflicts;
  final List<ConflictInfo>? conflicts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Leave({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeeIdStr,
    this.department,
    this.designation,
    required this.leaveType,
    required this.leaveTypeDisplay,
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    this.halfDayPeriod,
    this.halfDayPeriodDisplay,
    required this.contactNumber,
    this.handoverEmployees,
    required this.reason,
    this.medicalCertificateUrl,
    required this.status,
    required this.statusDisplay,
    required this.totalDays,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    this.hasConflicts = false,
    this.conflicts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeEmail: json['employeeEmail'],
      employeeIdStr: json['employeeId_str'] ?? '',
      department: json['department'],
      designation: json['designation'],
      leaveType: LeaveType.values.firstWhere(
        (e) => e.toString().split('.').last == json['leaveType'],
      ),
      leaveTypeDisplay: json['leaveTypeDisplay'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isHalfDay: json['isHalfDay'],
      halfDayPeriod: json['halfDayPeriod'] != null
          ? HalfDayPeriod.values.firstWhere(
              (e) => e.toString().split('.').last == json['halfDayPeriod'],
            )
          : null,
      halfDayPeriodDisplay: json['halfDayPeriodDisplay'],
      contactNumber: json['contactNumber'],
      handoverEmployees: json['handoverEmployees'] != null
          ? (json['handoverEmployees'] as List)
              .map((e) => HandoverEmployee.fromJson(e))
              .toList()
          : null,
      reason: json['reason'],
      medicalCertificateUrl: json['medicalCertificateUrl'],
      status: LeaveStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      statusDisplay: json['statusDisplay'],
      totalDays: json['totalDays']?.toDouble() ?? 0.0,
      reviewedBy: json['reviewedBy'] != null
          ? Reviewer.fromJson(json['reviewedBy'])
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      reviewNote: json['reviewNote'],
      hasConflicts: json['hasConflicts'] ?? false,
      conflicts: json['conflicts'] != null
          ? (json['conflicts'] as List)
              .map((e) => ConflictInfo.fromJson(e))
              .toList()
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeEmail': employeeEmail,
      'employeeId_str': employeeIdStr,
      'department': department,
      'designation': designation,
      'leaveType': leaveType.toString().split('.').last,
      'leaveTypeDisplay': leaveTypeDisplay,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'isHalfDay': isHalfDay,
      'halfDayPeriod': halfDayPeriod?.toString().split('.').last,
      'halfDayPeriodDisplay': halfDayPeriodDisplay,
      'contactNumber': contactNumber,
      'handoverEmployees': handoverEmployees?.map((e) => e.toJson()).toList(),
      'reason': reason,
      'medicalCertificateUrl': medicalCertificateUrl,
      'status': status.toString().split('.').last,
      'statusDisplay': statusDisplay,
      'totalDays': totalDays,
      'reviewedBy': reviewedBy?.toJson(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNote': reviewNote,
      'hasConflicts': hasConflicts,
      'conflicts': conflicts?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ConflictInfo {
  final int employeeId;
  final String employeeName;
  final String employeeIdStr;
  final DateTime leaveStartDate;
  final DateTime leaveEndDate;
  final String leaveType;
  final String conflictType;

  ConflictInfo({
    required this.employeeId,
    required this.employeeName,
    required this.employeeIdStr,
    required this.leaveStartDate,
    required this.leaveEndDate,
    required this.leaveType,
    required this.conflictType,
  });

  factory ConflictInfo.fromJson(Map<String, dynamic> json) {
    return ConflictInfo(
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeIdStr: json['employeeId_str'],
      leaveStartDate: DateTime.parse(json['leaveStartDate']),
      leaveEndDate: DateTime.parse(json['leaveEndDate']),
      leaveType: json['leaveType'],
      conflictType: json['conflictType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeId_str': employeeIdStr,
      'leaveStartDate': leaveStartDate.toIso8601String().split('T')[0],
      'leaveEndDate': leaveEndDate.toIso8601String().split('T')[0],
      'leaveType': leaveType,
      'conflictType': conflictType,
    };
  }
}

class HandoverEmployee {
  final int id;
  final String name;
  final String employeeId;
  final String? designation;
  final String email;

  HandoverEmployee({
    required this.id,
    required this.name,
    required this.employeeId,
    this.designation,
    required this.email,
  });

  factory HandoverEmployee.fromJson(Map<String, dynamic> json) {
    return HandoverEmployee(
      id: json['id'],
      name: json['name'],
      employeeId: json['employeeId'],
      designation: json['designation'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeId': employeeId,
      'designation': designation,
      'email': email,
    };
  }
}

class Reviewer {
  final int id;
  final String name;
  final String email;
  final String role;

  Reviewer({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory Reviewer.fromJson(Map<String, dynamic> json) {
    return Reviewer(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}

enum LeaveType {
  SICK_LEAVE,
  CASUAL_LEAVE,
  ANNUAL_LEAVE,
  MATERNITY_LEAVE,
  PATERNITY_LEAVE,
  MEDICAL_LEAVE,
  EMERGENCY_LEAVE,
  UNPAID_LEAVE,
  COMPENSATORY_OFF,
}

extension LeaveTypeExtension on LeaveType {
  String get displayName {
    switch (this) {
      case LeaveType.SICK_LEAVE:
        return 'Sick Leave';
      case LeaveType.CASUAL_LEAVE:
        return 'Casual Leave';
      case LeaveType.ANNUAL_LEAVE:
        return 'Annual Leave';
      case LeaveType.MATERNITY_LEAVE:
        return 'Maternity Leave';
      case LeaveType.PATERNITY_LEAVE:
        return 'Paternity Leave';
      case LeaveType.MEDICAL_LEAVE:
        return 'Medical Leave';
      case LeaveType.EMERGENCY_LEAVE:
        return 'Emergency Leave';
      case LeaveType.UNPAID_LEAVE:
        return 'Unpaid Leave';
      case LeaveType.COMPENSATORY_OFF:
        return 'Compensatory Off';
    }
  }
}

enum HalfDayPeriod {
  FIRST_HALF,
  SECOND_HALF,
}

extension HalfDayPeriodExtension on HalfDayPeriod {
  String get displayName {
    switch (this) {
      case HalfDayPeriod.FIRST_HALF:
        return 'First Half - Morning';
      case HalfDayPeriod.SECOND_HALF:
        return 'Second Half - Afternoon';
    }
  }
}

enum LeaveStatus {
  PENDING,
  APPROVED,
  REJECTED,
  CANCELLED,
}

extension LeaveStatusExtension on LeaveStatus {
  String get displayName {
    switch (this) {
      case LeaveStatus.PENDING:
        return 'Pending';
      case LeaveStatus.APPROVED:
        return 'Approved';
      case LeaveStatus.REJECTED:
        return 'Rejected';
      case LeaveStatus.CANCELLED:
        return 'Cancelled';
    }
  }
}

class LeaveRequest {
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isHalfDay;
  final HalfDayPeriod? halfDayPeriod;
  final String contactNumber;
  final List<int>? handoverEmployeeIds;
  final String reason;
  final String? medicalCertificateUrl;

  LeaveRequest({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    this.halfDayPeriod,
    required this.contactNumber,
    this.handoverEmployeeIds,
    required this.reason,
    this.medicalCertificateUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'leaveType': leaveType.toString().split('.').last,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'isHalfDay': isHalfDay,
      'halfDayPeriod': halfDayPeriod?.toString().split('.').last,
      'contactNumber': contactNumber,
      'handoverEmployeeIds': handoverEmployeeIds,
      'reason': reason,
      'medicalCertificateUrl': medicalCertificateUrl,
    };
  }
}

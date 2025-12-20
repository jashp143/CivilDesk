class Overtime {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final String employeeIdStr;
  final String? department;
  final String? designation;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String reason;
  final OvertimeStatus status;
  final String statusDisplay;
  final Reviewer? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Overtime({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeeIdStr,
    this.department,
    this.designation,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.status,
    required this.statusDisplay,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Overtime.fromJson(Map<String, dynamic> json) {
    return Overtime(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeEmail: json['employeeEmail'],
      employeeIdStr: json['employeeId_str'] ?? '',
      department: json['department'],
      designation: json['designation'],
      date: DateTime.parse(json['date']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      reason: json['reason'],
      status: OvertimeStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OvertimeStatus.PENDING,
      ),
      statusDisplay: json['statusDisplay'],
      reviewedBy: json['reviewedBy'] != null
          ? Reviewer.fromJson(json['reviewedBy'])
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      reviewNote: json['reviewNote'],
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
      'date': date.toIso8601String().split('T')[0],
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
      'status': status.toString().split('.').last,
      'statusDisplay': statusDisplay,
      'reviewedBy': reviewedBy?.toJson(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNote': reviewNote,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ignore: constant_identifier_names
enum OvertimeStatus {
  PENDING,
  APPROVED,
  REJECTED;

  String get displayName {
    switch (this) {
      case OvertimeStatus.PENDING:
        return 'Pending';
      case OvertimeStatus.APPROVED:
        return 'Approved';
      case OvertimeStatus.REJECTED:
        return 'Rejected';
    }
  }

  static OvertimeStatus fromString(String value) {
    return OvertimeStatus.values.firstWhere(
      (e) => e.toString().split('.').last == value.toUpperCase(),
      orElse: () => OvertimeStatus.PENDING,
    );
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

class OvertimeReviewRequest {
  final OvertimeStatus status;
  final String? reviewNote;

  OvertimeReviewRequest({
    required this.status,
    this.reviewNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.toString().split('.').last,
      'reviewNote': reviewNote,
    };
  }
}

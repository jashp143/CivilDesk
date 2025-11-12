class Attendance {
  final int? id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? lunchOutTime;
  final DateTime? lunchInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final String? recognitionMethod;
  final double? faceRecognitionConfidence;
  final String? notes;

  Attendance({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.checkInTime,
    this.lunchOutTime,
    this.lunchInTime,
    this.checkOutTime,
    required this.status,
    this.recognitionMethod,
    this.faceRecognitionConfidence,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as int?,
      employeeId: json['employeeId'] as String? ?? json['employee_id'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? json['employee_name'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      checkInTime: json['checkInTime'] != null || json['check_in_time'] != null
          ? DateTime.parse(
              (json['checkInTime'] ?? json['check_in_time']) as String)
          : null,
      lunchOutTime: json['lunchOutTime'] != null || json['lunch_out_time'] != null
          ? DateTime.parse(
              (json['lunchOutTime'] ?? json['lunch_out_time']) as String)
          : null,
      lunchInTime: json['lunchInTime'] != null || json['lunch_in_time'] != null
          ? DateTime.parse(
              (json['lunchInTime'] ?? json['lunch_in_time']) as String)
          : null,
      checkOutTime: json['checkOutTime'] != null || json['check_out_time'] != null
          ? DateTime.parse(
              (json['checkOutTime'] ?? json['check_out_time']) as String)
          : null,
      status: AttendanceStatus.fromString(
          json['status'] as String? ?? 'PRESENT'),
      recognitionMethod: json['recognitionMethod'] as String? ??
          json['recognition_method'] as String?,
      faceRecognitionConfidence: json['faceRecognitionConfidence'] != null
          ? (json['faceRecognitionConfidence'] as num).toDouble()
          : json['face_recognition_confidence'] != null
              ? (json['face_recognition_confidence'] as num).toDouble()
              : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date.toIso8601String().split('T')[0],
      'checkInTime': checkInTime?.toIso8601String(),
      'lunchOutTime': lunchOutTime?.toIso8601String(),
      'lunchInTime': lunchInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status.name,
      'recognitionMethod': recognitionMethod,
      'faceRecognitionConfidence': faceRecognitionConfidence,
      'notes': notes,
    };
  }

  String get formattedCheckInTime {
    if (checkInTime == null) return 'N/A';
    return '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCheckOutTime {
    if (checkOutTime == null) return 'N/A';
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }

  String? get workingHours {
    if (checkInTime == null || checkOutTime == null) return null;
    final duration = checkOutTime!.difference(checkInTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

enum AttendanceStatus {
  present,
  absent,
  onLeave,
  halfDay,
  late;

  static AttendanceStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'ON_LEAVE':
        return AttendanceStatus.onLeave;
      case 'HALF_DAY':
        return AttendanceStatus.halfDay;
      case 'LATE':
        return AttendanceStatus.late;
      default:
        return AttendanceStatus.present;
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.onLeave:
        return 'On Leave';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}


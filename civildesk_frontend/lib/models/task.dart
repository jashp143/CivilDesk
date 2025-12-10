class Task {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String description;
  final String modeOfTravel;
  final String modeOfTravelDisplay;
  final TaskStatus status;
  final String statusDisplay;
  final AssignedByInfo assignedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final List<AssignedEmployeeInfo> assignedEmployees;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.description,
    required this.modeOfTravel,
    required this.modeOfTravelDisplay,
    required this.status,
    required this.statusDisplay,
    required this.assignedBy,
    this.reviewedAt,
    this.reviewNote,
    required this.assignedEmployees,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      location: json['location'],
      description: json['description'],
      modeOfTravel: json['modeOfTravel'] ?? json['modeOfTravelDisplay'] ?? '',
      modeOfTravelDisplay: json['modeOfTravelDisplay'] ?? json['modeOfTravel'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (json['status']?.toString().toLowerCase() ?? ''),
        orElse: () => TaskStatus.pending,
      ),
      statusDisplay: json['statusDisplay'],
      assignedBy: AssignedByInfo.fromJson(json['assignedBy']),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      reviewNote: json['reviewNote'],
      assignedEmployees: (json['assignedEmployees'] as List)
          .map((e) => AssignedEmployeeInfo.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'location': location,
      'description': description,
      'modeOfTravel': modeOfTravel,
      'modeOfTravelDisplay': modeOfTravelDisplay,
      'status': status.toString().split('.').last,
      'statusDisplay': statusDisplay,
      'assignedBy': assignedBy.toJson(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNote': reviewNote,
      'assignedEmployees': assignedEmployees.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class AssignedByInfo {
  final int id;
  final String name;
  final String email;
  final String role;

  AssignedByInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AssignedByInfo.fromJson(Map<String, dynamic> json) {
    return AssignedByInfo(
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

class AssignedEmployeeInfo {
  final int id;
  final String name;
  final String employeeId;
  final String email;
  final String? designation;
  final String? department;

  AssignedEmployeeInfo({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.email,
    this.designation,
    this.department,
  });

  factory AssignedEmployeeInfo.fromJson(Map<String, dynamic> json) {
    return AssignedEmployeeInfo(
      id: json['id'],
      name: json['name'],
      employeeId: json['employeeId'],
      email: json['email'],
      designation: json['designation'],
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeId': employeeId,
      'email': email,
      'designation': designation,
      'department': department,
    };
  }
}

class TaskRequest {
  final List<int> employeeIds;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String description;
  final String modeOfTravel;

  TaskRequest({
    required this.employeeIds,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.description,
    required this.modeOfTravel,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeIds': employeeIds,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'location': location,
      'description': description,
      'modeOfTravel': modeOfTravel,
    };
  }
}

enum TaskStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String displayName;
  const TaskStatus(this.displayName);
}

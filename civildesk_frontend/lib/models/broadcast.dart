class BroadcastMessage {
  final int? id;
  final String title;
  final String message;
  final String priority;
  final String priorityDisplay;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CreatorInfo? createdBy;
  final CreatorInfo? updatedBy;

  BroadcastMessage({
    this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.priorityDisplay,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'NORMAL',
      priorityDisplay: json['priorityDisplay'] ?? 'Normal',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'] != null ? CreatorInfo.fromJson(json['createdBy']) : null,
      updatedBy: json['updatedBy'] != null ? CreatorInfo.fromJson(json['updatedBy']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'message': message,
      'priority': priority,
      'isActive': isActive,
    };
  }

  bool get isUrgent => priority == 'URGENT';
  bool get isHigh => priority == 'HIGH';
  bool get isLow => priority == 'LOW';
}

class CreatorInfo {
  final int id;
  final String name;
  final String email;
  final String role;

  CreatorInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory CreatorInfo.fromJson(Map<String, dynamic> json) {
    return CreatorInfo(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}


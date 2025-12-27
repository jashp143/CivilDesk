class NotificationModel {
  final int? id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  // Helper methods
  String get iconName {
    switch (type) {
      case 'TASK_ASSIGNED':
      case 'TASK_STATUS_CHANGED':
        return 'task';
      case 'LEAVE_REQUEST':
      case 'LEAVE_APPROVED':
      case 'LEAVE_REJECTED':
      case 'ASSIGNED_RESPONSIBILITY':
        return 'leave';
      case 'EXPENSE_REQUEST':
      case 'EXPENSE_APPROVED':
      case 'EXPENSE_REJECTED':
        return 'expense';
      case 'OVERTIME_REQUEST':
      case 'OVERTIME_APPROVED':
      case 'OVERTIME_REJECTED':
        return 'overtime';
      case 'FINALIZED_SALARY_SLIPS':
        return 'salary';
      default:
        return 'notification';
    }
  }

  bool get isPositive {
    return type.contains('APPROVED') || 
           type == 'TASK_ASSIGNED' || 
           type == 'FINALIZED_SALARY_SLIPS';
  }

  bool get isNegative {
    return type.contains('REJECTED');
  }
}


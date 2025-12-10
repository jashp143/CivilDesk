class Expense {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final String employeeIdStr;
  final String? department;
  final String? designation;
  final DateTime expenseDate;
  final ExpenseCategory category;
  final String categoryDisplay;
  final double amount;
  final String description;
  final List<String>? receiptUrls;
  final ExpenseStatus status;
  final String statusDisplay;
  final Reviewer? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeeIdStr,
    this.department,
    this.designation,
    required this.expenseDate,
    required this.category,
    required this.categoryDisplay,
    required this.amount,
    required this.description,
    this.receiptUrls,
    required this.status,
    required this.statusDisplay,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeEmail: json['employeeEmail'],
      employeeIdStr: json['employeeId_str'] ?? '',
      department: json['department'],
      designation: json['designation'],
      expenseDate: DateTime.parse(json['expenseDate']),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
      ),
      categoryDisplay: json['categoryDisplay'],
      amount: json['amount']?.toDouble() ?? 0.0,
      description: json['description'],
      receiptUrls: json['receiptUrls'] != null
          ? (json['receiptUrls'] as List).map((e) => e.toString()).toList()
          : null,
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
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
      'expenseDate': expenseDate.toIso8601String().split('T')[0],
      'category': category.toString().split('.').last,
      'categoryDisplay': categoryDisplay,
      'amount': amount,
      'description': description,
      'receiptUrls': receiptUrls,
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

enum ExpenseCategory {
  TRAVEL,
  MEALS,
  ACCOMMODATION,
  SUPPLIES,
  EQUIPMENT,
  COMMUNICATION,
  TRANSPORTATION,
  ENTERTAINMENT,
  TRAINING,
  OTHER,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.TRAVEL:
        return 'Travel';
      case ExpenseCategory.MEALS:
        return 'Meals';
      case ExpenseCategory.ACCOMMODATION:
        return 'Accommodation';
      case ExpenseCategory.SUPPLIES:
        return 'Supplies';
      case ExpenseCategory.EQUIPMENT:
        return 'Equipment';
      case ExpenseCategory.COMMUNICATION:
        return 'Communication';
      case ExpenseCategory.TRANSPORTATION:
        return 'Transportation';
      case ExpenseCategory.ENTERTAINMENT:
        return 'Entertainment';
      case ExpenseCategory.TRAINING:
        return 'Training';
      case ExpenseCategory.OTHER:
        return 'Other';
    }
  }
}

enum ExpenseStatus {
  PENDING,
  APPROVED,
  REJECTED,
}

extension ExpenseStatusExtension on ExpenseStatus {
  String get displayName {
    switch (this) {
      case ExpenseStatus.PENDING:
        return 'Pending';
      case ExpenseStatus.APPROVED:
        return 'Approved';
      case ExpenseStatus.REJECTED:
        return 'Rejected';
    }
  }

  String get color {
    switch (this) {
      case ExpenseStatus.PENDING:
        return '#FFA500'; // Orange
      case ExpenseStatus.APPROVED:
        return '#4CAF50'; // Green
      case ExpenseStatus.REJECTED:
        return '#F44336'; // Red
    }
  }
}

class ExpenseRequest {
  final DateTime expenseDate;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final List<String>? receiptUrls;

  ExpenseRequest({
    required this.expenseDate,
    required this.category,
    required this.amount,
    required this.description,
    this.receiptUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      'expenseDate': expenseDate.toIso8601String().split('T')[0],
      'category': category.toString().split('.').last,
      'amount': amount,
      'description': description,
      'receiptUrls': receiptUrls,
    };
  }
}

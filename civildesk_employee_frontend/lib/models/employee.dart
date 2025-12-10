class Employee {
  final int id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String email;
  final String? phoneNumber;
  final String? department;
  final String? designation;

  Employee({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.email,
    this.phoneNumber,
    this.department,
    this.designation,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      employeeId: json['employeeId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      middleName: json['middleName'],
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      department: json['department'],
      designation: json['designation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'email': email,
      'phoneNumber': phoneNumber,
      'department': department,
      'designation': designation,
    };
  }
}

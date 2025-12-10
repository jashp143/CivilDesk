class Employee {
  final int? id;
  final String employeeId;
  final int? userId;
  
  // Personal Information
  final String firstName;
  final String lastName;
  final String? middleName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final MaritalStatus? maritalStatus;
  final String? bloodGroup;
  final String? profilePhotoUrl;
  
  // Contact Information
  final String email;
  final String phoneNumber;
  final String? alternatePhoneNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;
  
  // Identification Documents
  final String aadharNumber;
  final String panNumber;
  final String? uanNumber;
  final String? esicNumber;
  
  // Work Information
  final String? department;
  final String? designation;
  final DateTime? joiningDate;
  final EmploymentType? employmentType;
  final int? reportingManagerId;
  final String? reportingManagerName;
  final EmploymentStatus? employmentStatus;
  final String? workLocation;
  
  // Salary Information
  final double? basicSalary;
  final double? houseRentAllowance;
  final double? conveyance;
  final double? uniformAndSafety;
  final double? bonus;
  final double? foodAllowance;
  final double? otherAllowance;
  final double? overtimeRate;
  final double? epfEmployee; // Percentage
  final double? epfEmployer; // Percentage
  final double? totalSalary;
  
  // Deduction Information
  final double? esic; // Percentage
  final double? professionalTax;
  
  // Bank Information
  final String? bankName;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? bankBranch;
  
  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  
  // Documents
  final String? aadharDocumentUrl;
  final String? panDocumentUrl;
  final String? resumeUrl;
  final String? offerLetterUrl;
  final String? appointmentLetterUrl;
  final String? otherDocumentsUrl;
  
  // Additional Information
  final String? notes;
  final bool? isActive;
  
  // Attendance Method
  final AttendanceMethod? attendanceMethod;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    this.id,
    required this.employeeId,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.bloodGroup,
    this.profilePhotoUrl,
    required this.email,
    required this.phoneNumber,
    this.alternatePhoneNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pincode,
    this.country,
    required this.aadharNumber,
    required this.panNumber,
    this.uanNumber,
    this.esicNumber,
    this.department,
    this.designation,
    this.joiningDate,
    this.employmentType,
    this.reportingManagerId,
    this.reportingManagerName,
    this.employmentStatus,
    this.workLocation,
    this.basicSalary,
    this.houseRentAllowance,
    this.conveyance,
    this.uniformAndSafety,
    this.bonus,
    this.foodAllowance,
    this.otherAllowance,
    this.overtimeRate,
    this.epfEmployee,
    this.epfEmployer,
    this.totalSalary,
    this.esic,
    this.professionalTax,
    this.bankName,
    this.bankAccountNumber,
    this.ifscCode,
    this.bankBranch,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.aadharDocumentUrl,
    this.panDocumentUrl,
    this.resumeUrl,
    this.offerLetterUrl,
    this.appointmentLetterUrl,
    this.otherDocumentsUrl,
    this.notes,
    this.isActive,
    this.attendanceMethod,
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int?,
      employeeId: json['employeeId'] as String,
      userId: json['userId'] as int?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      middleName: json['middleName'] as String?,
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth'] as String) 
          : null,
      gender: json['gender'] != null 
          ? Gender.values.firstWhere(
              (e) => e.name.toLowerCase() == (json['gender'] as String).toLowerCase(),
              orElse: () => Gender.other,
            )
          : null,
      maritalStatus: json['maritalStatus'] != null
          ? MaritalStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == (json['maritalStatus'] as String).toLowerCase(),
              orElse: () => MaritalStatus.single,
            )
          : null,
      bloodGroup: json['bloodGroup'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      alternatePhoneNumber: json['alternatePhoneNumber'] as String?,
      addressLine1: json['addressLine1'] as String?,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      country: json['country'] as String?,
      aadharNumber: json['aadharNumber'] as String,
      panNumber: json['panNumber'] as String,
      uanNumber: json['uanNumber'] as String?,
      esicNumber: json['esicNumber'] as String?,
      department: json['department'] as String?,
      designation: json['designation'] as String?,
      joiningDate: json['joiningDate'] != null 
          ? DateTime.parse(json['joiningDate'] as String) 
          : null,
      employmentType: json['employmentType'] != null
          ? EmploymentType.values.firstWhere(
              (e) => _camelToSnake(e.name).toLowerCase() == (json['employmentType'] as String).toLowerCase(),
              orElse: () => EmploymentType.fullTime,
            )
          : null,
      reportingManagerId: json['reportingManagerId'] as int?,
      reportingManagerName: json['reportingManagerName'] as String?,
      employmentStatus: json['employmentStatus'] != null
          ? EmploymentStatus.values.firstWhere(
              (e) => _camelToSnake(e.name).toLowerCase() == (json['employmentStatus'] as String).toLowerCase(),
              orElse: () => EmploymentStatus.active,
            )
          : null,
      workLocation: json['workLocation'] as String?,
      basicSalary: json['basicSalary'] != null ? (json['basicSalary'] as num).toDouble() : null,
      houseRentAllowance: json['houseRentAllowance'] != null ? (json['houseRentAllowance'] as num).toDouble() : null,
      conveyance: json['conveyance'] != null ? (json['conveyance'] as num).toDouble() : null,
      uniformAndSafety: json['uniformAndSafety'] != null ? (json['uniformAndSafety'] as num).toDouble() : null,
      bonus: json['bonus'] != null ? (json['bonus'] as num).toDouble() : null,
      foodAllowance: json['foodAllowance'] != null ? (json['foodAllowance'] as num).toDouble() : null,
      otherAllowance: json['otherAllowance'] != null ? (json['otherAllowance'] as num).toDouble() : null,
      overtimeRate: json['overtimeRate'] != null ? (json['overtimeRate'] as num).toDouble() : null,
      epfEmployee: json['epfEmployee'] != null ? (json['epfEmployee'] as num).toDouble() : null,
      epfEmployer: json['epfEmployer'] != null ? (json['epfEmployer'] as num).toDouble() : null,
      totalSalary: json['totalSalary'] != null ? (json['totalSalary'] as num).toDouble() : null,
      esic: json['esic'] != null ? (json['esic'] as num).toDouble() : null,
      professionalTax: json['professionalTax'] != null ? (json['professionalTax'] as num).toDouble() : null,
      bankName: json['bankName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      bankBranch: json['bankBranch'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelation: json['emergencyContactRelation'] as String?,
      aadharDocumentUrl: json['aadharDocumentUrl'] as String?,
      panDocumentUrl: json['panDocumentUrl'] as String?,
      resumeUrl: json['resumeUrl'] as String?,
      offerLetterUrl: json['offerLetterUrl'] as String?,
      appointmentLetterUrl: json['appointmentLetterUrl'] as String?,
      otherDocumentsUrl: json['otherDocumentsUrl'] as String?,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool?,
      attendanceMethod: json['attendanceMethod'] != null
          ? AttendanceMethod.values.firstWhere(
              (e) => _camelToSnake(e.name).toUpperCase() == (json['attendanceMethod'] as String).toUpperCase(),
              orElse: () => AttendanceMethod.faceRecognition,
            )
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      if (userId != null) 'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      if (middleName != null) 'middleName': middleName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String().split('T')[0],
      if (gender != null) 'gender': gender!.name.toUpperCase(),
      if (maritalStatus != null) 'maritalStatus': maritalStatus!.name.toUpperCase(),
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      if (alternatePhoneNumber != null) 'alternatePhoneNumber': alternatePhoneNumber,
      if (addressLine1 != null) 'addressLine1': addressLine1,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (country != null) 'country': country,
      'aadharNumber': aadharNumber,
      'panNumber': panNumber,
      if (uanNumber != null) 'uanNumber': uanNumber,
      if (esicNumber != null) 'esicNumber': esicNumber,
      if (department != null) 'department': department,
      if (designation != null) 'designation': designation,
      if (joiningDate != null) 'joiningDate': joiningDate!.toIso8601String().split('T')[0],
      if (employmentType != null) 'employmentType': _camelToSnake(employmentType!.name).toUpperCase(),
      if (reportingManagerId != null) 'reportingManagerId': reportingManagerId,
      if (employmentStatus != null) 'employmentStatus': _camelToSnake(employmentStatus!.name).toUpperCase(),
      if (workLocation != null) 'workLocation': workLocation,
      if (basicSalary != null) 'basicSalary': basicSalary,
      if (houseRentAllowance != null) 'houseRentAllowance': houseRentAllowance,
      if (conveyance != null) 'conveyance': conveyance,
      if (uniformAndSafety != null) 'uniformAndSafety': uniformAndSafety,
      if (bonus != null) 'bonus': bonus,
      if (foodAllowance != null) 'foodAllowance': foodAllowance,
      if (otherAllowance != null) 'otherAllowance': otherAllowance,
      if (overtimeRate != null) 'overtimeRate': overtimeRate,
      if (epfEmployee != null) 'epfEmployee': epfEmployee,
      if (epfEmployer != null) 'epfEmployer': epfEmployer,
      if (esic != null) 'esic': esic,
      if (professionalTax != null) 'professionalTax': professionalTax,
      if (bankName != null) 'bankName': bankName,
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      if (ifscCode != null) 'ifscCode': ifscCode,
      if (bankBranch != null) 'bankBranch': bankBranch,
      if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
      if (emergencyContactRelation != null) 'emergencyContactRelation': emergencyContactRelation,
      if (aadharDocumentUrl != null) 'aadharDocumentUrl': aadharDocumentUrl,
      if (panDocumentUrl != null) 'panDocumentUrl': panDocumentUrl,
      if (resumeUrl != null) 'resumeUrl': resumeUrl,
      if (offerLetterUrl != null) 'offerLetterUrl': offerLetterUrl,
      if (appointmentLetterUrl != null) 'appointmentLetterUrl': appointmentLetterUrl,
      if (otherDocumentsUrl != null) 'otherDocumentsUrl': otherDocumentsUrl,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'isActive': isActive,
      if (attendanceMethod != null) 'attendanceMethod': _camelToSnake(attendanceMethod!.name).toUpperCase(),
    };
  }

  String get fullName => '$firstName ${middleName ?? ''} $lastName'.trim();

  // Helper function to convert camelCase to snake_case
  static String _camelToSnake(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]}_${match[2]!.toLowerCase()}',
    );
  }
}

enum Gender {
  male,
  female,
  other,
}

enum MaritalStatus {
  single,
  married,
  divorced,
  widowed,
}

enum EmploymentType {
  fullTime,
  partTime,
  contract,
  intern,
}

enum EmploymentStatus {
  active,
  inactive,
  terminated,
  onLeave,
}

enum AttendanceMethod {
  faceRecognition,
  gpsBased,
}


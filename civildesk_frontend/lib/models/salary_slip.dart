class SalarySlip {
  final int? id;
  final String employeeId;
  final String employeeName;
  final String? department;
  final String? designation;
  final int year;
  final int month;
  final String periodString;
  
  // Calendar & Working Days
  final int? totalDaysInMonth;
  final int? workingDays;
  final int? weeklyOffs;
  
  // Attendance Data
  final double? totalEffectiveWorkingHours;
  final double? totalOvertimeHours;
  final double? rawPresentDays;
  final int? presentDays;
  final int? absentDays;
  final double? prorationFactor;
  
  // Earnings
  final double? basicPay;
  final double? hraAmount;
  final double? medicalAllowance;
  final double? conveyanceAllowance;
  final double? uniformAndSafetyAllowance;
  final double? bonus;
  final double? foodAllowance;
  final double? specialAllowance;
  final double? overtimePay;
  final double? totalSpecialAllowance;
  final double? otherIncentive;
  final double? epfEmployerEarnings;
  final double? totalEarnings;
  
  // Deductions
  final double? epfEmployeeDeduction;
  final double? epfEmployerDeduction;
  final double? esicDeduction;
  final double? professionalTax;
  final double? tds;
  final double? advanceSalaryRecovery;
  final double? loanRecovery;
  final double? fuelAdvanceRecovery;
  final double? otherDeductions;
  final double? totalStatutoryDeductions;
  final double? totalOtherDeductions;
  final double? totalDeductions;
  
  // Net Salary
  final double? netSalary;
  
  // Rates
  final double? dailyRate;
  final double? hourlyRate;
  final double? overtimeRate;
  
  // Status
  final String status;
  final int? generatedBy;
  final DateTime? generatedAt;
  final String? notes;
  
  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalarySlip({
    this.id,
    required this.employeeId,
    required this.employeeName,
    this.department,
    this.designation,
    required this.year,
    required this.month,
    required this.periodString,
    this.totalDaysInMonth,
    this.workingDays,
    this.weeklyOffs,
    this.totalEffectiveWorkingHours,
    this.totalOvertimeHours,
    this.rawPresentDays,
    this.presentDays,
    this.absentDays,
    this.prorationFactor,
    this.basicPay,
    this.hraAmount,
    this.medicalAllowance,
    this.conveyanceAllowance,
    this.uniformAndSafetyAllowance,
    this.bonus,
    this.foodAllowance,
    this.specialAllowance,
    this.overtimePay,
    this.totalSpecialAllowance,
    this.otherIncentive,
    this.epfEmployerEarnings,
    this.totalEarnings,
    this.epfEmployeeDeduction,
    this.epfEmployerDeduction,
    this.esicDeduction,
    this.professionalTax,
    this.tds,
    this.advanceSalaryRecovery,
    this.loanRecovery,
    this.fuelAdvanceRecovery,
    this.otherDeductions,
    this.totalStatutoryDeductions,
    this.totalOtherDeductions,
    this.totalDeductions,
    this.netSalary,
    this.dailyRate,
    this.hourlyRate,
    this.overtimeRate,
    required this.status,
    this.generatedBy,
    this.generatedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      id: json['id'],
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      department: json['department'],
      designation: json['designation'],
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      periodString: json['periodString'] ?? '',
      totalDaysInMonth: json['totalDaysInMonth'],
      workingDays: json['workingDays'],
      weeklyOffs: json['weeklyOffs'],
      totalEffectiveWorkingHours: json['totalEffectiveWorkingHours']?.toDouble(),
      totalOvertimeHours: json['totalOvertimeHours']?.toDouble(),
      rawPresentDays: json['rawPresentDays']?.toDouble(),
      presentDays: json['presentDays'],
      absentDays: json['absentDays'],
      prorationFactor: json['prorationFactor']?.toDouble(),
      basicPay: json['basicPay']?.toDouble(),
      hraAmount: json['hraAmount']?.toDouble(),
      medicalAllowance: json['medicalAllowance']?.toDouble(),
      conveyanceAllowance: json['conveyanceAllowance']?.toDouble(),
      uniformAndSafetyAllowance: json['uniformAndSafetyAllowance']?.toDouble(),
      bonus: json['bonus']?.toDouble(),
      foodAllowance: json['foodAllowance']?.toDouble(),
      specialAllowance: json['specialAllowance']?.toDouble(),
      overtimePay: json['overtimePay']?.toDouble(),
      totalSpecialAllowance: json['totalSpecialAllowance']?.toDouble(),
      otherIncentive: json['otherIncentive']?.toDouble(),
      epfEmployerEarnings: json['epfEmployerEarnings']?.toDouble(),
      totalEarnings: json['totalEarnings']?.toDouble(),
      epfEmployeeDeduction: json['epfEmployeeDeduction']?.toDouble(),
      epfEmployerDeduction: json['epfEmployerDeduction']?.toDouble(),
      esicDeduction: json['esicDeduction']?.toDouble(),
      professionalTax: json['professionalTax']?.toDouble(),
      tds: json['tds']?.toDouble(),
      advanceSalaryRecovery: json['advanceSalaryRecovery']?.toDouble(),
      loanRecovery: json['loanRecovery']?.toDouble(),
      fuelAdvanceRecovery: json['fuelAdvanceRecovery']?.toDouble(),
      otherDeductions: json['otherDeductions']?.toDouble(),
      totalStatutoryDeductions: json['totalStatutoryDeductions']?.toDouble(),
      totalOtherDeductions: json['totalOtherDeductions']?.toDouble(),
      totalDeductions: json['totalDeductions']?.toDouble(),
      netSalary: json['netSalary']?.toDouble(),
      dailyRate: json['dailyRate']?.toDouble(),
      hourlyRate: json['hourlyRate']?.toDouble(),
      overtimeRate: json['overtimeRate']?.toDouble(),
      status: json['status'] ?? 'DRAFT',
      generatedBy: json['generatedBy'],
      generatedAt: json['generatedAt'] != null ? DateTime.parse(json['generatedAt']) : null,
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': department,
      'designation': designation,
      'year': year,
      'month': month,
      'periodString': periodString,
      'totalDaysInMonth': totalDaysInMonth,
      'workingDays': workingDays,
      'weeklyOffs': weeklyOffs,
      'totalEffectiveWorkingHours': totalEffectiveWorkingHours,
      'totalOvertimeHours': totalOvertimeHours,
      'rawPresentDays': rawPresentDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'prorationFactor': prorationFactor,
      'basicPay': basicPay,
      'hraAmount': hraAmount,
      'medicalAllowance': medicalAllowance,
      'conveyanceAllowance': conveyanceAllowance,
      'uniformAndSafetyAllowance': uniformAndSafetyAllowance,
      'bonus': bonus,
      'foodAllowance': foodAllowance,
      'specialAllowance': specialAllowance,
      'overtimePay': overtimePay,
      'totalSpecialAllowance': totalSpecialAllowance,
      'otherIncentive': otherIncentive,
      'epfEmployerEarnings': epfEmployerEarnings,
      'totalEarnings': totalEarnings,
      'epfEmployeeDeduction': epfEmployeeDeduction,
      'epfEmployerDeduction': epfEmployerDeduction,
      'esicDeduction': esicDeduction,
      'professionalTax': professionalTax,
      'tds': tds,
      'advanceSalaryRecovery': advanceSalaryRecovery,
      'loanRecovery': loanRecovery,
      'fuelAdvanceRecovery': fuelAdvanceRecovery,
      'otherDeductions': otherDeductions,
      'totalStatutoryDeductions': totalStatutoryDeductions,
      'totalOtherDeductions': totalOtherDeductions,
      'totalDeductions': totalDeductions,
      'netSalary': netSalary,
      'dailyRate': dailyRate,
      'hourlyRate': hourlyRate,
      'overtimeRate': overtimeRate,
      'status': status,
      'generatedBy': generatedBy,
      'generatedAt': generatedAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class SalaryCalculationRequest {
  final String employeeId;
  final int year;
  final int month;
  final double? tds;
  final double? advanceSalaryRecovery;
  final double? loanRecovery;
  final double? fuelAdvanceRecovery;
  final double? otherDeductions;
  final double? otherIncentive;
  final String? notes;

  SalaryCalculationRequest({
    required this.employeeId,
    required this.year,
    required this.month,
    this.tds,
    this.advanceSalaryRecovery,
    this.loanRecovery,
    this.fuelAdvanceRecovery,
    this.otherDeductions,
    this.otherIncentive,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'year': year,
      'month': month,
      'tds': tds ?? 0.0,
      'advanceSalaryRecovery': advanceSalaryRecovery ?? 0.0,
      'loanRecovery': loanRecovery ?? 0.0,
      'fuelAdvanceRecovery': fuelAdvanceRecovery ?? 0.0,
      'otherDeductions': otherDeductions ?? 0.0,
      'otherIncentive': otherIncentive,
      'notes': notes,
    };
  }
}


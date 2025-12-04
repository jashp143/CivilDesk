class AppRoutes {
  // Common Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminEmployeeList = '/admin/employees';
  static const String adminEmployeeRegistration = '/admin/employees/register';
  static const String adminEmployeeDetail = '/admin/employees/:id';
  static const String adminAttendance = '/admin/attendance';
  static const String attendanceAnalytics = '/admin/attendance-analytics';
  static const String holidayManagement = '/admin/holidays';
  static const String adminSalary = '/admin/salary';
  static const String adminSalaryCalculation = '/admin/salary/calculate';
  static const String adminSalarySlips = '/admin/salary/slips';
  static const String adminLeave = '/admin/leave';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';

  // HR Manager Routes
  static const String hrDashboard = '/hr/dashboard';
  static const String hrEmployeeList = '/hr/employees';
  static const String hrEmployeeDetail = '/hr/employees/:id';
  static const String hrAttendance = '/hr/attendance';
  static const String hrLeave = '/hr/leave';
  static const String hrReports = '/hr/reports';

  // Employee Routes
  static const String employeeDashboard = '/employee/dashboard';
  static const String employeeProfile = '/employee/profile';
  static const String employeeAttendance = '/employee/attendance';
  static const String employeeLeave = '/employee/leave';
  static const String employeeSalary = '/employee/salary';
  static const String employeeAttendanceCheckIn = '/employee/attendance/check-in';

  // Attendance routes
  static const String faceRegistration = '/attendance/face-registration';
  static const String attendanceMarking = '/attendance/marking';
  static const String faceAttendance = '/attendance/face-attendance';
  static const String faceAttendanceAnnotated = '/attendance/face-attendance-annotated';
  static const String editPunchTimes = '/attendance/edit-punch-times';

  // Helper methods to build routes with parameters
  static String employeeDetail(String id) => '/admin/employees/$id';
  static String buildHrEmployeeDetail(String id) => '/hr/employees/$id';
}


class AppRoutes {
  // Common Routes
  static const String splash = '/';
  static const String login = '/login';

  // Employee Routes
  static const String home = '/home';
  static const String dashboard = '/dashboard'; // Keep for backward compatibility
  static const String myAttendance = '/my-attendance';
  static const String mySalarySlips = '/my-salary-slips';
  static const String leaves = '/leaves';
  static const String overtime = '/overtime';
  static const String expenses = '/expenses';
  static const String tasks = '/tasks';
  
  // Legacy routes (for backward compatibility)
  static const String profile = '/profile';
  static const String attendanceHistory = '/attendance/history';
  static const String leave = '/leave';
  static const String leaveRequest = '/leave/request';
  static const String settings = '/settings';
}


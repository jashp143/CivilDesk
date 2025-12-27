import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../core/providers/auth_provider.dart';
import '../screens/common/login_screen.dart';
import '../screens/common/signup_screen.dart';
import '../screens/common/verify_otp_screen.dart';
import '../screens/common/splash_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/hr_dashboard_screen.dart';
import '../screens/admin/employee_list_screen.dart';
import '../screens/employee/employee_dashboard_screen.dart';
import '../screens/attendance/face_registration_screen.dart';
import '../screens/attendance/admin_attendance_marking_screen.dart';
import '../screens/attendance/daily_overview_screen.dart';
import '../screens/attendance/face_attendance_screen.dart';
import '../screens/attendance/face_attendance_annotated_screen.dart';
import '../screens/admin/attendance_analytics_screen.dart';
import '../screens/admin/holiday_management_screen.dart';
import '../screens/admin/salary_calculation_screen.dart';
import '../screens/admin/salary_slips_list_screen.dart';
import '../screens/admin/site_management_screen.dart';
import '../screens/admin/gps_attendance_map_screen.dart';
import '../screens/admin/leaves_management_screen.dart';
import '../screens/admin/overtime_management_screen.dart';
import '../screens/admin/expenses_management_screen.dart';
import '../screens/admin/tasks_management_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/notifications_screen.dart';
import '../screens/admin/broadcast_management_screen.dart';
import '../widgets/route_guard.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
        );

      case AppRoutes.verifyOtp:
        final email = settings.arguments as String?;
        if (email == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Email is required for OTP verification')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(email: email),
        );

      // Admin routes
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const AdminDashboardScreen(),
          ),
        );

      case AppRoutes.adminEmployeeList:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const EmployeeListScreen(),
          ),
        );

      // HR Manager routes
      case AppRoutes.hrDashboard:
        return MaterialPageRoute(
          builder: (_) => ManagerRouteGuard(
            child: const HrDashboardScreen(),
          ),
        );

      // Employee routes
      case AppRoutes.employeeDashboard:
        return MaterialPageRoute(
          builder: (_) => EmployeeRouteGuard(
            child: const EmployeeDashboardScreen(),
          ),
        );

      // Attendance routes
      case AppRoutes.faceRegistration:
        final employeeId = settings.arguments as String?;
        if (employeeId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Employee ID is required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => FaceRegistrationScreen(employeeId: employeeId),
        );

      case AppRoutes.attendanceMarking:
        return MaterialPageRoute(
          builder: (_) => ManagerRouteGuard(
            child: const AdminAttendanceMarkingScreen(),
          ),
        );

      case AppRoutes.adminAttendance:
        return MaterialPageRoute(
          builder: (_) => ManagerRouteGuard(
            child: const DailyOverviewScreen(),
          ),
        );

      case AppRoutes.faceAttendance:
        return MaterialPageRoute(
          builder: (_) => const FaceAttendanceScreen(),
        );

      case AppRoutes.faceAttendanceAnnotated:
        return MaterialPageRoute(
          builder: (_) => const FaceAttendanceAnnotatedScreen(),
        );

      case AppRoutes.attendanceAnalytics:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const AttendanceAnalyticsScreen(),
          ),
        );

      case AppRoutes.holidayManagement:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const HolidayManagementScreen(),
          ),
        );

      case AppRoutes.adminSalaryCalculation:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const SalaryCalculationScreen(),
          ),
        );

      case AppRoutes.adminSalarySlips:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const SalarySlipsListScreen(),
          ),
        );

      case AppRoutes.siteManagement:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const SiteManagementScreen(),
          ),
        );

      case AppRoutes.gpsAttendanceMap:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const GpsAttendanceMapScreen(),
          ),
        );

      case AppRoutes.adminLeave:
        return MaterialPageRoute(
          builder: (_) => ManagerRouteGuard(
            child: const LeavesManagementScreen(),
          ),
        );

      case AppRoutes.adminOvertime:
        return MaterialPageRoute(
          builder: (_) => ManagerRouteGuard(
            child: const OvertimeManagementScreen(),
          ),
        );

      case AppRoutes.adminExpenses:
        return MaterialPageRoute(
          builder: (_) => ManagerRouteGuard(
            child: const ExpensesManagementScreen(),
          ),
        );

      case AppRoutes.adminTasks:
        return MaterialPageRoute(
          builder: (_) => ManagerRouteGuard(
            child: const TasksManagementScreen(),
          ),
        );

      case AppRoutes.adminSettings:
        return MaterialPageRoute(
          builder: (_) => AdminRouteGuard(
            child: const AdminSettingsScreen(),
          ),
        );

      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );

      case AppRoutes.adminBroadcasts:
        return MaterialPageRoute(
          builder: (_) => ManagerRouteGuard(
            child: const BroadcastManagementScreen(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static String? getInitialRoute(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return AppRoutes.login;
    }

    final role = authProvider.userRole;
    switch (role) {
      case 'ADMIN':
        return AppRoutes.adminDashboard;
      case 'HR_MANAGER':
        return AppRoutes.hrDashboard;
      case 'EMPLOYEE':
        return AppRoutes.employeeDashboard;
      default:
        return AppRoutes.login;
    }
  }
}


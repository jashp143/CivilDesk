import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../screens/common/login_screen.dart';
import '../screens/common/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/attendance/my_attendance_screen.dart';
import '../screens/salary/my_salary_slips_screen.dart';
import '../screens/leaves/leaves_screen.dart';
import '../screens/overtime/overtime_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/attendance/attendance_history_screen.dart';
import '../screens/attendance/gps_attendance_screen.dart';
import '../screens/leave/leave_screen.dart';
import '../screens/settings/settings_screen.dart';

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

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case AppRoutes.dashboard:
        // Redirect dashboard to home for backward compatibility
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case AppRoutes.myAttendance:
        return MaterialPageRoute(
          builder: (_) => const MyAttendanceScreen(),
        );

      case AppRoutes.gpsAttendance:
        return MaterialPageRoute(
          builder: (_) => const GpsAttendanceScreen(),
        );

      case AppRoutes.mySalarySlips:
        return MaterialPageRoute(
          builder: (_) => const MySalarySlipsScreen(),
        );

      case AppRoutes.leaves:
        return MaterialPageRoute(
          builder: (_) => const LeavesScreen(),
        );

      case AppRoutes.overtime:
        return MaterialPageRoute(
          builder: (_) => const OvertimeScreen(),
        );

      case AppRoutes.expenses:
        return MaterialPageRoute(
          builder: (_) => const ExpensesScreen(),
        );

      case AppRoutes.tasks:
        return MaterialPageRoute(
          builder: (_) => const TasksScreen(),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case AppRoutes.attendanceHistory:
        return MaterialPageRoute(
          builder: (_) => const AttendanceHistoryScreen(),
        );

      case AppRoutes.leave:
        return MaterialPageRoute(
          builder: (_) => const LeaveScreen(),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
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
}


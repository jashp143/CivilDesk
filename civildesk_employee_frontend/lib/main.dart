import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/attendance_provider.dart';
import 'core/providers/salary_slip_provider.dart';
import 'core/providers/leave_provider.dart';
import 'core/providers/overtime_provider.dart';
import 'core/providers/expense_provider.dart';
import 'core/providers/task_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/constants/app_routes.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const CivildeskEmployeeApp());
}

class CivildeskEmployeeApp extends StatelessWidget {
  const CivildeskEmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SalarySlipProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => OvertimeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final brightness = themeProvider.isDarkMode ? Brightness.dark : Brightness.light;
          return MaterialApp(
            title: 'Civildesk Employee',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(themeProvider.colorPalette, Brightness.light),
            darkTheme: AppTheme.getTheme(themeProvider.colorPalette, Brightness.dark),
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}

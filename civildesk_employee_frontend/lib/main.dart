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
import 'core/providers/holiday_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/broadcast_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/constants/app_routes.dart';
import 'routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    // Initialize FCM service (will be initialized after login)
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
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
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BroadcastProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
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

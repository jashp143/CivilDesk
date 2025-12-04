// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civildesk_employee_frontend/main.dart';
import 'package:civildesk_employee_frontend/core/providers/theme_provider.dart';
import 'package:civildesk_employee_frontend/core/providers/auth_provider.dart';
import 'package:civildesk_employee_frontend/core/providers/dashboard_provider.dart';
import 'package:civildesk_employee_frontend/core/providers/attendance_provider.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ],
        child: const CivildeskEmployeeApp(),
      ),
    );

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // Verify that the app has initialized (should show splash or login screen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

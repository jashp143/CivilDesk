import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/employee_layout.dart';

class OvertimeScreen extends StatelessWidget {
  const OvertimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      currentRoute: AppRoutes.overtime,
      title: const Text('Overtime'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Overtime feature will be available soon.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


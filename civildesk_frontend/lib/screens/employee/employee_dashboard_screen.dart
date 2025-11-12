import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../widgets/stats_card.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadEmployeeDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardProvider>().loadEmployeeDashboardStats();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.employeeStats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.employeeStats == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadEmployeeDashboardStats();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = provider.employeeStats;
          if (stats == null) {
            return const Center(child: Text('No data available'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadEmployeeDashboardStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Employee ID', stats.personalInfo.employeeId),
                          const SizedBox(height: 8),
                          _buildInfoRow('Name', stats.personalInfo.fullName),
                          const SizedBox(height: 8),
                          _buildInfoRow('Department', stats.personalInfo.department),
                          const SizedBox(height: 8),
                          _buildInfoRow('Designation', stats.personalInfo.designation),
                          const SizedBox(height: 8),
                          _buildInfoRow('Status', stats.personalInfo.employmentStatus),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Attendance Summary
                  Text(
                    'Attendance Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      StatsCard(
                        title: 'Present This Month',
                        value: stats.attendanceSummary.daysPresentThisMonth.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      StatsCard(
                        title: 'Absent This Month',
                        value: stats.attendanceSummary.daysAbsentThisMonth.toString(),
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),
                      StatsCard(
                        title: 'Attendance %',
                        value: '${stats.attendanceSummary.attendancePercentageThisMonth.toStringAsFixed(1)}%',
                        icon: Icons.percent,
                        color: Colors.blue,
                      ),
                      StatsCard(
                        title: 'On Leave',
                        value: stats.attendanceSummary.daysOnLeaveThisMonth.toString(),
                        icon: Icons.airplane_ticket,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  // Today's Status
                  if (stats.attendanceSummary.checkedInToday)
                    Card(
                      elevation: 2,
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Checked In Today',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                ),
                              ],
                            ),
                            if (stats.attendanceSummary.checkInTimeToday != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Check-in: ${stats.attendanceSummary.checkInTimeToday}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      color: Colors.grey.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Not checked in today',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Leave Summary
                  Text(
                    'Leave Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      StatsCard(
                        title: 'Total Leaves',
                        value: stats.leaveSummary.totalLeaves.toString(),
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      StatsCard(
                        title: 'Used Leaves',
                        value: stats.leaveSummary.usedLeaves.toString(),
                        icon: Icons.event_busy,
                        color: Colors.orange,
                      ),
                      StatsCard(
                        title: 'Remaining',
                        value: stats.leaveSummary.remainingLeaves.toString(),
                        icon: Icons.event_available,
                        color: Colors.green,
                      ),
                      StatsCard(
                        title: 'Pending Requests',
                        value: stats.leaveSummary.pendingLeaveRequests.toString(),
                        icon: Icons.pending,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }
}


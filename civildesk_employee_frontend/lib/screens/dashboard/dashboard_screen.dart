import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/attendance_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    await Future.wait([
      dashboardProvider.fetchDashboardStats(),
      attendanceProvider.fetchTodayAttendance(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: dashboardProvider.isLoading && dashboardProvider.dashboardStats == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${authProvider.userName ?? "Employee"}!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Today's Attendance Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Attendance',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            if (attendanceProvider.todayAttendance != null) ...[
                              _buildAttendanceRow(
                                'Check In',
                                attendanceProvider.todayAttendance!.checkInTime != null
                                    ? DateFormat('hh:mm a').format(
                                        attendanceProvider.todayAttendance!.checkInTime!)
                                    : 'Not marked',
                              ),
                              const Divider(),
                              _buildAttendanceRow(
                                'Lunch Start',
                                attendanceProvider.todayAttendance!.lunchOutTime != null
                                    ? DateFormat('hh:mm a').format(
                                        attendanceProvider.todayAttendance!.lunchOutTime!)
                                    : 'Not marked',
                              ),
                              const Divider(),
                              _buildAttendanceRow(
                                'Lunch End',
                                attendanceProvider.todayAttendance!.lunchInTime != null
                                    ? DateFormat('hh:mm a').format(
                                        attendanceProvider.todayAttendance!.lunchInTime!)
                                    : 'Not marked',
                              ),
                              const Divider(),
                              _buildAttendanceRow(
                                'Check Out',
                                attendanceProvider.todayAttendance!.checkOutTime != null
                                    ? DateFormat('hh:mm a').format(
                                        attendanceProvider.todayAttendance!.checkOutTime!)
                                    : 'Not marked',
                              ),
                              if (attendanceProvider.todayAttendance!.formattedWorkingHours != null ||
                                  attendanceProvider.todayAttendance!.formattedOvertimeHours != null) ...[
                                const Divider(),
                                if (attendanceProvider.todayAttendance!.formattedWorkingHours != null)
                                  _buildAttendanceRow(
                                    'Working Hours',
                                    attendanceProvider.todayAttendance!.formattedWorkingHours!,
                                    isBold: true,
                                    color: Colors.blue,
                                  ),
                                if (attendanceProvider.todayAttendance!.formattedOvertimeHours != null) ...[
                                  const Divider(),
                                  _buildAttendanceRow(
                                    'Overtime',
                                    attendanceProvider.todayAttendance!.formattedOvertimeHours!,
                                    isBold: true,
                                    color: Colors.orange,
                                  ),
                                ],
                              ],
                            ] else ...[
                              const Text('No attendance marked today'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, 
                                      color: Colors.blue.shade700, 
                                      size: 20
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Attendance is marked by admin/HR',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(AppRoutes.attendanceHistory);
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('View Attendance History'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Stats
                    if (dashboardProvider.dashboardStats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Present',
                              dashboardProvider.dashboardStats!.attendanceSummary
                                  .totalPresent
                                  .toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Absent',
                              dashboardProvider.dashboardStats!.attendanceSummary
                                  .totalAbsent
                                  .toString(),
                              Icons.cancel,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Leaves',
                              '${dashboardProvider.dashboardStats!.leaveSummary.remainingLeaves}/${dashboardProvider.dashboardStats!.leaveSummary.totalLeaves}',
                              Icons.event_busy,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Attendance',
                              '${dashboardProvider.dashboardStats!.attendanceSummary.attendancePercentage.toStringAsFixed(1)}%',
                              Icons.pie_chart,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildQuickAction(
                          context,
                          'Profile',
                          Icons.person,
                          AppRoutes.profile,
                        ),
                        _buildQuickAction(
                          context,
                          'History',
                          Icons.history,
                          AppRoutes.attendanceHistory,
                        ),
                        _buildQuickAction(
                          context,
                          'Leave',
                          Icons.event_note,
                          AppRoutes.leave,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAttendanceRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


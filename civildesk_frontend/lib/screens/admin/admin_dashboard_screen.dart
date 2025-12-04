import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/charts/department_chart.dart';
import '../../widgets/charts/employee_type_chart.dart';
import '../../widgets/admin_layout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadAdminDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.adminDashboard,
      title: const Text('Admin Dashboard'),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
              tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            context.read<DashboardProvider>().loadAdminDashboardStats();
          },
          tooltip: 'Refresh',
        ),
      ],
      child: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.adminStats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.adminStats == null) {
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
                        provider.loadAdminDashboardStats();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final stats = provider.adminStats;
            if (stats == null) {
              return const Center(child: Text('No data available'));
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadAdminDashboardStats(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee Stats Cards
                    Text(
                      'Employee Statistics',
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
                          title: 'Total Employees',
                          value: stats.employeeStats.totalEmployees.toString(),
                          icon: Icons.people,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.adminEmployeeList,
                            );
                          },
                        ),
                        StatsCard(
                          title: 'Active Employees',
                          value: stats.employeeStats.activeEmployees.toString(),
                          icon: Icons.people_outline,
                          color: Colors.green,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.adminEmployeeList,
                            );
                          },
                        ),
                        StatsCard(
                          title: 'New This Month',
                          value: stats.employeeStats.newEmployeesThisMonth
                              .toString(),
                          icon: Icons.person_add,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        StatsCard(
                          title: 'Departments',
                          value: stats.departmentStats.totalDepartments
                              .toString(),
                          icon: Icons.business,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Employee Type Chart
                    Text(
                      'Employees by Type',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 250,
                          child: EmployeeTypeChart(
                            employeeStats: stats.employeeStats,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Department Distribution Chart
                    Text(
                      'Department Distribution',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 250,
                              child: DepartmentChart(
                                departmentData:
                                    stats.departmentStats.departmentCounts,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DepartmentChartLegend(
                              departmentData:
                                  stats.departmentStats.departmentCounts,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Attendance Stats
                    Text(
                      'Attendance Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        StatsCard(
                          title: 'Present Today',
                          value: stats.attendanceStats.presentToday.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        StatsCard(
                          title: 'Absent Today',
                          value: stats.attendanceStats.absentToday.toString(),
                          icon: Icons.cancel,
                          color: Colors.red,
                        ),
                        StatsCard(
                          title: 'On Leave',
                          value: stats.attendanceStats.onLeaveToday.toString(),
                          icon: Icons.airplane_ticket,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick Actions Section
                    Text(
                      'Quick Actions',
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
                      childAspectRatio: 2.5,
                      children: [
                        // Salary Management Card
                        Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.adminSalarySlips,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.payments,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Salary Slips',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'View & Manage',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Calculate Salary Card
                        Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.adminSalaryCalculation,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calculate,
                                    color: Theme.of(context).colorScheme.secondary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Calculate Salary',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Generate New Slip',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Face Recognition Attendance Marking
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.face,
                                  color: Theme.of(context).primaryColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Mark Attendance',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use face recognition to mark attendance for employees',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.attendanceMarking,
                                );
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Mark Attendance with Face Recognition'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}

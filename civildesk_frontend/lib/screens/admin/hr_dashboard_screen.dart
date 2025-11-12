import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/charts/department_chart.dart';
import '../../widgets/charts/employee_type_chart.dart';

class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadHrDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardProvider>().loadHrDashboardStats();
            },
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
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
                      provider.loadHrDashboardStats();
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
            onRefresh: () => provider.loadHrDashboardStats(),
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
                        color: Colors.blue,
                      ),
                      StatsCard(
                        title: 'Active Employees',
                        value: stats.employeeStats.activeEmployees.toString(),
                        icon: Icons.people_outline,
                        color: Colors.green,
                      ),
                      StatsCard(
                        title: 'New This Month',
                        value: stats.employeeStats.newEmployeesThisMonth.toString(),
                        icon: Icons.person_add,
                        color: Colors.orange,
                      ),
                      StatsCard(
                        title: 'Departments',
                        value: stats.departmentStats.totalDepartments.toString(),
                        icon: Icons.business,
                        color: Colors.purple,
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
                              departmentData: stats.departmentStats.departmentCounts,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DepartmentChartLegend(
                            departmentData: stats.departmentStats.departmentCounts,
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
                                  color: Colors.grey[600],
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
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
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


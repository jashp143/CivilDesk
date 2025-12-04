import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await provider.fetchDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final personalInfo = dashboardProvider.dashboardStats?.personalInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: dashboardProvider.isLoading && personalInfo == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            authProvider.userName ?? 'Employee',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (personalInfo != null)
                            Text(
                              personalInfo.designation,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Profile Details
                    if (personalInfo != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Card(
                              child: Column(
                                children: [
                                  _buildInfoTile(
                                    'Employee Code',
                                    personalInfo.employeeCode,
                                    Icons.badge,
                                  ),
                                  const Divider(height: 1),
                                  _buildInfoTile(
                                    'Email',
                                    personalInfo.email,
                                    Icons.email,
                                  ),
                                  const Divider(height: 1),
                                  _buildInfoTile(
                                    'Department',
                                    personalInfo.department,
                                    Icons.business,
                                  ),
                                  const Divider(height: 1),
                                  _buildInfoTile(
                                    'Designation',
                                    personalInfo.designation,
                                    Icons.work,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Attendance Summary
                            if (dashboardProvider.dashboardStats != null) ...[
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attendance Summary',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatColumn(
                                            'Present',
                                            dashboardProvider.dashboardStats!
                                                .attendanceSummary.totalPresent
                                                .toString(),
                                            Colors.green,
                                          ),
                                          _buildStatColumn(
                                            'Absent',
                                            dashboardProvider.dashboardStats!
                                                .attendanceSummary.totalAbsent
                                                .toString(),
                                            Colors.red,
                                          ),
                                          _buildStatColumn(
                                            'Leaves',
                                            dashboardProvider.dashboardStats!
                                                .attendanceSummary.totalLeaves
                                                .toString(),
                                            Colors.orange,
                                          ),
                                          _buildStatColumn(
                                            'Percentage',
                                            '${dashboardProvider.dashboardStats!.attendanceSummary.attendancePercentage.toStringAsFixed(1)}%',
                                            Colors.blue,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}


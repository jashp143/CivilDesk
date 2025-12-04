import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/dashboard_provider.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaveData();
    });
  }

  Future<void> _loadLeaveData() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await provider.fetchDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final leaveSummary = provider.dashboardStats?.leaveSummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      body: provider.isLoading && leaveSummary == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLeaveData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leave Balance Card
                    if (leaveSummary != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Leave Balance',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildLeaveStatCard(
                                    'Total',
                                    leaveSummary.totalLeaves.toString(),
                                    Icons.calendar_month,
                                    Colors.blue,
                                  ),
                                  _buildLeaveStatCard(
                                    'Used',
                                    leaveSummary.usedLeaves.toString(),
                                    Icons.check_circle,
                                    Colors.orange,
                                  ),
                                  _buildLeaveStatCard(
                                    'Remaining',
                                    leaveSummary.remainingLeaves.toString(),
                                    Icons.event_available,
                                    Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pending Requests
                      if (leaveSummary.pendingRequests > 0)
                        Card(
                          color: Colors.amber.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.pending, color: Colors.amber),
                            title: const Text('Pending Leave Requests'),
                            subtitle: Text(
                                '${leaveSummary.pendingRequests} request(s) pending approval'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Apply Leave Section
                    Text(
                      'Apply for Leave',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.note_add,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Leave application feature coming soon',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: null,
                              child: const Text('Apply for Leave'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Leave History
                    Text(
                      'Leave History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No leave history available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLeaveStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
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


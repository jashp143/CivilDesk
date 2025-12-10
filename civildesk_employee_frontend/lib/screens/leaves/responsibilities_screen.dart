import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/leave_provider.dart';
import '../../models/leave.dart';

class ResponsibilitiesScreen extends StatefulWidget {
  const ResponsibilitiesScreen({Key? key}) : super(key: key);

  @override
  State<ResponsibilitiesScreen> createState() => _ResponsibilitiesScreenState();
}

class _ResponsibilitiesScreenState extends State<ResponsibilitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).fetchMyResponsibilities();
    });
  }

  Future<void> _refreshResponsibilities() async {
    await Provider.of<LeaveProvider>(context, listen: false).fetchMyResponsibilities();
  }

  void _viewLeaveDetails(Leave leave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responsibility Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Employee on Leave', leave.employeeName),
              _buildDetailRow('Employee ID', leave.employeeIdStr),
              if (leave.department != null)
                _buildDetailRow('Department', leave.department!),
              if (leave.designation != null)
                _buildDetailRow('Designation', leave.designation!),
              const Divider(),
              _buildDetailRow('Leave Type', leave.leaveTypeDisplay),
              _buildDetailRow('Start Date', DateFormat('dd MMM yyyy').format(leave.startDate)),
              _buildDetailRow('End Date', DateFormat('dd MMM yyyy').format(leave.endDate)),
              _buildDetailRow('Total Days', leave.totalDays.toString()),
              if (leave.isHalfDay)
                _buildDetailRow('Half Day', leave.halfDayPeriodDisplay ?? ''),
              const Divider(),
              _buildDetailRow('Contact Number', leave.contactNumber),
              _buildDetailRow('Reason', leave.reason),
              if (leave.handoverEmployees != null && leave.handoverEmployees!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Other Responsible Employees:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...leave.handoverEmployees!.map((emp) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text('• ${emp.name} (${emp.employeeId})'),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Responsibilities'),
        elevation: 0,
      ),
      body: Consumer<LeaveProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshResponsibilities,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.responsibilities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No Responsibilities',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have no assigned responsibilities from other employees.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshResponsibilities,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.responsibilities.length,
              itemBuilder: (context, index) {
                final leave = provider.responsibilities[index];
                return _buildResponsibilityCard(leave);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsibilityCard(Leave leave) {
    final isActive = leave.startDate.isBefore(DateTime.now().add(const Duration(days: 1))) &&
        leave.endDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewLeaveDetails(leave),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.employeeName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${leave.employeeIdStr} • ${leave.designation ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Leave Type
              Row(
                children: [
                  const Icon(Icons.category, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    leave.leaveTypeDisplay,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date Range
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${leave.totalDays} ${leave.totalDays == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Contact Number
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Contact: ${leave.contactNumber}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reason
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leave.reason,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/employee_layout.dart';
import '../../core/providers/leave_provider.dart';
import '../../models/leave.dart';
import 'apply_leave_screen.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).fetchMyLeaves();
    });
  }

  Future<void> _refreshLeaves() async {
    await Provider.of<LeaveProvider>(context, listen: false).fetchMyLeaves();
  }

  void _navigateToApplyLeave() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplyLeaveScreen(),
      ),
    );
    if (result == true) {
      _refreshLeaves();
    }
  }

  void _editLeave(Leave leave) async {
    if (leave.status != LeaveStatus.PENDING) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pending leaves can be edited'),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyLeaveScreen(existingLeave: leave),
      ),
    );
    if (result == true) {
      _refreshLeaves();
    }
  }

  void _deleteLeave(Leave leave) {
    if (leave.status != LeaveStatus.PENDING) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pending leaves can be deleted'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Leave'),
        content: const Text('Are you sure you want to delete this leave application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<LeaveProvider>(context, listen: false);
              final success = await provider.deleteLeave(leave.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leave deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error ?? 'Failed to delete leave'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _viewLeaveDetails(Leave leave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${leave.leaveTypeDisplay} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Employee', leave.employeeName),
              _buildDetailRow('Employee ID', leave.employeeIdStr),
              _buildDetailRow('Leave Type', leave.leaveTypeDisplay),
              _buildDetailRow('Start Date', DateFormat('dd MMM yyyy').format(leave.startDate)),
              _buildDetailRow('End Date', DateFormat('dd MMM yyyy').format(leave.endDate)),
              _buildDetailRow('Total Days', leave.totalDays.toString()),
              if (leave.isHalfDay)
                _buildDetailRow('Half Day', leave.halfDayPeriodDisplay ?? ''),
              _buildDetailRow('Contact Number', leave.contactNumber),
              if (leave.handoverEmployees != null && leave.handoverEmployees!.isNotEmpty)
                _buildDetailRow(
                  'Handover To',
                  leave.handoverEmployees!.map((e) => e.name).join(', '),
                ),
              _buildDetailRow('Reason', leave.reason),
              _buildDetailRow('Status', leave.statusDisplay),
              if (leave.reviewedBy != null) ...[
                const Divider(),
                _buildDetailRow('Reviewed By', leave.reviewedBy!.name),
                _buildDetailRow('Role', leave.reviewedBy!.role),
                if (leave.reviewedAt != null)
                  _buildDetailRow(
                    'Reviewed At',
                    DateFormat('dd MMM yyyy, hh:mm a').format(leave.reviewedAt!),
                  ),
                if (leave.reviewNote != null && leave.reviewNote!.isNotEmpty)
                  _buildDetailRow('Note', leave.reviewNote!),
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
    return EmployeeLayout(
      currentRoute: AppRoutes.leaves,
      title: const Text('My Leaves'),
      actions: [
        ElevatedButton.icon(
          onPressed: _navigateToApplyLeave,
          icon: const Icon(Icons.add),
          label: const Text('Apply Leave'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
      child: Column(
        children: [
          // Leaves List
          Expanded(
            child: Consumer<LeaveProvider>(
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
                          onPressed: _refreshLeaves,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.leaves.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        Text(
                          'No Leave Applications',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _navigateToApplyLeave,
                          icon: const Icon(Icons.add),
                          label: const Text('Apply for Leave'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshLeaves,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.leaves.length,
                    itemBuilder: (context, index) {
                      final leave = provider.leaves[index];
                      return _buildLeaveCard(leave);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Leave leave) {
    Color statusColor;
    IconData statusIcon;

    switch (leave.status) {
      case LeaveStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case LeaveStatus.APPROVED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case LeaveStatus.REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case LeaveStatus.CANCELLED:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
    }

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
                    child: Text(
                      leave.leaveTypeDisplay,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          leave.statusDisplay,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Date Range
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
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
              if (leave.isHalfDay) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      leave.halfDayPeriodDisplay ?? 'Half Day',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Reason
              Text(
                leave.reason,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (leave.reviewedBy != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Reviewed by: ${leave.reviewedBy!.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              // Actions
              if (leave.status == LeaveStatus.PENDING) ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editLeave(leave),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteLeave(leave),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


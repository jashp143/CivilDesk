import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/employee_layout.dart';
import '../../core/providers/overtime_provider.dart';
import '../../models/overtime.dart';
import 'apply_overtime_screen.dart';

class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OvertimeProvider>(context, listen: false).fetchMyOvertimes();
    });
  }

  Future<void> _refreshOvertimes() async {
    await Provider.of<OvertimeProvider>(context, listen: false).fetchMyOvertimes();
  }

  void _navigateToApplyOvertime() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplyOvertimeScreen(),
      ),
    );
    if (result == true) {
      _refreshOvertimes();
    }
  }

  void _editOvertime(Overtime overtime) async {
    if (overtime.status != OvertimeStatus.PENDING) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pending overtimes can be edited'),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyOvertimeScreen(existingOvertime: overtime),
      ),
    );
    if (result == true) {
      _refreshOvertimes();
    }
  }

  void _deleteOvertime(Overtime overtime) {
    if (overtime.status != OvertimeStatus.PENDING) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pending overtimes can be deleted'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Overtime'),
        content: const Text('Are you sure you want to delete this overtime application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<OvertimeProvider>(context, listen: false);
              final success = await provider.deleteOvertime(overtime.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Overtime deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error ?? 'Failed to delete overtime'),
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

  void _viewOvertimeDetails(Overtime overtime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Overtime Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(overtime.date)),
              _buildDetailRow('Start Time', overtime.startTime),
              _buildDetailRow('End Time', overtime.endTime),
              _buildDetailRow('Reason', overtime.reason),
              _buildDetailRow('Status', overtime.statusDisplay),
              if (overtime.reviewedBy != null) ...[
                const Divider(),
                _buildDetailRow('Reviewed By', overtime.reviewedBy!.name),
                _buildDetailRow('Role', overtime.reviewedBy!.role),
                if (overtime.reviewedAt != null)
                  _buildDetailRow(
                    'Reviewed At',
                    DateFormat('dd MMM yyyy, hh:mm a').format(overtime.reviewedAt!),
                  ),
                if (overtime.reviewNote != null && overtime.reviewNote!.isNotEmpty)
                  _buildDetailRow('Note', overtime.reviewNote!),
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
      currentRoute: AppRoutes.overtime,
      title: const Text('My Overtimes'),
      actions: [
        ElevatedButton.icon(
          onPressed: _navigateToApplyOvertime,
          icon: const Icon(Icons.add),
          label: const Text('Apply Overtime'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
      child: Column(
        children: [
          // Overtimes List
          Expanded(
            child: Consumer<OvertimeProvider>(
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
                          onPressed: _refreshOvertimes,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.overtimes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        Text(
                          'No Overtime Applications',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _navigateToApplyOvertime,
                          icon: const Icon(Icons.add),
                          label: const Text('Apply for Overtime'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshOvertimes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.overtimes.length,
                    itemBuilder: (context, index) {
                      final overtime = provider.overtimes[index];
                      return _buildOvertimeCard(overtime);
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

  Widget _buildOvertimeCard(Overtime overtime) {
    Color statusColor;
    IconData statusIcon;

    switch (overtime.status) {
      case OvertimeStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case OvertimeStatus.APPROVED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case OvertimeStatus.REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewOvertimeDetails(overtime),
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
                      'Overtime Request',
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
                          overtime.statusDisplay,
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
              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(overtime.date),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Time Range
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${overtime.startTime} - ${overtime.endTime}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reason
              Text(
                overtime.reason,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (overtime.reviewedBy != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Reviewed by: ${overtime.reviewedBy!.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              // Actions
              if (overtime.status == OvertimeStatus.PENDING) ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editOvertime(overtime),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteOvertime(overtime),
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


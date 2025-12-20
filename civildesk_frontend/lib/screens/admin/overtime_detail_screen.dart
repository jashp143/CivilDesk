import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/overtime.dart';
import '../../core/providers/overtime_provider.dart';

class OvertimeDetailScreen extends StatefulWidget {
  final Overtime overtime;

  const OvertimeDetailScreen({super.key, required this.overtime});

  @override
  State<OvertimeDetailScreen> createState() => _OvertimeDetailScreenState();
}

class _OvertimeDetailScreenState extends State<OvertimeDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showReviewDialog(OvertimeStatus status) {
    _noteController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == OvertimeStatus.APPROVED ? 'Approve Overtime' : 'Reject Overtime',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${status == OvertimeStatus.APPROVED ? 'approve' : 'reject'} this overtime application?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add a note for the employee',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewOvertime(status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == OvertimeStatus.APPROVED 
                  ? Colors.green 
                  : Colors.red,
            ),
            child: Text(
              status == OvertimeStatus.APPROVED ? 'APPROVE' : 'REJECT',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewOvertime(OvertimeStatus status) async {
    setState(() => _isSubmitting = true);

    final provider = Provider.of<OvertimeProvider>(context, listen: false);
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    
    final success = await provider.reviewOvertime(widget.overtime.id, status, note);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Overtime ${status == OvertimeStatus.APPROVED ? 'approved' : 'rejected'} successfully',
            ),
            backgroundColor: status == OvertimeStatus.APPROVED ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh parent screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to review overtime'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overtime = widget.overtime;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overtime Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: statusColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            overtime.statusDisplay,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Employee Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    _buildDetailRow('Name', overtime.employeeName),
                    _buildDetailRow('Employee ID', overtime.employeeIdStr),
                    if (overtime.designation != null)
                      _buildDetailRow('Designation', overtime.designation!),
                    if (overtime.department != null)
                      _buildDetailRow('Department', overtime.department!),
                    _buildDetailRow('Email', overtime.employeeEmail),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Overtime Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overtime Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Date',
                      DateFormat('dd MMMM yyyy (EEEE)').format(overtime.date),
                    ),
                    _buildDetailRow('Start Time', overtime.startTime),
                    _buildDetailRow('End Time', overtime.endTime),
                    _buildDetailRow('Reason', overtime.reason),
                  ],
                ),
              ),
            ),
            // Review Information
            if (overtime.reviewedBy != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
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
                  ),
                ),
              ),
            ],
            // Action Buttons
            if (overtime.status == OvertimeStatus.PENDING) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _showReviewDialog(OvertimeStatus.APPROVED),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _showReviewDialog(OvertimeStatus.REJECTED),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

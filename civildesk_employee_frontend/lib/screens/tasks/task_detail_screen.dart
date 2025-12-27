import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/task_provider.dart';
import '../../models/task.dart';
import '../../widgets/cached_profile_image.dart';
import '../../widgets/toast.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _ReviewDialog extends StatefulWidget {
  final TaskStatus status;
  final int taskId;
  final TextEditingController reviewNoteController;
  final VoidCallback onSuccess;
  final ValueChanged<String> onError;

  const _ReviewDialog({
    required this.status,
    required this.taskId,
    required this.reviewNoteController,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  bool _isReviewing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.status == TaskStatus.approved ? 'Approve Task' : 'Reject Task',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.status == TaskStatus.approved
                  ? 'Are you sure you want to approve this task?'
                  : 'Are you sure you want to reject this task?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Note (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.reviewNoteController,
              enabled: !_isReviewing,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a note...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isReviewing
              ? null
              : () {
                  widget.reviewNoteController.clear();
                  Navigator.pop(context);
                },
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isReviewing
              ? null
              : () async {
                  final note = widget.reviewNoteController.text.trim();
                  
                  setState(() {
                    _isReviewing = true;
                  });

                  final provider = Provider.of<TaskProvider>(context, listen: false);
                  final success = await provider.reviewTask(
                    widget.taskId,
                    widget.status,
                    note.isEmpty ? null : note,
                  );

                  if (!mounted) return;

                  widget.reviewNoteController.clear();

                  if (success) {
                    widget.onSuccess();
                  } else {
                    widget.onError(provider.error ?? 'Failed to review task');
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.status == TaskStatus.approved
                ? Colors.green
                : Colors.red,
          ),
          child: _isReviewing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.status == TaskStatus.approved ? 'APPROVE' : 'REJECT',
                ),
        ),
      ],
    );
  }
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _reviewNoteController = TextEditingController();

  @override
  void dispose() {
    _reviewNoteController.dispose();
    super.dispose();
  }

  void _showReviewDialog(TaskStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ReviewDialog(
        status: status,
        taskId: widget.task.id,
        reviewNoteController: _reviewNoteController,
        onSuccess: () {
          Navigator.pop(dialogContext);
          if (mounted) {
            Toast.success(context, status == TaskStatus.approved
                ? 'Task approved successfully'
                : 'Task rejected successfully');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pop(context, true);
              }
            });
          }
        },
        onError: (error) {
          Navigator.pop(dialogContext);
          if (mounted) {
            Toast.error(context, error);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case TaskStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
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
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.statusDisplay,
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
            // Location
            _buildDetailSection(
              icon: Icons.location_on,
              title: 'Location',
              content: task.location,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            // Date Range
            _buildDetailSection(
              icon: Icons.calendar_today,
              title: 'Date Range',
              content:
                  '${DateFormat('dd MMM yyyy').format(task.startDate)} - ${DateFormat('dd MMM yyyy').format(task.endDate)}',
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            // Mode of Travel
            _buildDetailSection(
              icon: Icons.directions_transit,
              title: 'Mode of Travel',
              content: task.modeOfTravelDisplay,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            // Description
            _buildDetailSection(
              icon: Icons.description,
              title: 'Description',
              content: task.description,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            // Assigned By (only show if role is ADMIN or HR_MANAGER)
            if (task.assignedBy.role.toUpperCase() == 'ADMIN' || 
                task.assignedBy.role.toUpperCase() == 'HR_MANAGER')
              _buildDetailSection(
                icon: Icons.person,
                title: 'Assigned By',
                content: '${task.assignedBy.name} (${task.assignedBy.role})',
                color: Colors.orange,
              ),
            const SizedBox(height: 16),
            // Assigned Employees
            if (task.assignedEmployees.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Assigned Employees',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...task.assignedEmployees.map((employee) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CachedProfileImage(
                                imageUrl: null, // Profile photo URL can be added to model
                                fallbackInitials: employee.name,
                                radius: 16,
                                backgroundColor: Colors.green[100],
                                foregroundColor: Colors.green[900],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (employee.designation != null)
                                      Text(
                                        employee.designation!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            // Review Information
            if (task.reviewedAt != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Review Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Reviewed At',
                        DateFormat('dd MMM yyyy, hh:mm a').format(task.reviewedAt!),
                      ),
                      if (task.reviewNote != null && task.reviewNote!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Your Comment', task.reviewNote!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            // Action Buttons
            if (task.status == TaskStatus.pending) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(TaskStatus.rejected),
                      icon: const Icon(Icons.cancel),
                      label: const Text('REJECT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(TaskStatus.approved),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('APPROVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

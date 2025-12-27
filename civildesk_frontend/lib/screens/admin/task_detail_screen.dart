import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/toast.dart';
import '../../core/providers/task_provider.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/utils/message_builder.dart';
import '../../models/task.dart';
import '../../widgets/cached_profile_image.dart';
import '../../widgets/detail_screen_components.dart';
import 'assign_task_dialog.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
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
        title: Text(
          'Task Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: DetailScreenComponents.buildStatusBadge(
                context: context,
                status: task.statusDisplay,
                color: statusColor,
                icon: statusIcon,
                isCompact: true,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: DetailScreenComponents.buildResponsiveContainer(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Task Details
                  DetailScreenComponents.buildSectionCard(
                context: context,
                title: 'Task Details',
                icon: Icons.task,
                accentColor: Colors.blue,
                children: [
                  DetailScreenComponents.buildDetailRow(
                    context: context,
                    label: 'Location',
                    value: task.location,
                    icon: Icons.location_on,
                    isHighlighted: true,
                  ),
                  DetailScreenComponents.buildDateRange(
                    context: context,
                    startDate: task.startDate,
                    endDate: task.endDate,
                  ),
                  const SizedBox(height: 16),
                  DetailScreenComponents.buildDetailRow(
                    context: context,
                    label: 'Mode of Travel',
                    value: task.modeOfTravelDisplay,
                    icon: Icons.directions_transit,
                  ),
                  if (task.siteName != null && task.siteName!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DetailScreenComponents.buildDetailRow(
                      context: context,
                      label: 'Site Name',
                      value: task.siteName!,
                      icon: Icons.business,
                    ),
                  ],
                  if (task.siteContactPersonName != null && task.siteContactPersonName!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DetailScreenComponents.buildDetailRow(
                      context: context,
                      label: 'Contact Person',
                      value: task.siteContactPersonName!,
                      icon: Icons.person,
                    ),
                  ],
                  if (task.siteContactPhone != null && task.siteContactPhone!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DetailScreenComponents.buildDetailRow(
                      context: context,
                      label: 'Contact Phone',
                      value: task.siteContactPhone!,
                      icon: Icons.phone,
                    ),
                  ],
                  const SizedBox(height: 8),
                  DetailScreenComponents.buildTextContent(
                    context: context,
                    text: task.description,
                    icon: Icons.description,
                    accentColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Assigned By
              DetailScreenComponents.buildSectionCard(
                context: context,
                title: 'Assigned By',
                icon: Icons.person,
                accentColor: Colors.orange,
                children: [
                  DetailScreenComponents.buildDetailRow(
                    context: context,
                    label: 'Name',
                    value: task.assignedBy.name,
                    icon: Icons.person,
                    isHighlighted: true,
                  ),
                  DetailScreenComponents.buildDetailRow(
                    context: context,
                    label: 'Role',
                    value: task.assignedBy.role,
                    icon: Icons.badge,
                  ),
                  DetailScreenComponents.buildDetailRow(
                    context: context,
                    label: 'Email',
                    value: task.assignedBy.email,
                    icon: Icons.email,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Assigned Employees
              if (task.assignedEmployees.isNotEmpty)
                DetailScreenComponents.buildSectionCard(
                  context: context,
                  title: 'Assigned Employees (${task.assignedEmployees.length})',
                  icon: Icons.people,
                  accentColor: Colors.green,
                  children: task.assignedEmployees.map((employee) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          CachedProfileImage(
                            imageUrl: null,
                            fallbackInitials: employee.name,
                            radius: 20,
                            backgroundColor: Colors.green.withValues(alpha: 0.15),
                            foregroundColor: Colors.green.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${employee.employeeId}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (employee.designation != null || employee.department != null)
                                  Text(
                                    [employee.designation, employee.department]
                                        .where((e) => e != null)
                                        .join(' • '),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              // Review Information
              if (task.reviewedAt != null) ...[
                const SizedBox(height: 16),
                DetailScreenComponents.buildSectionCard(
                  context: context,
                  title: 'Review Information',
                  icon: Icons.rate_review,
                  accentColor: task.status == TaskStatus.approved
                      ? Colors.green
                      : Colors.red,
                  children: [
                    DetailScreenComponents.buildDetailRow(
                      context: context,
                      label: 'Reviewed At',
                      value: DateFormat('dd MMM yyyy, hh:mm a').format(task.reviewedAt!),
                      icon: Icons.access_time,
                    ),
                    if (task.reviewNote != null && task.reviewNote!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DetailScreenComponents.buildTextContent(
                        context: context,
                        text: task.reviewNote!,
                        icon: Icons.note,
                      ),
                    ],
                  ],
                ),
              ],
              // Task Information
              const SizedBox(height: 16),
              DetailScreenComponents.buildSectionCard(
                context: context,
                title: 'Task Information',
                icon: Icons.info,
                accentColor: Colors.grey,
                children: [
                  DetailScreenComponents.buildDetailRow(
                    context: context,
                    label: 'Created At',
                    value: DateFormat('dd MMM yyyy, hh:mm a').format(task.createdAt),
                    icon: Icons.access_time,
                  ),
                  DetailScreenComponents.buildDetailRow(
                    context: context,
                    label: 'Updated At',
                    value: DateFormat('dd MMM yyyy, hh:mm a').format(task.updatedAt),
                    icon: Icons.update,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Add spacing for bottom buttons
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
          // Bottom Action Buttons (always visible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (task.status == TaskStatus.pending) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editTask(task),
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text('EDIT'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteTask(task),
                          icon: const Icon(Icons.delete, size: 20),
                          label: const Text('DELETE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton(
                      onPressed: () => _sendTaskWhatsAppToAll(task),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(56, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.message, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _editTask(Task task) async {
    if (task.status != TaskStatus.pending) {
      Toast.warning(context, 'Only pending tasks can be edited');
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (context) => AssignTaskDialog(existingTask: task),
    );
    if (result == true && mounted) {
      // Refresh the task data
      final provider = Provider.of<TaskProvider>(context, listen: false);
      final updatedTask = await provider.getTaskById(task.id);
      if (updatedTask != null && mounted) {
        Navigator.pop(context, true); // Return to refresh parent
      }
    }
  }

  void _deleteTask(Task task) {
    if (task.status != TaskStatus.pending) {
      Toast.warning(context, 'Only pending tasks can be deleted');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<TaskProvider>(
                context,
                listen: false,
              );
              final success = await provider.deleteTask(task.id);
              if (mounted && context.mounted) {
                if (success) {
                  Toast.success(context, 'Task deleted successfully');
                  Navigator.pop(context, true); // Return to refresh parent
                } else {
                  Toast.error(context, provider.error ?? 'Failed to delete task');
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

  Future<void> _sendTaskWhatsAppToAll(Task task) async {
    if (task.assignedEmployees.isEmpty) {
      Toast.warning(context, 'No employees assigned to this task');
      return;
    }

    int successCount = 0;
    int failCount = 0;

    for (final assignedEmployee in task.assignedEmployees) {
      try {
        // Fetch employee to get phone number
        final employeeService = EmployeeService();
        final employee = await employeeService.getEmployeeById(assignedEmployee.id);
        
        if (employee.phoneNumber.isEmpty) {
          failCount++;
          continue;
        }

        // Build message
        final message = MessageBuilder.buildTaskAssignmentMessage(
          task: task,
          employeeName: assignedEmployee.name,
        );

        // Launch WhatsApp
        final launched = await WhatsAppService.launchWhatsApp(
          phoneNumber: employee.phoneNumber,
          message: message,
        );

        if (launched) {
          successCount++;
          // Add a small delay between messages to avoid overwhelming the system
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      if (successCount > 0 && failCount == 0) {
        Toast.success(context, 'WhatsApp notifications sent to all employees');
      } else if (successCount > 0 && failCount > 0) {
        Toast.warning(
          context,
          'Sent to $successCount employee(s). Failed to send to $failCount employee(s).',
        );
      } else {
        Toast.error(context, 'Failed to send WhatsApp notifications');
      }
    }
  }
}


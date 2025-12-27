import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leave.dart';
import '../../widgets/employee_layout.dart';
import '../../core/constants/app_routes.dart';

class ResponsibilityDetailScreen extends StatelessWidget {
  final Leave leave;

  const ResponsibilityDetailScreen({super.key, required this.leave});

  Color _getStatusColor(LeaveStatus status, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    switch (status) {
      case LeaveStatus.APPROVED:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case LeaveStatus.PENDING:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      case LeaveStatus.REJECTED:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
      case LeaveStatus.CANCELLED:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.APPROVED:
        return Icons.check_circle;
      case LeaveStatus.PENDING:
        return Icons.pending;
      case LeaveStatus.REJECTED:
        return Icons.cancel;
      case LeaveStatus.CANCELLED:
        return Icons.block;
    }
  }

  String _getConflictTypeText(String conflictType) {
    switch (conflictType) {
      case 'EXACT_OVERLAP':
        return 'Exact Date Overlap';
      case 'COMPLETE_OVERLAP':
        return 'Complete Date Overlap';
      case 'PARTIAL_OVERLAP':
        return 'Partial Date Overlap';
      default:
        return 'Date Conflict';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(leave.status, colorScheme);
    final statusIcon = _getStatusIcon(leave.status);
    final isActive = leave.startDate.isBefore(DateTime.now().add(const Duration(days: 1))) &&
        leave.endDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return EmployeeLayout(
      currentRoute: AppRoutes.responsibilities,
      title: const Text('Responsibility Details'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Active Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        leave.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 12, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Employee on Leave Information Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Employee on Leave',
                          style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'Name',
                      leave.employeeName,
                      colorScheme,
                    ),
                    _buildInfoRow(
                      context,
                      'Employee ID',
                      leave.employeeIdStr,
                      colorScheme,
                    ),
                    if (leave.department != null)
                      _buildInfoRow(
                        context,
                        'Department',
                        leave.department!,
                        colorScheme,
                      ),
                    if (leave.designation != null)
                      _buildInfoRow(
                        context,
                        'Designation',
                        leave.designation!,
                        colorScheme,
                      ),
                    _buildInfoRow(
                      context,
                      'Email',
                      leave.employeeEmail,
                      colorScheme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Leave Information Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Leave Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'Leave Type',
                      leave.leaveTypeDisplay,
                      colorScheme,
                    ),
                    _buildInfoRow(
                      context,
                      'Start Date',
                      DateFormat('dd MMM yyyy').format(leave.startDate),
                      colorScheme,
                    ),
                    _buildInfoRow(
                      context,
                      'End Date',
                      DateFormat('dd MMM yyyy').format(leave.endDate),
                      colorScheme,
                    ),
                    _buildInfoRow(
                      context,
                      'Total Days',
                      '${leave.totalDays} ${leave.totalDays == 1 ? 'day' : 'days'}',
                      colorScheme,
                    ),
                    if (leave.isHalfDay)
                      _buildInfoRow(
                        context,
                        'Half Day Period',
                        leave.halfDayPeriodDisplay ?? 'Half Day',
                        colorScheme,
                      ),
                    _buildInfoRow(
                      context,
                      'Contact Number',
                      leave.contactNumber,
                      colorScheme,
                    ),
                  ],
                ),
              ),
            ),

            // Conflict Warning Card
            if (leave.hasConflicts &&
                leave.conflicts != null &&
                leave.conflicts!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.orange.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Conflict Detected',
                              style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have overlapping leaves with the following employees:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...leave.conflicts!.map((conflict) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.orange.shade100,
                                    child: Text(
                                      conflict.employeeName.isNotEmpty
                                          ? conflict.employeeName[0].toUpperCase()
                                          : 'E',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          conflict.employeeName,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                        ),
                                        Text(
                                          'ID: ${conflict.employeeIdStr}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                context,
                                'Leave Type',
                                conflict.leaveType,
                                colorScheme,
                              ),
                              _buildInfoRow(
                                context,
                                'Dates',
                                '${DateFormat('dd MMM yyyy').format(conflict.leaveStartDate)} - ${DateFormat('dd MMM yyyy').format(conflict.leaveEndDate)}',
                                colorScheme,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getConflictTypeText(conflict.conflictType),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
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
            ],

            // Other Responsible Employees
            if (leave.handoverEmployees != null &&
                leave.handoverEmployees!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Other Responsible Employees',
                            style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...leave.handoverEmployees!.map((employee) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  employee.name.isNotEmpty
                                      ? employee.name[0].toUpperCase()
                                      : 'E',
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee.name,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                    if (employee.designation != null)
                                      Text(
                                        employee.designation!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    Text(
                                      'ID: ${employee.employeeId}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
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
            ],

            // Medical Certificate
            if (leave.medicalCertificateUrl != null &&
                leave.medicalCertificateUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical Certificate',
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.description,
                          color: colorScheme.primary,
                        ),
                        title: const Text('Certificate'),
                        subtitle: Text(
                          leave.medicalCertificateUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.open_in_new,
                          color: colorScheme.primary,
                        ),
                        onTap: () {
                          // TODO: Open certificate URL
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Review Information
            if (leave.reviewedBy != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        'Reviewed By',
                        leave.reviewedBy!.name,
                        colorScheme,
                      ),
                      _buildInfoRow(
                        context,
                        'Role',
                        leave.reviewedBy!.role,
                        colorScheme,
                      ),
                      _buildInfoRow(
                        context,
                        'Email',
                        leave.reviewedBy!.email,
                        colorScheme,
                      ),
                      if (leave.reviewedAt != null)
                        _buildInfoRow(
                          context,
                          'Reviewed At',
                          DateFormat('dd MMM yyyy, hh:mm a').format(leave.reviewedAt!),
                          colorScheme,
                        ),
                      if (leave.reviewNote != null && leave.reviewNote!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Note',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            leave.reviewNote!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


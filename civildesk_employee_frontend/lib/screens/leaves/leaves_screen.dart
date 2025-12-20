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
  String? _selectedStatusFilter; // null means 'All'
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = null; // Show all by default
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).refreshLeaves();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMoreLeaves();
      }
    }
  }

  Future<void> _refreshLeaves() async {
    await Provider.of<LeaveProvider>(context, listen: false).refreshLeaves();
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
              if (!mounted) return;
              
              final messenger = ScaffoldMessenger.of(context);
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Leave deleted successfully')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Failed to delete leave'),
                  ),
                );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(leave.status, colorScheme);
    final statusIcon = _getStatusIcon(leave.status);
    final leaveTypeIcon = _getLeaveTypeIcon(leave.leaveType);
    final leaveTypeColor = _getLeaveTypeColor(leave.leaveType, colorScheme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              
              // Header Bar with Leave Type
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: leaveTypeColor.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: leaveTypeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        leaveTypeIcon,
                        size: 22,
                        color: leaveTypeColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + Leave Type
                    Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            leave.leaveTypeDisplay.toUpperCase(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            leave.statusDisplay.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurface,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Duration Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.calendar_today_rounded,
                        'Date & Duration',
                        [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                // Start Date
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Color(0xFF4CAF50),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Start Date',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(leave.startDate),
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: colorScheme.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // End Date
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE57373).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.stop_rounded,
                                          color: Color(0xFFE57373),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'End Date',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(leave.endDate),
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: colorScheme.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Duration
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.calendar_view_week_rounded,
                                          color: colorScheme.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Duration',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${leave.totalDays.toInt()} ${leave.totalDays == 1 ? 'day' : 'days'}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: colorScheme.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Reason for Leave Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.description_rounded,
                        'Reason for Leave',
                        [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.format_quote_rounded,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    leave.reason,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Contact Information Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.phone_rounded,
                        'Contact Information',
                        [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.phone_rounded,
                                    color: Color(0xFF4CAF50),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contact Number',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        leave.contactNumber,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Timeline Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.access_time_rounded,
                        'Timeline',
                        [
                          // Submitted
                          _buildTimelineItem(
                            theme,
                            colorScheme,
                            Icons.send_rounded,
                            'Submitted',
                            '${DateFormat('MMM dd, yyyy').format(leave.createdAt)} • ${DateFormat('hh:mm a').format(leave.createdAt)}',
                            colorScheme.primaryContainer,
                            true,
                          ),
                          // Reviewed (if exists)
                          if (leave.reviewedAt != null) ...[
                            const SizedBox(height: 8),
                            _buildTimelineItem(
                              theme,
                              colorScheme,
                              leave.status == LeaveStatus.APPROVED
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              leave.status == LeaveStatus.APPROVED
                                  ? 'Approved'
                                  : leave.status == LeaveStatus.REJECTED
                                      ? 'Rejected'
                                      : 'Reviewed',
                              '${DateFormat('MMM dd, yyyy').format(leave.reviewedAt!)} • ${DateFormat('hh:mm a').format(leave.reviewedAt!)}',
                              leave.status == LeaveStatus.APPROVED
                                  ? _getStatusColor(LeaveStatus.APPROVED, colorScheme).withValues(alpha: 0.2)
                                  : _getStatusColor(LeaveStatus.REJECTED, colorScheme).withValues(alpha: 0.2),
                              false,
                            ),
                          ],
                        ],
                      ),

                      // Handover Employees (if exists)
                      if (leave.handoverEmployees != null &&
                          leave.handoverEmployees!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          theme,
                          colorScheme,
                          Icons.people_rounded,
                  'Handover To',
                          leave.handoverEmployees!.map((employee) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Medical Certificate (if exists)
                      if (leave.medicalCertificateUrl != null &&
                          leave.medicalCertificateUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          theme,
                          colorScheme,
                          Icons.description_rounded,
                          'Medical Certificate',
                          [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
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
                            ),
                          ],
                        ),
                      ],

                      // Review Information (if exists)
              if (leave.reviewedBy != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          theme,
                          colorScheme,
                          Icons.verified_user_rounded,
                          'Review Information',
                          [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(theme, colorScheme, 'Reviewed By', leave.reviewedBy!.name),
                                  _buildDetailRow(theme, colorScheme, 'Role', leave.reviewedBy!.role),
                                  _buildDetailRow(theme, colorScheme, 'Email', leave.reviewedBy!.email),
                if (leave.reviewedAt != null)
                  _buildDetailRow(
                                      theme,
                                      colorScheme,
                    'Reviewed At',
                                      DateFormat('MMM dd, yyyy, hh:mm a').format(leave.reviewedAt!),
                                    ),
                                  if (leave.reviewNote != null && leave.reviewNote!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.comment_rounded,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              leave.reviewNote!,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: colorScheme.onSurface,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
              ],
            ],
          ),
        ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String subtitle,
    Color iconBackgroundColor,
    bool showLine,
  ) {
    // Determine icon color based on background
    Color iconColor;
    if (iconBackgroundColor == colorScheme.primaryContainer) {
      iconColor = colorScheme.primary;
    } else if (iconBackgroundColor == _getStatusColor(LeaveStatus.APPROVED, colorScheme).withValues(alpha: 0.2)) {
      iconColor = _getStatusColor(LeaveStatus.APPROVED, colorScheme);
    } else {
      iconColor = _getStatusColor(LeaveStatus.REJECTED, colorScheme);
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              if (showLine) ...[
                const SizedBox(height: 4),
                Container(
                  width: 2,
                  height: 20,
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ],
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, ColorScheme colorScheme, String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return EmployeeLayout(
      currentRoute: AppRoutes.leaves,
      title: const Text('My Leaves'),
      actions: [
        IconButton(
          onPressed: _navigateToApplyLeave,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Apply Leave',
        ),
      ],
      child: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'All',
                    _selectedStatusFilter == null,
                    () {
                      setState(() {
                        _selectedStatusFilter = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'Pending',
                    _selectedStatusFilter == 'PENDING',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'PENDING';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'Approved',
                    _selectedStatusFilter == 'APPROVED',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'APPROVED';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'Rejected',
                    _selectedStatusFilter == 'REJECTED',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'REJECTED';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Leaves List
          Expanded(
            child: Consumer<LeaveProvider>(
              builder: (context, provider, child) {
                // Filter leaves based on selected status
                final filteredLeaves = _selectedStatusFilter == null
                    ? provider.leaves
                    : provider.leaves.where((leave) {
                        return leave.status.toString().split('.').last == _selectedStatusFilter;
                      }).toList();
                
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  final theme = Theme.of(context);
                  final colorScheme = theme.colorScheme;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: _getErrorColor(colorScheme),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
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
                  final theme = Theme.of(context);
                  final colorScheme = theme.colorScheme;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_busy_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                        const SizedBox(height: 24),
                        Text(
                          'No Leave Applications',
                              style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'You haven\'t applied for any leaves yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _navigateToApplyLeave,
                              icon: const Icon(Icons.add_rounded),
                          label: const Text('Apply for Leave'),
                        ),
                      ],
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshLeaves,
                  color: Theme.of(context).colorScheme.primary,
                  child: filteredLeaves.isEmpty && provider.leaves.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off_rounded,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${_selectedStatusFilter?.toLowerCase() ?? ''} leaves found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                          itemCount: filteredLeaves.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredLeaves.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final leave = filteredLeaves[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 0),
                              child: _buildLeaveCard(leave),
                            );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(leave.status, colorScheme);
    final statusIcon = _getStatusIcon(leave.status);
    final statusLabel = leave.statusDisplay.toUpperCase();
    final leaveTypeIcon = _getLeaveTypeIcon(leave.leaveType);
    final leaveTypeColor = _getLeaveTypeColor(leave.leaveType, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shadowColor: Colors.transparent,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewLeaveDetails(leave),
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Leave Type Icon + Title + Duration + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Icon + Leave Type + Duration
                  Expanded(
                    child: Row(
                      children: [
                        // Leave Type Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: leaveTypeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            leaveTypeIcon,
                            size: 22,
                            color: leaveTypeColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Leave Type + Duration
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leave.leaveTypeDisplay.toUpperCase(),
                                style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_view_week_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${leave.totalDays.toInt()} ${leave.totalDays == 1 ? 'day' : 'days'}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date Range Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                children: [
                    // From Date
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                  Text(
                                  'From',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(leave.startDate),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                      ),
                                ),
                              ],
                    ),
                  ),
                ],
              ),
                    ),
                    // Arrow
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // To Date
                    Expanded(
                      child: Row(
                  children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                    Text(
                                  'To',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(leave.endDate),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Reason
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                leave.reason,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ],
              ),
              
              // Admin Comment (if exists)
              if (leave.reviewNote != null && leave.reviewNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Icon(
                        Icons.comment_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Text(
                              'Admin Comment',
                              style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              leave.reviewNote!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Submitted timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Submitted: ${DateFormat('MMM dd, yyyy').format(leave.createdAt)} • ${DateFormat('hh:mm a').format(leave.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
              
              // Actions (only for pending)
              if (leave.status == LeaveStatus.PENDING) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: OutlinedButton.icon(
                      onPressed: () => _editLeave(leave),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete Button
                    Expanded(
                      child: ElevatedButton.icon(
                      onPressed: () => _deleteLeave(leave),
                        icon: const Icon(Icons.delete_rounded, size: 18),
                      label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getErrorColor(colorScheme),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                      ),
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

  IconData _getLeaveTypeIcon(LeaveType leaveType) {
    switch (leaveType) {
      case LeaveType.SICK_LEAVE:
        return Icons.medical_services_rounded;
      case LeaveType.CASUAL_LEAVE:
        return Icons.beach_access_rounded;
      case LeaveType.ANNUAL_LEAVE:
        return Icons.beach_access_rounded;
      case LeaveType.MATERNITY_LEAVE:
        return Icons.child_care_rounded;
      case LeaveType.PATERNITY_LEAVE:
        return Icons.family_restroom_rounded;
      case LeaveType.MEDICAL_LEAVE:
        return Icons.local_hospital_rounded;
      case LeaveType.EMERGENCY_LEAVE:
        return Icons.emergency_rounded;
      case LeaveType.UNPAID_LEAVE:
        return Icons.money_off_rounded;
      case LeaveType.COMPENSATORY_OFF:
        return Icons.event_available_rounded;
    }
  }

  Color _getLeaveTypeColor(LeaveType leaveType, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    switch (leaveType) {
      case LeaveType.SICK_LEAVE:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F);
      case LeaveType.CASUAL_LEAVE:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      case LeaveType.ANNUAL_LEAVE:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      case LeaveType.MATERNITY_LEAVE:
      case LeaveType.PATERNITY_LEAVE:
        return isDark ? const Color(0xFFBA68C8) : const Color(0xFF9C27B0);
      case LeaveType.MEDICAL_LEAVE:
        return isDark ? const Color(0xFF81C784) : const Color(0xFF388E3C);
      case LeaveType.EMERGENCY_LEAVE:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F);
      case LeaveType.UNPAID_LEAVE:
        return colorScheme.onSurfaceVariant;
      case LeaveType.COMPENSATORY_OFF:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    }
  }

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

  Color _getErrorColor(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? const Color(0xFFEF5350) // More vibrant red for dark mode
        : const Color(0xFFC62828);
  }
}


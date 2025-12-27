import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/employee_layout.dart';
import '../../core/providers/overtime_provider.dart';
import '../../models/overtime.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/toast.dart';
import 'apply_overtime_screen.dart';

class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  String? _selectedStatusFilter; // null means 'All'
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = null; // Show all by default
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OvertimeProvider>(context, listen: false).refreshOvertimes();
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
      final provider = Provider.of<OvertimeProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMoreOvertimes();
      }
    }
  }

  Future<void> _refreshOvertimes() async {
    await Provider.of<OvertimeProvider>(context, listen: false).refreshOvertimes();
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
      Toast.warning(context, 'Only pending overtimes can be edited');
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
      Toast.warning(context, 'Only pending overtimes can be deleted');
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
              if (!mounted || !context.mounted) return;
              
              if (success) {
                Toast.success(context, 'Overtime deleted successfully');
              } else {
                Toast.error(context, provider.error ?? 'Failed to delete overtime');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(overtime.status, colorScheme);
    final statusIcon = _getStatusIcon(overtime.status);

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
              
              // Header Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.15),
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
                        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overtime Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
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
                            overtime.statusDisplay.toUpperCase(),
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
                      // Date & Time Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.calendar_today_rounded,
                        'Date & Time',
                        [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                // Date
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
                                          Icons.calendar_today_rounded,
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
                                              'Date',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(overtime.date),
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
                                // Start Time
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
                                              'Start Time',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              overtime.startTime,
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
                                // End Time
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
                                              'End Time',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              overtime.endTime,
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
                      
                      // Reason Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.description_rounded,
                        'Reason',
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
                                    overtime.reason,
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
                            DateUtils.formatIndiaDateTime(overtime.createdAt),
                            colorScheme.primaryContainer,
                            true,
                          ),
                          // Reviewed (if exists)
                          if (overtime.reviewedAt != null) ...[
                            const SizedBox(height: 8),
                            _buildTimelineItem(
                              theme,
                              colorScheme,
                              overtime.status == OvertimeStatus.APPROVED
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              overtime.status == OvertimeStatus.APPROVED
                                  ? 'Approved'
                                  : 'Rejected',
                              DateUtils.formatIndiaDateTime(overtime.reviewedAt!),
                              overtime.status == OvertimeStatus.APPROVED
                                  ? _getStatusColor(OvertimeStatus.APPROVED, colorScheme).withValues(alpha: 0.2)
                                  : _getStatusColor(OvertimeStatus.REJECTED, colorScheme).withValues(alpha: 0.2),
                              false,
                            ),
                          ],
                        ],
                      ),

                      // Review Information (if exists)
                      if (overtime.reviewedBy != null) ...[
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
                                  _buildDetailRow(theme, colorScheme, 'Reviewed By', overtime.reviewedBy!.name),
                                  _buildDetailRow(theme, colorScheme, 'Role', overtime.reviewedBy!.role),
                                  _buildDetailRow(theme, colorScheme, 'Email', overtime.reviewedBy!.email),
                                  if (overtime.reviewedAt != null)
                                    _buildDetailRow(
                                      theme,
                                      colorScheme,
                                      'Reviewed At',
                                      DateFormat('MMM dd, yyyy, hh:mm a').format(overtime.reviewedAt!),
                                    ),
                                  if (overtime.reviewNote != null && overtime.reviewNote!.isNotEmpty) ...[
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
                                              overtime.reviewNote!,
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
    Color iconColor;
    if (iconBackgroundColor == colorScheme.primaryContainer) {
      iconColor = colorScheme.primary;
    } else if (iconBackgroundColor == _getStatusColor(OvertimeStatus.APPROVED, colorScheme).withValues(alpha: 0.2)) {
      iconColor = _getStatusColor(OvertimeStatus.APPROVED, colorScheme);
    } else {
      iconColor = _getStatusColor(OvertimeStatus.REJECTED, colorScheme);
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

  IconData _getStatusIcon(OvertimeStatus status) {
    switch (status) {
      case OvertimeStatus.APPROVED:
        return Icons.check_circle;
      case OvertimeStatus.PENDING:
        return Icons.pending;
      case OvertimeStatus.REJECTED:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return EmployeeLayout(
      currentRoute: AppRoutes.overtime,
      title: const Text('My Overtimes'),
      actions: [
        IconButton(
          onPressed: _navigateToApplyOvertime,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Apply Overtime',
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
          // Overtimes List
          Expanded(
            child: Consumer<OvertimeProvider>(
              builder: (context, provider, child) {
                // Filter overtimes based on selected status
                final filteredOvertimes = _selectedStatusFilter == null
                    ? provider.overtimes
                    : provider.overtimes.where((overtime) {
                        return overtime.status.toString().split('.').last == _selectedStatusFilter;
                      }).toList();
                
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
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
                          onPressed: _refreshOvertimes,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.overtimes.isEmpty) {
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
                                Icons.schedule_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Overtime Applications',
                              style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'You haven\'t applied for any overtimes yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _navigateToApplyOvertime,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Apply for Overtime'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshOvertimes,
                  color: Theme.of(context).colorScheme.primary,
                  child: filteredOvertimes.isEmpty && provider.overtimes.isNotEmpty
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
                                'No ${_selectedStatusFilter?.toLowerCase() ?? ''} overtimes found',
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
                          itemCount: filteredOvertimes.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredOvertimes.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final overtime = filteredOvertimes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 0),
                              child: _buildOvertimeCard(overtime),
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

  Widget _buildOvertimeCard(Overtime overtime) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(overtime.status, colorScheme);
    final statusIcon = _getStatusIcon(overtime.status);
    final statusLabel = overtime.statusDisplay.toUpperCase();

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
        onTap: () => _viewOvertimeDetails(overtime),
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Title + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Icon + Title
                  Expanded(
                    child: Row(
                      children: [
                        // Overtime Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OVERTIME REQUEST',
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
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(overtime.date),
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
              
              // Time Range Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Start Time
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  overtime.startTime,
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
                    // End Time
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.stop_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  overtime.endTime,
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
                      overtime.reason,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ],
              ),
              
              // Admin Comment (if exists)
              if (overtime.reviewNote != null && overtime.reviewNote!.isNotEmpty) ...[
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
                              overtime.reviewNote!,
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
                    'Submitted: ${DateFormat('MMM dd, yyyy').format(overtime.createdAt)} • ${DateFormat('hh:mm a').format(overtime.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
              
              // Actions (only for pending)
              if (overtime.status == OvertimeStatus.PENDING) ...[
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
                        onPressed: () => _editOvertime(overtime),
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
                        onPressed: () => _deleteOvertime(overtime),
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

  Color _getStatusColor(OvertimeStatus status, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    switch (status) {
      case OvertimeStatus.APPROVED:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case OvertimeStatus.PENDING:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      case OvertimeStatus.REJECTED:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
    }
  }

  Color _getErrorColor(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? const Color(0xFFEF5350) // More vibrant red for dark mode
        : const Color(0xFFC62828);
  }
}

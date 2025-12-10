import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin_layout.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/leave_provider.dart';
import '../../models/leave.dart';
import 'leave_detail_screen.dart';

class LeavesManagementScreen extends StatefulWidget {
  const LeavesManagementScreen({Key? key}) : super(key: key);

  @override
  State<LeavesManagementScreen> createState() => _LeavesManagementScreenState();
}

class _LeavesManagementScreenState extends State<LeavesManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).fetchAllLeaves();
    });
  }

  Future<void> _refreshLeaves() async {
    await Provider.of<LeaveProvider>(context, listen: false).fetchAllLeaves();
  }

  void _showFilterDialog() {
    final provider = Provider.of<LeaveProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Leaves'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: provider.selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'All Statuses',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...LeaveStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status.toString().split('.').last,
                          child: Text(status.displayName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      provider.setStatusFilter(value);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  // Leave Type Filter
                  const Text(
                    'Leave Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: provider.selectedLeaveType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'All Leave Types',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Leave Types')),
                      ...LeaveType.values.map((type) {
                        return DropdownMenuItem(
                          value: type.toString().split('.').last,
                          child: Text(type.displayName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      provider.setLeaveTypeFilter(value);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  // Department Filter
                  const Text(
                    'Department',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: provider.selectedDepartment,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'All Departments',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Departments')),
                      ...provider.departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      provider.setDepartmentFilter(value);
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('CLEAR ALL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  void _viewLeaveDetails(Leave leave) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveDetailScreen(leave: leave),
      ),
    );
    
    if (result == true) {
      _refreshLeaves();
    }
  }

  void _showReviewDialog(Leave leave, LeaveStatus status) {
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == LeaveStatus.APPROVED ? 'Approve Leave' : 'Reject Leave',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${status == LeaveStatus.APPROVED ? 'approve' : 'reject'} this leave application?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
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
            onPressed: () async {
              Navigator.pop(context);
              await _reviewLeave(leave, status, noteController.text.trim().isEmpty ? null : noteController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == LeaveStatus.APPROVED 
                  ? Colors.green 
                  : Colors.red,
            ),
            child: Text(
              status == LeaveStatus.APPROVED ? 'APPROVE' : 'REJECT',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewLeave(Leave leave, LeaveStatus status, String? note) async {
    final provider = Provider.of<LeaveProvider>(context, listen: false);
    
    final success = await provider.reviewLeave(leave.id, status, note);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Leave ${status == LeaveStatus.APPROVED ? 'approved' : 'rejected'} successfully',
            ),
            backgroundColor: status == LeaveStatus.APPROVED ? Colors.green : Colors.red,
          ),
        );
        _refreshLeaves();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to review leave'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: const Text('Leave Management'),
      currentRoute: AppRoutes.adminLeave,
      actions: [
        Consumer<LeaveProvider>(
          builder: (context, provider, child) {
            int activeFilters = 0;
            if (provider.selectedStatus != null) activeFilters++;
            if (provider.selectedLeaveType != null) activeFilters++;
            if (provider.selectedDepartment != null) activeFilters++;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showFilterDialog,
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: Text(activeFilters > 0 ? 'Filters ($activeFilters)' : 'Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeFilters > 0 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      foregroundColor: activeFilters > 0
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
      child: Column(
        children: [
          // Leaves Grid
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
                        const SizedBox(height: 8),
                        Text(
                          'No leaves found matching the filters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshLeaves,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Mobile: < 600px (card view)
                      // Tablet/Desktop: >= 600px (list view)
                      final isMobile = constraints.maxWidth < 600;
                      
                      if (isMobile) {
                        // Card view for mobile
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.leaves.length,
                          itemBuilder: (context, index) {
                            final leave = provider.leaves[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildLeaveCard(leave),
                            );
                          },
                        );
                      } else {
                        // Table view for tablet/desktop
                        return _buildLeavesTable(provider.leaves);
                      }
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewLeaveDetails(leave),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.employeeName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${leave.employeeIdStr} • ${leave.designation ?? "N/A"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          leave.statusDisplay.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Leave Summary Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      leave.leaveTypeDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${leave.totalDays} ${leave.totalDays == 1 ? 'day' : 'days'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Date Range
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${DateFormat('dd MMM').format(leave.startDate)} – ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Department (if exists)
              if (leave.department != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        leave.department!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Reason Preview
              Text(
                leave.reason,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Divider before actions
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              
              const SizedBox(height: 12),
              
              // Action Buttons Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (leave.status == LeaveStatus.PENDING) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewDialog(leave, LeaveStatus.REJECTED),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade600),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReviewDialog(leave, LeaveStatus.APPROVED),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewLeaveDetails(leave),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeavesTable(List<Leave> leaves) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth - 32 : 1000.0;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(1.8),
                          4: FlexColumnWidth(2.0),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        children: [
                          // Table Header
                          TableRow(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                            ),
                            children: [
                              _buildTableHeaderCell('Employee', Icons.person),
                              _buildTableHeaderCell('Status', Icons.info),
                              _buildTableHeaderCell('Leave Type', Icons.event_note),
                              _buildTableHeaderCell('Date Range', Icons.calendar_today),
                              _buildTableHeaderCell('Actions', Icons.more_vert),
                            ],
                          ),
                          // Table Rows with alternating colors
                          ...leaves.asMap().entries.map((entry) {
                            final index = entry.key;
                            final leave = entry.value;
                            return _buildTableRow(leave, index);
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text, IconData icon) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(Leave leave, int index) {
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

    // Alternating row colors
    final isEven = index % 2 == 0;
    final rowColor = isEven
        ? Colors.transparent
        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2);

    return TableRow(
      decoration: BoxDecoration(
        color: rowColor,
      ),
      children: [
        // Employee Info Cell
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () => _viewLeaveDetails(leave),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              leave.employeeName.isNotEmpty
                                  ? leave.employeeName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                leave.employeeName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${leave.employeeIdStr} • ${leave.designation ?? "N/A"}${leave.department != null ? ' • ${leave.department}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Status Cell
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      leave.statusDisplay.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Leave Type Cell
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_note, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          leave.leaveTypeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${leave.totalDays} ${leave.totalDays == 1 ? 'day' : 'days'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Date Range Cell
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${DateFormat('dd MMM').format(leave.startDate)} – ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Actions Cell
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildTableActionButtons(leave),
          ),
        ),
      ],
    );
  }

  Widget _buildTableActionButtons(Leave leave) {
    if (leave.status == LeaveStatus.PENDING) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: OutlinedButton.icon(
                onPressed: () => _showReviewDialog(leave, LeaveStatus.REJECTED),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade700, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                onPressed: () => _showReviewDialog(leave, LeaveStatus.APPROVED),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: OutlinedButton.icon(
          onPressed: () => _viewLeaveDetails(leave),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View Details'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLeaveListItem(Leave leave) {
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewLeaveDetails(leave),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;
              
              if (isCompact) {
                // Vertical stack for smaller tablets
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEmployeeInfoRow(leave, statusColor, statusIcon),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLeaveSummary(leave),
                        const SizedBox(width: 16),
                        _buildDateRange(leave),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildActionButtons(leave, isVertical: true),
                  ],
                );
              }
              
              // Horizontal layout for desktop
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee Info
                  Flexible(
                    flex: 2,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
                      child: _buildEmployeeInfoColumn(leave, statusColor, statusIcon),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Leave Summary
                  Flexible(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
                      child: _buildLeaveSummary(leave),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Date Range
                  Flexible(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 130, maxWidth: 180),
                      child: _buildDateRange(leave),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Actions - Flexible to prevent overflow
                  Flexible(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
                      child: _buildActionButtons(leave, isVertical: false),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoColumn(Leave leave, Color statusColor, IconData statusIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                leave.employeeName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    leave.statusDisplay.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${leave.employeeIdStr} • ${leave.designation ?? "N/A"}${leave.department != null ? ' • ${leave.department}' : ''}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmployeeInfoRow(Leave leave, Color statusColor, IconData statusIcon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leave.employeeName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${leave.employeeIdStr} • ${leave.designation ?? "N/A"}${leave.department != null ? ' • ${leave.department}' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                leave.statusDisplay.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveSummary(Leave leave) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            leave.leaveTypeDisplay,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${leave.totalDays} ${leave.totalDays == 1 ? 'day' : 'days'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRange(Leave leave) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${DateFormat('dd MMM').format(leave.startDate)} – ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Leave leave, {required bool isVertical}) {
    if (isVertical) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (leave.status == LeaveStatus.PENDING) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showReviewDialog(leave, LeaveStatus.REJECTED),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade600),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showReviewDialog(leave, LeaveStatus.APPROVED),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewLeaveDetails(leave),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Horizontal layout - compact buttons that fit in available space
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leave.status == LeaveStatus.PENDING) ...[
          Flexible(
            child: OutlinedButton.icon(
              onPressed: () => _showReviewDialog(leave, LeaveStatus.REJECTED),
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade600),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ElevatedButton.icon(
              onPressed: () => _showReviewDialog(leave, LeaveStatus.APPROVED),
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ] else ...[
          Flexible(
            child: OutlinedButton.icon(
              onPressed: () => _viewLeaveDetails(leave),
              icon: const Icon(Icons.visibility, size: 14),
              label: const Text('View'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

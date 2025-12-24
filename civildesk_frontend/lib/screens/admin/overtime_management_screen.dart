import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin_layout.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/overtime_provider.dart';
import '../../models/overtime.dart';
import 'overtime_detail_screen.dart';

class OvertimeManagementScreen extends StatefulWidget {
  const OvertimeManagementScreen({super.key});

  @override
  State<OvertimeManagementScreen> createState() => _OvertimeManagementScreenState();
}

class _OvertimeManagementScreenState extends State<OvertimeManagementScreen> {
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
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
    if (!_scrollController.hasClients || !mounted) return;
    
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.9) {
      final provider = Provider.of<OvertimeProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMoreOvertimes();
      }
    } else if (maxScroll <= 0 && position.viewportDimension > 0) {
      final provider = Provider.of<OvertimeProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading && provider.overtimes.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && provider.hasMore && !provider.isLoading) {
            provider.loadMoreOvertimes();
          }
        });
      }
    }
  }

  Future<void> _refreshOvertimes() async {
    await Provider.of<OvertimeProvider>(context, listen: false).refreshOvertimes();
  }

  void _showFilterDialog() {
    final provider = Provider.of<OvertimeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Overtimes'),
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
                    initialValue: provider.selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'All Statuses',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...OvertimeStatus.values.map((status) {
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
                  // Department Filter
                  const Text(
                    'Department',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: provider.selectedDepartment,
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

  void _viewOvertimeDetails(Overtime overtime) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OvertimeDetailScreen(overtime: overtime),
      ),
    );
    
    if (result == true) {
      _refreshOvertimes();
    }
  }

  void _showReviewDialog(Overtime overtime, OvertimeStatus status) {
    final TextEditingController noteController = TextEditingController();
    
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
              await _reviewOvertime(overtime, status, noteController.text.trim().isEmpty ? null : noteController.text.trim());
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

  Future<void> _reviewOvertime(Overtime overtime, OvertimeStatus status, String? note) async {
    final provider = Provider.of<OvertimeProvider>(context, listen: false);
    
    final success = await provider.reviewOvertime(overtime.id, status, note);
    
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
        _refreshOvertimes();
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

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    
    return AdminLayout(
      title: const Text('Overtime Management'),
      currentRoute: AppRoutes.adminOvertime,
      actions: [
        Consumer<OvertimeProvider>(
          builder: (context, provider, child) {
            int activeFilters = 0;
            if (provider.selectedStatus != null) activeFilters++;
            if (provider.selectedDepartment != null) activeFilters++;

            if (isMobile) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterDialog,
                    tooltip: activeFilters > 0 ? 'Filters ($activeFilters)' : 'Filter',
                  ),
                  if (activeFilters > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    ),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(activeFilters > 0 ? 'Filters ($activeFilters)' : 'Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeFilters > 0 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  foregroundColor: activeFilters > 0
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            );
          },
        ),
      ],
      child: Column(
        children: [
          // Overtimes Grid
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
                        const SizedBox(height: 8),
                        Text(
                          'No overtimes found matching the filters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshOvertimes,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Mobile: < 600px (card view)
                      // Tablet/Desktop: >= 600px (table view)
                      final isMobile = constraints.maxWidth < 600;
                      
                      if (isMobile) {
                        // Check if we need to load more when content fits on screen
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients && mounted) {
                            final position = _scrollController.position;
                            if (position.maxScrollExtent <= 0 && 
                                position.viewportDimension > 0 &&
                                provider.hasMore && 
                                !provider.isLoading && 
                                provider.overtimes.isNotEmpty) {
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted && provider.hasMore && !provider.isLoading) {
                                  provider.loadMoreOvertimes();
                                }
                              });
                            }
                          }
                        });

                        // Card view for mobile with pagination
                        return NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            if (notification is ScrollEndNotification) {
                              final metrics = notification.metrics;
                              if (metrics.pixels >= metrics.maxScrollExtent * 0.9) {
                                if (provider.hasMore && !provider.isLoading) {
                                  provider.loadMoreOvertimes();
                                }
                              }
                            }
                            return false;
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.overtimes.length + (provider.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == provider.overtimes.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final overtime = provider.overtimes[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildOvertimeCard(overtime),
                              );
                            },
                          ),
                        );
                      } else {
                        // Table view for tablet/desktop
                        return _buildOvertimesTable(provider.overtimes, provider.hasMore);
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewOvertimeDetails(overtime),
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
                          overtime.employeeName,
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
                          '${overtime.employeeIdStr} • ${overtime.designation ?? "N/A"}',
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
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          overtime.statusDisplay.toUpperCase(),
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
              
              // Overtime Summary Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _calculateHours(overtime.startTime, overtime.endTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Date
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
                      DateFormat('dd MMM yyyy').format(overtime.date),
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
              const SizedBox(height: 8),
              // Time Range
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${overtime.startTime} - ${overtime.endTime}',
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
              if (overtime.department != null) ...[
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
                        overtime.department!,
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
                overtime.reason,
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
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
              
              const SizedBox(height: 12),
              
              // Action Buttons Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (overtime.status == OvertimeStatus.PENDING) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewDialog(overtime, OvertimeStatus.REJECTED),
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
                        onPressed: () => _showReviewDialog(overtime, OvertimeStatus.APPROVED),
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
                        onPressed: () => _viewOvertimeDetails(overtime),
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

  String _calculateHours(String startTime, String endTime) {
    try {
      // Parse time strings (format: "HH:mm")
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      if (startParts.length < 2 || endParts.length < 2) {
        return 'N/A';
      }
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      // Convert to minutes for easier calculation
      int startMinutes = startHour * 60 + startMinute;
      int endMinutes = endHour * 60 + endMinute;
      
      // Handle overnight (end time is next day)
      if (endMinutes <= startMinutes) {
        endMinutes += 24 * 60; // Add 24 hours
      }
      
      final totalMinutes = endMinutes - startMinutes;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      
      if (hours == 0 && minutes == 0) {
        return '0 hours';
      } else if (hours == 0) {
        return '$minutes ${minutes == 1 ? 'min' : 'mins'}';
      } else if (minutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        // Show hours with decimal (e.g., 2.5 hours)
        final decimalHours = hours + (minutes / 60);
        return '${decimalHours.toStringAsFixed(1)} hours';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildOvertimesTable(List<Overtime> overtimes, bool hasMore) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth - 32 : 1000.0;
        
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final provider = Provider.of<OvertimeProvider>(context, listen: false);
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent * 0.9) {
                if (provider.hasMore && !provider.isLoading) {
                  provider.loadMoreOvertimes();
                }
              }
            }
            return false;
          },
          child: SingleChildScrollView(
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
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                              width: 1,
                            ),
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          children: [
                            // Table Header
                            TableRow(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                              children: [
                                _buildTableHeaderCell('Employee', Icons.person),
                                _buildTableHeaderCell('Status', Icons.info),
                                _buildTableHeaderCell('Date & Time', Icons.access_time),
                                _buildTableHeaderCell('Date', Icons.calendar_today),
                                _buildTableHeaderCell('Actions', Icons.more_vert),
                              ],
                            ),
                            // Table Rows with alternating colors
                            ...overtimes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final overtime = entry.value;
                              return _buildOvertimeTableRow(overtime, index);
                            }),
                            // Loading indicator row
                            if (hasMore)
                              TableRow(
                                children: [
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                  ),
                                  const TableCell(child: SizedBox()),
                                  const TableCell(child: SizedBox()),
                                  const TableCell(child: SizedBox()),
                                  const TableCell(child: SizedBox()),
                                ],
                              ),
                          ],
                        ),
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

  TableRow _buildOvertimeTableRow(Overtime overtime, int index) {
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

    // Alternating row colors
    final isEven = index % 2 == 0;
    final rowColor = isEven
        ? Colors.transparent
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);

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
              onTap: () => _viewOvertimeDetails(overtime),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            overtime.employeeName.isNotEmpty
                                ? overtime.employeeName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
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
                                overtime.employeeName,
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
                                '${overtime.employeeIdStr} • ${overtime.designation ?? "N/A"}${overtime.department != null ? ' • ${overtime.department}' : ''}',
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
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
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
                      overtime.statusDisplay.toUpperCase(),
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
        // Time Range Cell
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${overtime.startTime} - ${overtime.endTime}',
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
        // Date Cell
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                      DateFormat('dd MMM yyyy').format(overtime.date),
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
            child: _buildOvertimeTableActionButtons(overtime),
          ),
        ),
      ],
    );
  }

  Widget _buildOvertimeTableActionButtons(Overtime overtime) {
    if (overtime.status == OvertimeStatus.PENDING) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: OutlinedButton.icon(
                onPressed: () => _showReviewDialog(overtime, OvertimeStatus.REJECTED),
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
                onPressed: () => _showReviewDialog(overtime, OvertimeStatus.APPROVED),
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
          onPressed: () => _viewOvertimeDetails(overtime),
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
}

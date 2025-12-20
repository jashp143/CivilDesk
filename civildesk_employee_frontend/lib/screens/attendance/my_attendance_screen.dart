import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/attendance_provider.dart';
import '../../models/attendance.dart';
import '../../widgets/employee_layout.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;
  final List<String> _statusOptions = [
    'All',
    'Present',
    'Absent',
    'Half Day',
    'On Leave',
    'Late',
    'Not Marked',
  ];
  bool _isStatsExpanded = false; // Statistics collapsed by default
  final Set<String> _expandedDates = {}; // Track expanded timeline items
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    // Ensure end date doesn't exceed today
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    _endDate = lastDayOfMonth.isAfter(now) ? now : lastDayOfMonth;
    _selectedStatus = 'All';
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Note: This is for CustomScrollView, pagination handled differently
  }

  Future<void> _loadAttendance({bool refresh = true}) async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    await provider.fetchAttendanceHistory(
      startDate: _startDate,
      endDate: _endDate,
      refresh: refresh,
    );
  }

  Future<void> _loadMoreAttendance() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    if (provider.hasMore && !provider.isLoading) {
      await provider.loadMoreAttendance(
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final initialStart = _startDate ?? now.subtract(const Duration(days: 30));
    final initialEnd = _endDate ?? now;

    // Ensure initial dates don't exceed lastDate
    final safeStart = initialStart.isAfter(now)
        ? now.subtract(const Duration(days: 30))
        : initialStart;
    final safeEnd = initialEnd.isAfter(now) ? now : initialEnd;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: safeStart, end: safeEnd),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAttendance(refresh: true);
    }
  }

  List<Attendance> _getFilteredAttendance() {
    final provider = Provider.of<AttendanceProvider>(context);
    List<Attendance> filtered = List.from(provider.attendanceList);

    if (_selectedStatus != null && _selectedStatus != 'All') {
      filtered = filtered.where((attendance) {
        final status = attendance.status.toUpperCase();
        switch (_selectedStatus) {
          case 'Present':
            return status == 'PRESENT';
          case 'Absent':
            return status == 'ABSENT';
          case 'Half Day':
            return status == 'HALF_DAY';
          case 'On Leave':
            return status == 'ON_LEAVE' || status == 'LEAVE';
          case 'Late':
            return status == 'LATE';
          case 'Not Marked':
            return status == 'NOT_MARKED';
          default:
            return true;
        }
      }).toList();
    }

    // Sort by date descending (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Map<String, dynamic> _calculateStats() {
    final provider = Provider.of<AttendanceProvider>(context);
    final attendances = provider.attendanceList;

    int totalPresent = 0;
    int totalAbsent = 0;
    int totalHalfDay = 0;
    int totalLeave = 0;
    int totalLate = 0;
    double totalWorkingHours = 0;
    double totalOvertimeHours = 0;

    for (var attendance in attendances) {
      final status = attendance.status.toUpperCase();
      switch (status) {
        case 'PRESENT':
          totalPresent++;
          break;
        case 'ABSENT':
          totalAbsent++;
          break;
        case 'HALF_DAY':
          totalHalfDay++;
          break;
        case 'ON_LEAVE':
        case 'LEAVE':
          totalLeave++;
          break;
        case 'LATE':
          totalLate++;
          break;
      }

      if (attendance.workingHours != null) {
        totalWorkingHours += attendance.workingHours!;
      }
      if (attendance.overtimeHours != null) {
        totalOvertimeHours += attendance.overtimeHours!;
      }
    }

    final totalDays = attendances.length;
    final attendancePercentage = totalDays > 0
        ? ((totalPresent + totalHalfDay) / totalDays * 100)
        : 0.0;

    return {
      'totalDays': totalDays,
      'totalPresent': totalPresent,
      'totalAbsent': totalAbsent,
      'totalHalfDay': totalHalfDay,
      'totalLeave': totalLeave,
      'totalLate': totalLate,
      'totalWorkingHours': totalWorkingHours,
      'totalOvertimeHours': totalOvertimeHours,
      'attendancePercentage': attendancePercentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final filteredAttendance = _getFilteredAttendance();
    final stats = _calculateStats();

    return EmployeeLayout(
      currentRoute: AppRoutes.myAttendance,
      title: const Text('My Attendance'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(),
          tooltip: 'Filter',
        ),
      ],
      child: CustomScrollView(
        slivers: [
          // Stats Section (Collapsible)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with toggle
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isStatsExpanded = !_isStatsExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Statistics',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            _isStatsExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Collapsible content
                  AnimatedCrossFade(
                    firstChild: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        // Responsive grid: 3 columns for large screens, 2 for medium, 1 for small
                        int crossAxisCount;
                        double childAspectRatio;
                        
                        if (screenWidth > 600) {
                          crossAxisCount = 3;
                          childAspectRatio = 1.8; // More height for content
                        } else if (screenWidth > 400) {
                          crossAxisCount = 2;
                          childAspectRatio = 2.0; // More height for content
                        } else {
                          crossAxisCount = 2;
                          childAspectRatio = 2.2; // More height for narrow screens
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: childAspectRatio,
                            children: [
                              _buildStatCard(
                                'Present',
                                stats['totalPresent'].toString(),
                                const Color(0xFF16A34A), // success green
                              ),
                              _buildStatCard(
                                'Absent',
                                stats['totalAbsent'].toString(),
                                const Color(0xFFEF4444), // danger red
                              ),
                              _buildStatCard(
                                'Attendance',
                                '${stats['attendancePercentage'].toStringAsFixed(1)}%',
                                const Color(0xFF2563EB), // info blue
                              ),
                              _buildStatCard(
                                'Working Hours',
                                _formatHours(stats['totalWorkingHours']),
                                const Color(0xFF2563EB), // info blue
                              ),
                              _buildStatCard(
                                'Overtime',
                                _formatHours(stats['totalOvertimeHours']),
                                const Color(0xFFF59E0B), // warn orange
                              ),
                              _buildStatCard(
                                'Total Days',
                                stats['totalDays'].toString(),
                                const Color(0xFF6B7280), // gray
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: _isStatsExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),

          // Sticky Date Range Filter Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              minHeight: 44,
              maxHeight: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:
                        Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.04,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                            : 'Select date range',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Change date range',
                      button: true,
                      child: TextButton(
                        onPressed: _selectDateRange,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(
                            44,
                            44,
                          ), // Minimum touch target
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Timeline View
          provider.isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : filteredAttendance.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance records found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == filteredAttendance.length) {
                        // Loading indicator at the end
                        if (provider.hasMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadMoreAttendance();
                          });
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final attendance = filteredAttendance[index];
                      final isLast = index == filteredAttendance.length - 1 && !provider.hasMore;
                      return _buildTimelineItem(attendance, isLast);
                    }, childCount: filteredAttendance.length + (provider.hasMore ? 1 : 0)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.04,
            ),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Attendance attendance, bool isLast) {
    final statusColor = _getStatusColor(attendance.status);
    final statusLabel = _getStatusLabel(attendance.status);
    final dateKey = attendance.date.toIso8601String();
    final isExpanded = _expandedDates.contains(dateKey);

    // Get time range for collapsed view
    String timeRange = '-';
    if (attendance.checkInTime != null && attendance.checkOutTime != null) {
      timeRange =
          '${DateFormat('HH:mm').format(attendance.checkInTime!)} - ${DateFormat('HH:mm').format(attendance.checkOutTime!)}';
    } else if (attendance.checkInTime != null) {
      timeRange = '${DateFormat('HH:mm').format(attendance.checkInTime!)} -';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Line and Dot
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: isExpanded ? 200 : 60,
                color: const Color(0xFFE6EEF3),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Content Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Semantics(
              label:
                  'Attendance entry for ${DateFormat('EEEE, dd MMMM yyyy').format(attendance.date)}, Status: $statusLabel',
              hint: isExpanded
                  ? 'Tap to collapse details'
                  : 'Tap to expand details',
              button: true,
              expanded: isExpanded,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedDates.remove(dateKey);
                    } else {
                      _expandedDates.add(dateKey);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                focusColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                autofocus: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Collapsed Header Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat(
                                'EEE, dd MMM yyyy',
                              ).format(attendance.date),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeRange,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Semantics(
                            label: isExpanded ? 'Collapse' : 'Expand',
                            child: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),

                      // Expanded Details with Animation
                      AnimatedCrossFade(
                        firstChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            _buildCompactTimeRow(
                              'Check In',
                              attendance.checkInTime,
                            ),
                            const SizedBox(height: 8),
                            _buildCompactTimeRow(
                              'Lunch Start',
                              attendance.lunchOutTime,
                            ),
                            const SizedBox(height: 8),
                            _buildCompactTimeRow(
                              'Lunch End',
                              attendance.lunchInTime,
                            ),
                            const SizedBox(height: 8),
                            _buildCompactTimeRow(
                              'Check Out',
                              attendance.checkOutTime,
                            ),

                            if (attendance.formattedWorkingHours != null ||
                                attendance.formattedOvertimeHours != null) ...[
                              const SizedBox(height: 12),
                              Divider(
                                height: 1,
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (attendance.formattedWorkingHours !=
                                      null) ...[
                                    Text(
                                      'Working: ${attendance.formattedWorkingHours}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                  if (attendance.formattedWorkingHours !=
                                          null &&
                                      attendance.formattedOvertimeHours != null)
                                    const Text(
                                      '  •  ',
                                      style: TextStyle(
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  if (attendance.formattedOvertimeHours != null)
                                    Text(
                                      'Overtime: ${attendance.formattedOvertimeHours}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        secondChild: const SizedBox.shrink(),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 160),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTimeRow(String label, DateTime? time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          time != null ? DateFormat('hh:mm a').format(time) : '-',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: time != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NOT_MARKED':
        return Colors.grey;
      case 'PRESENT':
        return Colors.green;
      case 'ABSENT':
        return Colors.red;
      case 'HALF_DAY':
        return Colors.orange;
      case 'ON_LEAVE':
      case 'LEAVE':
        return Colors.blue;
      case 'LATE':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'HALF_DAY':
        return 'Half Day';
      case 'ON_LEAVE':
      case 'LEAVE':
        return 'On Leave';
      case 'LATE':
        return 'Late';
      case 'NOT_MARKED':
        return 'Not Marked';
      default:
        return status;
    }
  }

  String _formatHours(double hours) {
    if (hours == 0) return '0h';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) {
      return '${h}h';
    }
    return '${h}h ${m}m';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Status Filter'),
              subtitle: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = 'All';
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sticky Header Delegate for date range filter
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

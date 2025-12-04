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
  final List<String> _statusOptions = ['All', 'Present', 'Absent', 'Half Day', 'On Leave', 'Late'];

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  Future<void> _loadAttendance() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    await provider.fetchAttendanceHistory(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final initialStart = _startDate ?? now.subtract(const Duration(days: 30));
    final initialEnd = _endDate ?? now;
    
    // Ensure initial dates don't exceed lastDate
    final safeStart = initialStart.isAfter(now) ? now.subtract(const Duration(days: 30)) : initialStart;
    final safeEnd = initialEnd.isAfter(now) ? now : initialEnd;
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: safeStart,
        end: safeEnd,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAttendance();
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
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAttendance,
          tooltip: 'Refresh',
        ),
      ],
      child: Column(
        children: [
          // Stats Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Present',
                        stats['totalPresent'].toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Absent',
                        stats['totalAbsent'].toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Attendance',
                        '${stats['attendancePercentage'].toStringAsFixed(1)}%',
                        Icons.pie_chart,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Working Hours',
                        _formatHours(stats['totalWorkingHours']),
                        Icons.access_time,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Overtime',
                        _formatHours(stats['totalOvertimeHours']),
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Total Days',
                        stats['totalDays'].toString(),
                        Icons.calendar_today,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date Range Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date Range',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                            : 'Select date range',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),

          // Timeline View
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAttendance.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance records found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAttendance,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAttendance.length,
                          itemBuilder: (context, index) {
                            final attendance = filteredAttendance[index];
                            final isLast = index == filteredAttendance.length - 1;
                            
                            return _buildTimelineItem(attendance, isLast);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Attendance attendance, bool isLast) {
    final statusColor = _getStatusColor(attendance.status);
    final statusLabel = _getStatusLabel(attendance.status);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Line
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 120,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Content Card
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showAttendanceDetails(attendance),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy').format(attendance.date),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(attendance.date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    // Time Details
                    _buildTimeDetail('Check In', attendance.checkInTime, Icons.login),
                    const SizedBox(height: 8),
                    _buildTimeDetail('Lunch Start', attendance.lunchOutTime, Icons.restaurant_outlined),
                    const SizedBox(height: 8),
                    _buildTimeDetail('Lunch End', attendance.lunchInTime, Icons.restaurant),
                    const SizedBox(height: 8),
                    _buildTimeDetail('Check Out', attendance.checkOutTime, Icons.logout),
                    
                    // Working Hours
                    if (attendance.formattedWorkingHours != null || 
                        attendance.formattedOvertimeHours != null) ...[
                      const Divider(height: 24),
                      if (attendance.formattedWorkingHours != null)
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Working: ${attendance.formattedWorkingHours}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (attendance.formattedOvertimeHours != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 18, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Overtime: ${attendance.formattedOvertimeHours}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDetail(String label, DateTime? time, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ),
        Text(
          time != null ? DateFormat('hh:mm a').format(time) : '-',
          style: TextStyle(
            color: time != null ? Colors.black87 : Colors.grey[400],
            fontWeight: time != null ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
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
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
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

  void _showAttendanceDetails(Attendance attendance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(attendance.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(attendance.status),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _getStatusLabel(attendance.status),
                        style: TextStyle(
                          color: _getStatusColor(attendance.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Date', DateFormat('EEEE, dd MMMM yyyy').format(attendance.date)),
                const Divider(),
                _buildDetailRow('Check In', attendance.checkInTime != null 
                    ? DateFormat('hh:mm a').format(attendance.checkInTime!)
                    : 'Not marked'),
                _buildDetailRow('Lunch Start', attendance.lunchOutTime != null 
                    ? DateFormat('hh:mm a').format(attendance.lunchOutTime!)
                    : 'Not marked'),
                _buildDetailRow('Lunch End', attendance.lunchInTime != null 
                    ? DateFormat('hh:mm a').format(attendance.lunchInTime!)
                    : 'Not marked'),
                _buildDetailRow('Check Out', attendance.checkOutTime != null 
                    ? DateFormat('hh:mm a').format(attendance.checkOutTime!)
                    : 'Not marked'),
                if (attendance.formattedWorkingHours != null || 
                    attendance.formattedOvertimeHours != null) ...[
                  const Divider(),
                  if (attendance.formattedWorkingHours != null)
                    _buildDetailRow('Working Hours', attendance.formattedWorkingHours!,
                        color: Colors.blue),
                  if (attendance.formattedOvertimeHours != null)
                    _buildDetailRow('Overtime Hours', attendance.formattedOvertimeHours!,
                        color: Colors.orange),
                ],
                if (attendance.remarks != null && attendance.remarks!.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailRow('Remarks', attendance.remarks!),
                ],
              ],
            ),
          ),
        ),
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

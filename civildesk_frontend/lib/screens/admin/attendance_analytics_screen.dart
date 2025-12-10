import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/attendance_analytics_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../models/employee.dart';
import '../../models/attendance_analytics.dart';
import '../../widgets/admin_layout.dart';
import '../../widgets/cached_profile_image.dart';

class AttendanceAnalyticsScreen extends StatefulWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  State<AttendanceAnalyticsScreen> createState() => _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen> {
  Employee? _selectedEmployee;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      if (_selectedEmployee != null) {
        _fetchAnalytics();
      }
    }
  }

  void _fetchAnalytics() {
    if (_selectedEmployee != null) {
      context.read<AttendanceAnalyticsProvider>().fetchAttendanceAnalytics(
            _selectedEmployee!.employeeId,
            _startDate,
            _endDate,
          );
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    return AdminLayout(
      currentRoute: AppRoutes.attendanceAnalytics,
      title: const Text('Attendance Analytics'),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            SizedBox(height: isMobile ? 16 : 32),
            _buildContent(),
          ],
        ),
      ),
    );
  }



  Widget _buildFilters() {
    final isMobile = _isMobile(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            if (isMobile)
              Column(
                children: [
                  _buildEmployeeSelector(),
                  const SizedBox(height: 16),
                  _buildDateRangeSelector(),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildEmployeeSelector(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateRangeSelector(),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedEmployee != null ? _fetchAnalytics : null,
                icon: const Icon(Icons.search),
                label: const Text('Generate Report'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, _) {
        if (employeeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Employee',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Employee>(
              value: _selectedEmployee,
              decoration: InputDecoration(
                hintText: 'Choose an employee',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: employeeProvider.employees.map((employee) {
                return DropdownMenuItem(
                  value: employee,
                  child: Text(
                    '${employee.firstName} ${employee.lastName} (${employee.employeeId})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (Employee? value) {
                setState(() {
                  _selectedEmployee = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Consumer<AttendanceAnalyticsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        if (provider.analytics == null) {
          return _buildEmptyState();
        }

        return _buildAnalyticsContent(provider.analytics!);
      },
    );
  }

  Widget _buildErrorState(String error) {
    final isMobile = _isMobile(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isMobile ? 48 : 64,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMobile = _isMobile(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: isMobile ? 48 : 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'No Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              'Select an employee and date range to view analytics',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(AttendanceAnalytics analytics) {
    final isMobile = _isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmployeeInfo(analytics),
        SizedBox(height: isMobile ? 16 : 24),
        _buildStatistics(analytics),
        SizedBox(height: isMobile ? 16 : 32),
        _buildDailyLogs(analytics.dailyLogs),
      ],
    );
  }

  Widget _buildEmployeeInfo(AttendanceAnalytics analytics) {
    final isMobile = _isMobile(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primaryContainer,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: isMobile
            ? Column(
                children: [
                  CachedProfileImage(
                    imageUrl: null,
                    fallbackInitials: analytics.employeeName,
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    analytics.employeeName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${analytics.employeeId} • ${analytics.department}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Report Period: ${DateFormat('MMM dd, yyyy').format(analytics.startDate)} - ${DateFormat('MMM dd, yyyy').format(analytics.endDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Row(
                children: [
                  CachedProfileImage(
                    imageUrl: null,
                    fallbackInitials: analytics.employeeName,
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analytics.employeeName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${analytics.employeeId} • ${analytics.department}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Report Period: ${DateFormat('MMM dd, yyyy').format(analytics.startDate)} - ${DateFormat('MMM dd, yyyy').format(analytics.endDate)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
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

  Widget _buildStatistics(AttendanceAnalytics analytics) {
    final isMobile = _isMobile(context);
    final crossAxisCount = isMobile ? 2 : 4;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Working days: Monday to Saturday. Sunday is non-working (all hours counted as overtime).',
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: isMobile ? 12 : 16,
          mainAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: isMobile ? 1.2 : 1.3,
          children: [
            _buildStatCard(
              'Total Working Hours',
              '${analytics.totalWorkingHours.toStringAsFixed(1)} hrs',
              Icons.access_time,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Overtime',
              '${analytics.totalOvertimeHours.toStringAsFixed(1)} hrs',
              Icons.schedule,
              Colors.orange,
            ),
            _buildStatCard(
              'Attendance Rate',
              '${analytics.attendancePercentage.toStringAsFixed(1)}%',
              Icons.pie_chart,
              Colors.green,
            ),
            _buildStatCard(
              'Days Present',
              '${analytics.totalDaysPresent} / ${analytics.totalWorkingDays}',
              Icons.check_circle,
              Colors.teal,
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: isMobile ? 12 : 16,
          mainAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: isMobile ? 1.2 : 1.3,
          children: [
            _buildStatCard(
              'Total Absent',
              '${analytics.totalAbsentDays} days',
              Icons.cancel,
              Colors.red,
            ),
            _buildStatCard(
              'Late Arrivals',
              '${analytics.totalLateDays} days',
              Icons.warning,
              Colors.amber,
            ),
            Tooltip(
              message: 'Monday to Saturday are working days. Sunday is non-working.',
              child: _buildStatCard(
                'Working Days',
                '${analytics.totalWorkingDays} days',
                Icons.calendar_today,
                Colors.purple,
              ),
            ),
            _buildStatCard(
              'Avg Hours/Day',
              '${(analytics.totalWorkingHours / (analytics.totalDaysPresent > 0 ? analytics.totalDaysPresent : 1)).toStringAsFixed(1)} hrs',
              Icons.trending_up,
              Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isMobile = _isMobile(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 11 : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isMobile ? 4 : 6),
                Container(
                  padding: EdgeInsets.all(isMobile ? 5 : 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: isMobile ? 16 : 18, color: color),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: isMobile ? 18 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogs(List<DailyAttendanceLog> logs) {
    final isMobile = _isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Attendance Logs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        if (isMobile)
          _buildMobileDailyLogs(logs)
        else
          _buildDesktopDailyLogs(logs),
      ],
    );
  }

  Widget _buildDesktopDailyLogs(List<DailyAttendanceLog> logs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Check In',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Check Out',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Hours',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'OT',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No attendance records found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildLogRow(logs[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDailyLogs(List<DailyAttendanceLog> logs) {
    if (logs.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No attendance records found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: logs.map((log) => _buildMobileLogCard(log)).toList(),
    );
  }

  Widget _buildMobileLogCard(DailyAttendanceLog log) {
    final dateFormat = DateFormat('MMM dd, EEE');
    final timeFormat = DateFormat('hh:mm a');
    final isSunday = log.dayOfWeek.toUpperCase() == 'SUNDAY';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (log.status) {
      case 'PRESENT':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Present';
        break;
      case 'ABSENT':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Absent';
        break;
      case 'LATE':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Late';
        break;
      case 'HALF_DAY':
        statusColor = Colors.amber;
        statusIcon = Icons.timelapse;
        statusText = 'Half Day';
        break;
      case 'ON_LEAVE':
        statusColor = Colors.blue;
        statusIcon = Icons.event_busy;
        statusText = 'On Leave';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = log.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isSunday
              ? Colors.purple.withOpacity(0.05)
              : log.isLate
                  ? Colors.orange.withOpacity(0.05)
                  : null,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dateFormat.format(log.date),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSunday ? Colors.purple : null,
                                ),
                          ),
                          if (isSunday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Non-Working',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (log.isLate && !isSunday) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.warning, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Late',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Time Information
            Row(
              children: [
                Expanded(
                  child: _buildMobileTimeInfo(
                    'Check In',
                    log.checkInTime != null ? timeFormat.format(log.checkInTime!) : '-',
                    Icons.login,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMobileTimeInfo(
                    'Check Out',
                    log.checkOutTime != null ? timeFormat.format(log.checkOutTime!) : '-',
                    Icons.logout,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMobileTimeInfo(
                    'Hours',
                    log.workingHours != null ? '${log.workingHours!.toStringAsFixed(1)}h' : '-',
                    Icons.access_time,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMobileTimeInfo(
                    'Overtime',
                    log.overtimeHours != null && log.overtimeHours! > 0
                        ? '${log.overtimeHours!.toStringAsFixed(1)}h'
                        : '-',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            if (isSunday && log.overtimeHours != null && log.overtimeHours! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.purple),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'All hours counted as overtime (Non-working day)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
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
    );
  }

  Widget _buildMobileTimeInfo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(DailyAttendanceLog log) {
    final dateFormat = DateFormat('MMM dd, EEE');
    final timeFormat = DateFormat('hh:mm a');

    // Check if it's Sunday (non-working day)
    final isSunday = log.dayOfWeek.toUpperCase() == 'SUNDAY';

    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case 'PRESENT':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'ABSENT':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'LATE':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'HALF_DAY':
        statusColor = Colors.amber;
        statusIcon = Icons.timelapse;
        break;
      case 'ON_LEAVE':
        statusColor = Colors.blue;
        statusIcon = Icons.event_busy;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSunday
            ? Colors.purple.withOpacity(0.05)
            : log.isLate 
                ? Colors.orange.withOpacity(0.05) 
                : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateFormat.format(log.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSunday ? Colors.purple : null,
                          ),
                    ),
                    if (isSunday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Non-Working',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (log.isLate && !isSunday)
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Late',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                if (isSunday && log.overtimeHours != null && log.overtimeHours! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'All hours counted as OT',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.checkInTime != null ? timeFormat.format(log.checkInTime!) : '-',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.checkOutTime != null ? timeFormat.format(log.checkOutTime!) : '-',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              log.workingHours != null ? '${log.workingHours!.toStringAsFixed(1)}h' : '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              log.overtimeHours != null && log.overtimeHours! > 0 
                  ? '${log.overtimeHours!.toStringAsFixed(1)}h' 
                  : '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSunday
                        ? Colors.purple
                        : log.overtimeHours != null && log.overtimeHours! > 0 
                            ? Colors.orange 
                            : null,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Tooltip(
              message: log.status,
              child: Icon(
                statusIcon,
                size: 20,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


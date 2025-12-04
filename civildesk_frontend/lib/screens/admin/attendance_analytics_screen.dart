import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/attendance_analytics_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../models/employee.dart';
import '../../models/attendance_analytics.dart';
import '../../widgets/admin_layout.dart';

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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.attendanceAnalytics,
      title: const Text('Attendance Analytics'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFilters(),
            const SizedBox(height: 32),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Analytics',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track and analyze employee attendance data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters() {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
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
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmployeeInfo(analytics),
        const SizedBox(height: 24),
        _buildStatistics(analytics),
        const SizedBox(height: 32),
        _buildDailyLogs(analytics.dailyLogs),
      ],
    );
  }

  Widget _buildEmployeeInfo(AttendanceAnalytics analytics) {
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
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                analytics.employeeName.split(' ').map((e) => e[0]).join().toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
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
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogs(List<DailyAttendanceLog> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Attendance Logs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
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
        ),
      ],
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


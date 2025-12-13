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
  State<AttendanceAnalyticsScreen> createState() =>
      _AttendanceAnalyticsScreenState();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'Select Date Range',
      cancelText: 'Cancel',
      confirmText: 'Apply',
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: colorScheme.copyWith(
              primary: colorScheme.primary,
              onPrimary: colorScheme.onPrimary,
              surface: colorScheme.surface,
              onSurface: colorScheme.onSurface,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
            ),
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
            SizedBox(height: isMobile ? 16 : 24),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final isMobile = _isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? colorScheme.outline.withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: isDark ? colorScheme.surface : colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (isMobile)
              Column(
                children: [
                  _buildEmployeeSelector(),
                  const SizedBox(height: 12),
                  _buildDateRangeSelector(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildEmployeeSelector()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildDateRangeSelector()),
                ],
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedEmployee != null ? _fetchAnalytics : null,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Generate Report'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, _) {
        if (employeeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Employee',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<Employee>(
              value: _selectedEmployee,
              decoration: InputDecoration(
                hintText: 'Choose an employee',
                prefixIcon: Icon(Icons.person_outline, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? colorScheme.outline.withOpacity(0.5)
                        : colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? colorScheme.outline.withOpacity(0.5)
                        : colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceVariant.withOpacity(0.3)
                    : colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                isDense: true,
              ),
              items: employeeProvider.employees.map((employee) {
                return DropdownMenuItem(
                  value: employee,
                  child: Text(
                    '${employee.firstName} ${employee.lastName} (${employee.employeeId})',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (Employee? value) {
                setState(() {
                  _selectedEmployee = value;
                });
              },
              style: theme.textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isMobile = _isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final daysDifference = _endDate.difference(_startDate).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Date Range',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        // Quick Preset Buttons - Two rows
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildPresetButton('Today', () => _setPresetDateRange('today')),
            _buildPresetButton(
              'This Week',
              () => _setPresetDateRange('thisWeek'),
            ),
            _buildPresetButton(
              'This Month',
              () => _setPresetDateRange('thisMonth'),
            ),
            _buildPresetButton(
              'Last 7 Days',
              () => _setPresetDateRange('last7Days'),
            ),
            _buildPresetButton(
              'Last 30 Days',
              () => _setPresetDateRange('last30Days'),
            ),
            _buildPresetButton(
              'Last Month',
              () => _setPresetDateRange('lastMonth'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Date Range Picker - Compact
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? colorScheme.outline.withOpacity(0.5)
                      : colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isDark
                    ? colorScheme.surfaceVariant.withOpacity(0.3)
                    : colorScheme.surface,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${dateFormat.format(_startDate)} → ${dateFormat.format(_endDate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (daysDifference > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$daysDifference ${daysDifference == 1 ? 'day' : 'days'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _isPresetSelected(label);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : isDark
                ? colorScheme.surfaceVariant.withOpacity(0.2)
                : colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.6)
                  : isDark
                  ? colorScheme.outline.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 1 : 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isPresetSelected(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case 'Today':
        return _startDate.year == today.year &&
            _startDate.month == today.month &&
            _startDate.day == today.day &&
            _endDate.year == today.year &&
            _endDate.month == today.month &&
            _endDate.day == today.day;
      case 'This Week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return _startDate.year == weekStart.year &&
            _startDate.month == weekStart.month &&
            _startDate.day == weekStart.day &&
            _endDate.year == weekEnd.year &&
            _endDate.month == weekEnd.month &&
            _endDate.day == weekEnd.day;
      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return _startDate.year == monthStart.year &&
            _startDate.month == monthStart.month &&
            _startDate.day == monthStart.day &&
            _endDate.year == monthEnd.year &&
            _endDate.month == monthEnd.month &&
            _endDate.day == monthEnd.day;
      case 'Last 7 Days':
        final last7Start = today.subtract(const Duration(days: 6));
        return _startDate.year == last7Start.year &&
            _startDate.month == last7Start.month &&
            _startDate.day == last7Start.day &&
            _endDate.year == today.year &&
            _endDate.month == today.month &&
            _endDate.day == today.day;
      case 'Last 30 Days':
        final last30Start = today.subtract(const Duration(days: 29));
        return _startDate.year == last30Start.year &&
            _startDate.month == last30Start.month &&
            _startDate.day == last30Start.day &&
            _endDate.year == today.year &&
            _endDate.month == today.month &&
            _endDate.day == today.day;
      case 'Last Month':
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        final lastMonthStart = DateTime(lastMonthYear, lastMonth, 1);
        final lastMonthEnd = DateTime(lastMonthYear, lastMonth + 1, 0);
        return _startDate.year == lastMonthStart.year &&
            _startDate.month == lastMonthStart.month &&
            _startDate.day == lastMonthStart.day &&
            _endDate.year == lastMonthEnd.year &&
            _endDate.month == lastMonthEnd.month &&
            _endDate.day == lastMonthEnd.day;
      default:
        return false;
    }
  }

  void _setPresetDateRange(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate;
    DateTime endDate;

    switch (preset) {
      case 'today':
        startDate = today;
        endDate = today;
        break;
      case 'thisWeek':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        startDate = weekStart;
        endDate = weekStart.add(const Duration(days: 6));
        break;
      case 'thisMonth':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'last7Days':
        startDate = today.subtract(const Duration(days: 6));
        endDate = today;
        break;
      case 'last30Days':
        startDate = today.subtract(const Duration(days: 29));
        endDate = today;
        break;
      case 'lastMonth':
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        startDate = DateTime(lastMonthYear, lastMonth, 1);
        endDate = DateTime(lastMonthYear, lastMonth + 1, 0);
        break;
      default:
        return;
    }

    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });

    if (_selectedEmployee != null) {
      _fetchAnalytics();
    }
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            Text(
              'No Data',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
        SizedBox(height: isMobile ? 16 : 20),
        _buildStatistics(analytics),
        SizedBox(height: isMobile ? 16 : 20),
        _buildDailyLogs(analytics.dailyLogs),
      ],
    );
  }

  Widget _buildEmployeeInfo(AttendanceAnalytics analytics) {
    final isMobile = _isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? colorScheme.outline.withOpacity(0.2)
              : colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: isDark
          ? colorScheme.surfaceVariant.withOpacity(0.2)
          : colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: isMobile
          ? SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                CachedProfileImage(
                  imageUrl: null,
                  fallbackInitials: analytics.employeeName,
                  radius: 28,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  analytics.employeeName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${analytics.employeeId} • ${analytics.department}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('MMM dd, yyyy').format(analytics.startDate)} → ${DateFormat('MMM dd, yyyy').format(analytics.endDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            )
          : SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  CachedProfileImage(
                    imageUrl: null,
                    fallbackInitials: analytics.employeeName,
                    radius: 32,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          analytics.employeeName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${analytics.employeeId} • ${analytics.department}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Report Period: ${DateFormat('MMM dd, yyyy').format(analytics.startDate)} → ${DateFormat('MMM dd, yyyy').format(analytics.endDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildStatistics(AttendanceAnalytics analytics) {
    final isMobile = _isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'Working days: Monday to Saturday. Sunday is non-working (all hours counted as overtime).',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark
                  ? colorScheme.outline.withOpacity(0.2)
                  : colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          color: isDark
              ? colorScheme.surfaceVariant.withOpacity(0.2)
              : colorScheme.surface,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: GridView.count(
              crossAxisCount: isMobile ? 1 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: isMobile ? 0 : 24,
              childAspectRatio: isMobile ? 4 : 5,
              children: [
                _buildUnifiedStatItem(
                  'Total Working Hours',
                  '${analytics.totalWorkingHours.toStringAsFixed(1)} hrs',
                  Icons.access_time,
                  isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
                _buildUnifiedStatItem(
                  'Total Overtime',
                  '${analytics.totalOvertimeHours.toStringAsFixed(1)} hrs',
                  Icons.schedule,
                  isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                ),
                _buildUnifiedStatItem(
                  'Attendance Rate',
                  '${analytics.attendancePercentage.toStringAsFixed(1)}%',
                  Icons.pie_chart,
                  isDark ? Colors.green.shade300 : Colors.green.shade700,
                ),
                _buildUnifiedStatItem(
                  'Days Present',
                  '${analytics.totalDaysPresent} / ${analytics.totalWorkingDays}',
                  Icons.check_circle,
                  isDark ? Colors.teal.shade300 : Colors.teal.shade700,
                ),
                _buildUnifiedStatItem(
                  'Total Absent',
                  '${analytics.totalAbsentDays} days',
                  Icons.cancel,
                  isDark ? Colors.red.shade300 : Colors.red.shade700,
                ),
                _buildUnifiedStatItem(
                  'Late Arrivals',
                  '${analytics.totalLateDays} days',
                  Icons.warning,
                  isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                ),
                Tooltip(
                  message:
                      'Monday to Saturday are working days. Sunday is non-working.',
                  child: _buildUnifiedStatItem(
                    'Working Days',
                    '${analytics.totalWorkingDays} days',
                    Icons.calendar_today,
                    isDark ? Colors.purple.shade300 : Colors.purple.shade700,
                  ),
                ),
                _buildUnifiedStatItem(
                  'Avg Hours/Day',
                  '${(analytics.totalWorkingHours / (analytics.totalDaysPresent > 0 ? analytics.totalDaysPresent : 1)).toStringAsFixed(1)} hrs',
                  Icons.trending_up,
                  isDark ? Colors.indigo.shade300 : Colors.indigo.shade700,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedStatItem(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: color,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        if (isMobile)
          _buildMobileDailyLogs(logs)
        else
          _buildDesktopDailyLogs(logs),
      ],
    );
  }

  Widget _buildDesktopDailyLogs(List<DailyAttendanceLog> logs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? colorScheme.outline.withOpacity(0.2)
              : colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: isDark
          ? colorScheme.surfaceVariant.withOpacity(0.2)
          : colorScheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceVariant.withOpacity(0.3)
                  : colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Check In',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Lunch Out',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Lunch In',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Check Out',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Hours',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'OT',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outline.withOpacity(0.1),
          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    String statusText;

    switch (log.status) {
      case 'PRESENT':
        statusColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        statusText = 'Present';
        break;
      case 'ABSENT':
        statusColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
        statusText = 'Absent';
        break;
      case 'LATE':
        statusColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        statusText = 'Late';
        break;
      case 'HALF_DAY':
        statusColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
        statusText = 'Half Day';
        break;
      case 'ON_LEAVE':
        statusColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
        statusText = 'On Leave';
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusText = log.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceVariant.withOpacity(0.2)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withOpacity(0.2)
              : colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      dateFormat.format(log.date),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSunday
                            ? (isDark
                                  ? Colors.purple.shade300
                                  : Colors.purple.shade700)
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (isSunday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.purple.withOpacity(0.2)
                              : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Non-Working',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.purple.shade300
                                : Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSimpleTimeRow(
                  'Check In',
                  log.checkInTime != null
                      ? timeFormat.format(log.checkInTime!)
                      : '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleTimeRow(
                  'Check Out',
                  log.checkOutTime != null
                      ? timeFormat.format(log.checkOutTime!)
                      : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSimpleTimeRow(
                  'Lunch Out',
                  log.lunchOutTime != null
                      ? timeFormat.format(log.lunchOutTime!)
                      : '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleTimeRow(
                  'Lunch In',
                  log.lunchInTime != null
                      ? timeFormat.format(log.lunchInTime!)
                      : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildColoredTimeRow(
                  'Hours',
                  log.workingHours != null
                      ? '${log.workingHours!.toStringAsFixed(1)}h'
                      : '-',
                  isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildColoredTimeRow(
                  'Overtime',
                  log.overtimeHours != null && log.overtimeHours! > 0
                      ? '${log.overtimeHours!.toStringAsFixed(1)}h'
                      : '-',
                  isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTimeRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildColoredTimeRow(String label, String value, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(DailyAttendanceLog log) {
    final dateFormat = DateFormat('MMM dd, EEE');
    final timeFormat = DateFormat('hh:mm a');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSunday = log.dayOfWeek.toUpperCase() == 'SUNDAY';

    Color statusColor;
    String statusText;

    switch (log.status) {
      case 'PRESENT':
        statusColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        statusText = 'Present';
        break;
      case 'ABSENT':
        statusColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
        statusText = 'Absent';
        break;
      case 'LATE':
        statusColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        statusText = 'Late';
        break;
      case 'HALF_DAY':
        statusColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
        statusText = 'Half Day';
        break;
      case 'ON_LEAVE':
        statusColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
        statusText = 'On Leave';
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusText = log.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isSunday
            ? (isDark
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.purple.withOpacity(0.05))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  dateFormat.format(log.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isSunday
                        ? (isDark
                              ? Colors.purple.shade300
                              : Colors.purple.shade700)
                        : colorScheme.onSurface,
                  ),
                ),
                if (isSunday) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Non-Working',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.purple.shade300
                            : Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.checkInTime != null
                  ? timeFormat.format(log.checkInTime!)
                  : '-',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.lunchOutTime != null
                  ? timeFormat.format(log.lunchOutTime!)
                  : '-',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.lunchInTime != null
                  ? timeFormat.format(log.lunchInTime!)
                  : '-',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.checkOutTime != null
                  ? timeFormat.format(log.checkOutTime!)
                  : '-',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                    .withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                log.workingHours != null
                    ? '${log.workingHours!.toStringAsFixed(1)}h'
                    : '-',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isSunday
                        ? (isDark ? Colors.purple.shade300 : Colors.purple.shade700)
                        : log.overtimeHours != null && log.overtimeHours! > 0
                            ? (isDark ? Colors.orange.shade300 : Colors.orange.shade700)
                            : colorScheme.onSurfaceVariant)
                    .withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (isSunday
                          ? (isDark ? Colors.purple.shade300 : Colors.purple.shade700)
                          : log.overtimeHours != null && log.overtimeHours! > 0
                              ? (isDark ? Colors.orange.shade300 : Colors.orange.shade700)
                              : colorScheme.onSurfaceVariant)
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                log.overtimeHours != null && log.overtimeHours! > 0
                    ? '${log.overtimeHours!.toStringAsFixed(1)}h'
                    : '-',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSunday
                      ? (isDark ? Colors.purple.shade300 : Colors.purple.shade700)
                      : log.overtimeHours != null && log.overtimeHours! > 0
                      ? (isDark ? Colors.orange.shade300 : Colors.orange.shade700)
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

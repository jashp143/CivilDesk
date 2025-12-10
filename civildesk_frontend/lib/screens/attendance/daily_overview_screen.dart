import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/attendance_service.dart';
import '../../models/attendance.dart';
import '../../widgets/admin_layout.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'edit_punch_times_screen.dart';

class DailyOverviewScreen extends StatefulWidget {
  const DailyOverviewScreen({super.key});

  @override
  State<DailyOverviewScreen> createState() => _DailyOverviewScreenState();
}

class _DailyOverviewScreenState extends State<DailyOverviewScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<Attendance> _attendances = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDailyAttendance();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  Future<void> _loadDailyAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _attendanceService.getDailyAttendance(date: dateString);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> attendanceList = response['data'] as List<dynamic>;
        setState(() {
          _attendances = attendanceList
              .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _attendances = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    if (!mounted) return;
    
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        helpText: 'Select Date',
        cancelText: 'Cancel',
        confirmText: 'Select',
        initialDatePickerMode: DatePickerMode.day,
      );
      
      if (mounted && picked != null) {
        if (picked.year != _selectedDate.year ||
            picked.month != _selectedDate.month ||
            picked.day != _selectedDate.day) {
          setState(() {
            _selectedDate = picked;
          });
          _loadDailyAttendance();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting date: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Attendance> get _filteredAttendances {
    if (_searchQuery.isEmpty) {
      return _attendances;
    }
    
    final query = _searchQuery.toLowerCase();
    return _attendances.where((attendance) {
      final nameMatch = attendance.employeeName.toLowerCase().contains(query);
      final idMatch = attendance.employeeId.toLowerCase().contains(query);
      return nameMatch || idMatch;
    }).toList();
  }

  void _navigateToEditScreen(Attendance attendance) {
    showDialog(
      context: context,
      builder: (context) => EditPunchTimesDialog(attendance: attendance),
    ).then((_) {
      if (mounted) {
        _loadDailyAttendance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final theme = Theme.of(context);
    
    return AdminLayout(
      currentRoute: AppRoutes.adminAttendance,
      title: Text(
        'Daily Attendance Overview',
        style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
      ),
      actions: [
        if (!isMobile) ...[
          _buildAppBarSummaryStats(),
        ],
        ],
                  child: Column(
                    children: [
          // Date selector, search bar and summary stats
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Date selector
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                      Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _selectDate,
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Change Date',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by employee name or ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            ),
                  onChanged: _handleSearch,
                          ),
                const SizedBox(height: 16),
                // Summary stats
                if (isMobile)
                  Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Present',
                          _filteredAttendances
                                      .where((a) => a.status == AttendanceStatus.present)
                                      .length
                                      .toString(),
                          AppTheme.statusApproved,
                                  Icons.check_circle,
                                ),
                              ),
                      const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Absent',
                          _filteredAttendances
                                      .where((a) => a.status == AttendanceStatus.absent)
                                      .length
                                      .toString(),
                          AppTheme.statusRejected,
                                  Icons.cancel,
                        ),
                                ),
                    ],
                              ),
                            ],
                          ),
                        ),
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                              Icons.error_outline,
                                      size: 64,
                              color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                              'Error: $_error',
                                      style: TextStyle(
                                color: theme.colorScheme.error,
                                      ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDailyAttendance,
                              child: const Text('Retry'),
                            ),
                          ],
                ),
                      )
                    : _filteredAttendances.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.event_busy,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No attendance records found for "$_searchQuery"'
                                      : 'No attendance records for this date',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _handleSearch('');
                                    },
                                    child: const Text('Clear search'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDailyAttendance,
                            color: theme.colorScheme.primary,
                            child: isMobile
                                ? _buildMobileCardView()
                                : _buildDesktopTableView(),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark
              ? color.withOpacity(0.2)
              : color.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildAppBarSummaryStats() {
    final presentCount = _filteredAttendances
        .where((a) => a.status == AttendanceStatus.present)
        .length;
    final absentCount = _filteredAttendances
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
            children: [
              Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
            color: AppTheme.statusApproved.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
                  border: Border.all(
              color: AppTheme.statusApproved.withOpacity(0.3),
              width: 1,
                  ),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
                  children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppTheme.statusApproved,
              ),
              const SizedBox(width: 6),
                    Text(
                '$presentCount Present',
                      style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusApproved,
                ),
              ),
            ],
                      ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.statusRejected.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.statusRejected.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                Icons.cancel,
                size: 16,
                color: AppTheme.statusRejected,
                        ),
              const SizedBox(width: 6),
                        Text(
                '$absentCount Absent',
                          style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusRejected,
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  // Desktop/Tablet Table View
  Widget _buildDesktopTableView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate minimum table width based on content
        final minTableWidth = 1200.0;
        final tableWidth = constraints.maxWidth > minTableWidth 
            ? constraints.maxWidth - 32 
            : minTableWidth;
        
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
                    children: [
              // Table Header
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline,
                      width: 2,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5), // Full Name with Employee ID
                        1: FlexColumnWidth(1.2), // Check In
                        2: FlexColumnWidth(1.2), // Lunch Out
                        3: FlexColumnWidth(1.2), // Lunch In
                        4: FlexColumnWidth(1.2), // Check Out
                        5: FlexColumnWidth(1.5), // Working Hours
                        6: FlexColumnWidth(1.2), // Overtime
                        7: FlexColumnWidth(1.8), // Actions/Status
                      },
                      children: [
                        TableRow(
                          children: [
                            _buildTableHeaderCell('Full Name (ID)', theme, Icons.person),
                            _buildTableHeaderCell('Check In', theme, Icons.login),
                            _buildTableHeaderCell('Lunch Out', theme, Icons.restaurant),
                            _buildTableHeaderCell('Lunch In', theme, Icons.restaurant_menu),
                            _buildTableHeaderCell('Check Out', theme, Icons.logout),
                            _buildTableHeaderCell('Working Hours', theme, Icons.access_time),
                            _buildTableHeaderCell('Overtime', theme, Icons.timer),
                            _buildTableHeaderCell('Status/Actions', theme, Icons.more_vert),
                          ],
                      ),
                    ],
                  ),
                ),
                ),
              ),
              // Table Body - Scrollable both directions
                Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5), // Full Name with Employee ID
                          1: FlexColumnWidth(1.2), // Check In
                          2: FlexColumnWidth(1.2), // Lunch Out
                          3: FlexColumnWidth(1.2), // Lunch In
                          4: FlexColumnWidth(1.2), // Check Out
                          5: FlexColumnWidth(1.5), // Working Hours
                          6: FlexColumnWidth(1.2), // Overtime
                          7: FlexColumnWidth(1.8), // Actions/Status
                        },
                    children: [
                          ..._filteredAttendances.asMap().entries.map((entry) {
                            final index = entry.key;
                            final attendance = entry.value;
                            return _buildTableRow(context, attendance, theme, index);
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
                          ),
                        ],
                      ),
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text, ThemeData theme, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
                          children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
                            ),
                          ],
                        ),
    );
  }

  TableRow _buildTableRow(
    BuildContext context,
    Attendance attendance,
    ThemeData theme,
    int index,
  ) {
    final colorScheme = theme.colorScheme;
    final isEven = index % 2 == 0;
    
    return TableRow(
      decoration: BoxDecoration(
        color: isEven 
            ? colorScheme.surface 
            : colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      children: [
        _buildNameCell(context, attendance, theme),
        _buildTimeCell(attendance.formattedCheckInTime, theme, Icons.login, Colors.blue),
        _buildTimeCell(_formatTime(attendance.lunchOutTime), theme, Icons.restaurant, Colors.orange),
        _buildTimeCell(_formatTime(attendance.lunchInTime), theme, Icons.restaurant_menu, Colors.teal),
        _buildTimeCell(attendance.formattedCheckOutTime, theme, Icons.logout, Colors.purple),
        _buildHoursCell(attendance.formattedWorkingHours, theme, Colors.green),
        _buildHoursCell(attendance.formattedOvertimeHours, theme, Colors.orange),
        _buildStatusActionsCell(context, attendance, theme),
      ],
    );
  }

  Widget _buildNameCell(BuildContext context, Attendance attendance, ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _navigateToEditScreen(attendance),
        hoverColor: primaryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                attendance.employeeName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                            ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                        ),
              const SizedBox(height: 4),
                      Row(
                        children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      attendance.employeeId,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildTimeCell(String time, ThemeData theme, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
                              Text(
            time,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
                                ),
            overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
    );
  }

  Widget _buildHoursCell(String? hours, ThemeData theme, Color color) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: hours != null
          ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                color: isDark
                    ? color.withOpacity(0.2)
                    : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      hours,
                      style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                        color: color,
                                ),
                      overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
            )
          : Text(
              'N/A',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  Widget _buildStatusActionsCell(
    BuildContext context,
    Attendance attendance,
    ThemeData theme,
  ) {
    final isPresent = attendance.status == AttendanceStatus.present;
    final statusColor = isPresent ? AppTheme.statusApproved : AppTheme.statusRejected;
    final statusText = isPresent ? 'Present' : 'Absent';
    final primaryColor = theme.colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
                        children: [
          // Status Badge
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                children: [
              Container(
                    width: 8,
                    height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                      shape: BoxShape.circle,
                ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                child: Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                  ),
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
            ],
          ),
        ),
      ),
          const SizedBox(width: 8),
          // Edit Action
          Tooltip(
            message: 'Edit Punch Times',
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: primaryColor,
                size: 20,
              ),
              onPressed: () => _navigateToEditScreen(attendance),
              tooltip: 'Edit',
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ),
        ),
      ],
      ),
    );
  }

  // Mobile Card View
  Widget _buildMobileCardView() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAttendances.length,
      itemBuilder: (context, index) {
        final attendance = _filteredAttendances[index];
        return _buildMobileCard(attendance);
      },
    );
    }

  Widget _buildMobileCard(Attendance attendance) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPresent = attendance.status == AttendanceStatus.present;
    final statusColor = isPresent ? AppTheme.statusApproved : AppTheme.statusRejected;
    final statusText = isPresent ? 'Present' : 'Absent';
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToEditScreen(attendance),
          borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Employee ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                        size: 18,
                        color: colorScheme.primary,
                            ),
                      const SizedBox(width: 8),
                            Text(
                              attendance.employeeId,
                        style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                                fontWeight: FontWeight.w600,
                            fontSize: 12,
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Time Information
              _buildMobileTimeRow(
                'Check In',
                attendance.formattedCheckInTime,
                Icons.login,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildMobileTimeRow(
                'Lunch Out',
                _formatTime(attendance.lunchOutTime),
                Icons.restaurant,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildMobileTimeRow(
                'Lunch In',
                _formatTime(attendance.lunchInTime),
                Icons.restaurant_menu,
                Colors.teal,
              ),
              const SizedBox(height: 12),
              _buildMobileTimeRow(
                'Check Out',
                attendance.formattedCheckOutTime,
                Icons.logout,
                Colors.purple,
                        ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Working Hours and Overtime
              Row(
                children: [
                  if (attendance.formattedWorkingHours != null) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.green.withOpacity(0.2)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                        ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Working Hours',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                              Text(
                              attendance.formattedWorkingHours!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (attendance.formattedWorkingHours != null &&
                      attendance.formattedOvertimeHours != null)
                    const SizedBox(width: 12),
                  if (attendance.formattedOvertimeHours != null) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                        ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 20,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 4),
                              Text(
                              'Overtime',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            const SizedBox(height: 4),
                              Text(
                                attendance.formattedOvertimeHours!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      ),
                ),
              ],
                ],
              ),
              const SizedBox(height: 16),
              // Edit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToEditScreen(attendance),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Punch Times'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTimeRow(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Row(
        children: [
          Container(
          padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
            color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
            color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                time,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

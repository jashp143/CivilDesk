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
  
  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  void _onScroll() {
    if (!_scrollController.hasClients || !mounted) return;
    
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    
    // Load more when user scrolls to 80% of the scroll extent
    if (currentScroll >= maxScroll * 0.8 && maxScroll > 0) {
      if (_hasMore && !_isLoading) {
        _loadMoreAttendance();
      }
    }
  }

  Future<void> _loadDailyAttendance({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 0;
      _attendances.clear();
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _attendanceService.getDailyAttendance(
        date: dateString,
        page: _currentPage,
        size: _currentPage == 0 ? 25 : 20,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        
        // Check if it's paginated response
        if (data.containsKey('content')) {
          // Paginated response
          final List<dynamic> attendanceList = data['content'] as List<dynamic>;
          final newAttendances = attendanceList
              .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
              .toList();
          
          setState(() {
            if (refresh || _currentPage == 0) {
              _attendances = newAttendances;
            } else {
              _attendances.addAll(newAttendances);
            }
            _currentPage = data['number'] as int? ?? _currentPage;
            _totalPages = data['totalPages'] as int? ?? 0;
            _totalElements = data['totalElements'] as int? ?? 0;
            _hasMore = _currentPage < _totalPages - 1;
            _isLoading = false;
          });
        } else if (data is List) {
          // Backward compatibility: list response
          final List<dynamic> attendanceList = data as List<dynamic>;
          setState(() {
            _attendances = attendanceList
                .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
                .toList();
            _hasMore = false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _attendances = [];
            _hasMore = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _attendances = [];
          _hasMore = false;
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

  Future<void> _loadMoreAttendance() async {
    if (!_hasMore || _isLoading) return;
    await _loadDailyAttendance(refresh: false);
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
          _loadDailyAttendance(refresh: true);
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

  Color _getStatusColor(AttendanceStatus status, ThemeData theme) {
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.statusApproved;
      case AttendanceStatus.absent:
        return AppTheme.statusRejected;
      case AttendanceStatus.onLeave:
        return Colors.blue;
      case AttendanceStatus.halfDay:
        return Colors.orange;
      case AttendanceStatus.late:
        return Colors.amber;
      case AttendanceStatus.notMarked:
        return Colors.grey;
    }
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
        _loadDailyAttendance(refresh: true);
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
          fontSize: isMobile ? 20 : 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.2,
        ),
      ),
      actions: [
        if (isMobile) ...[
          // Change Date button for mobile
          IconButton(
            icon: Icon(Icons.calendar_today_rounded, size: 22),
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: _selectDate,
            tooltip: 'Change Date',
          ),
        ] else ...[
          _buildAppBarSummaryStats(),
        ],
      ],
      child: Column(
        children: [
          // Date selector, search bar and summary stats
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
            child: Column(
              children: [
                // Date selector - More prominent
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy',
                          ).format(_selectedDate),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 18 : 20,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _selectDate,
                          icon: Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          label: Text(
                            'Change Date',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search employees...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
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
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: _handleSearch,
                ),
                const SizedBox(height: 12),
                // Summary stats
                if (isMobile)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Present',
                          _filteredAttendances
                              .where(
                                (a) => a.status == AttendanceStatus.present,
                              )
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
                          style: TextStyle(color: theme.colorScheme.error),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.statusApproved.withValues(
              alpha: isDark ? 0.2 : 0.12,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.statusApproved.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppTheme.statusApproved,
              ),
              const SizedBox(width: 8),
              Text(
                '$presentCount Present',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusApproved,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.statusRejected.withValues(
              alpha: isDark ? 0.2 : 0.12,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.statusRejected.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cancel_rounded,
                size: 18,
                color: AppTheme.statusRejected,
              ),
              const SizedBox(width: 8),
              Text(
                '$absentCount Absent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusRejected,
                  letterSpacing: 0.1,
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

        return Column(
          children: [
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
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
                          // Header Row
                          TableRow(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline,
                            width: 2,
                          ),
                        ),
                      ),
                      children: [
                        _buildTableHeaderCell(
                          'Full Name (ID)',
                          theme,
                          Icons.person,
                        ),
                        _buildTableHeaderCell('Check In', theme, Icons.login),
                        _buildTableHeaderCell(
                          'Lunch Out',
                          theme,
                          Icons.restaurant,
                        ),
                        _buildTableHeaderCell(
                          'Lunch In',
                          theme,
                          Icons.restaurant_menu,
                        ),
                        _buildTableHeaderCell('Check Out', theme, Icons.logout),
                        _buildTableHeaderCell(
                          'Working Hours',
                          theme,
                          Icons.access_time,
                        ),
                        _buildTableHeaderCell('Overtime', theme, Icons.timer),
                        _buildTableHeaderCell(
                          'Status/Actions',
                          theme,
                          Icons.more_vert,
                        ),
                      ],
                    ),
                    // Data Rows
                    ..._filteredAttendances.asMap().entries.map((entry) {
                      final index = entry.key;
                      final attendance = entry.value;
                      return _buildTableRow(context, attendance, theme, index);
                    }),
                          // Loading indicator row
                          if (_hasMore && _isLoading)
                            TableRow(
                              children: List.generate(8, (index) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Load More button footer
            if (_hasMore && !_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _loadMoreAttendance,
                    icon: const Icon(Icons.expand_more),
                    label: Text(
                      'Load More (${_totalElements - _attendances.length} remaining)',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text, ThemeData theme, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      children: [
        _buildNameCell(context, attendance, theme),
        _buildTimeCell(
          attendance.formattedCheckInTime,
          theme,
          Icons.login,
          Colors.blue,
        ),
        _buildTimeCell(
          _formatTime(attendance.lunchOutTime),
          theme,
          Icons.restaurant,
          Colors.orange,
        ),
        _buildTimeCell(
          _formatTime(attendance.lunchInTime),
          theme,
          Icons.restaurant_menu,
          Colors.teal,
        ),
        _buildTimeCell(
          attendance.formattedCheckOutTime,
          theme,
          Icons.logout,
          Colors.purple,
        ),
        _buildHoursCell(attendance.formattedWorkingHours, theme, Colors.green),
        _buildHoursCell(
          attendance.formattedOvertimeHours,
          theme,
          Colors.orange,
        ),
        _buildStatusActionsCell(context, attendance, theme),
      ],
    );
  }

  Widget _buildNameCell(
    BuildContext context,
    Attendance attendance,
    ThemeData theme,
  ) {
    final primaryColor = theme.colorScheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _navigateToEditScreen(attendance),
        hoverColor: primaryColor.withValues(alpha: 0.1),
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
                maxLines: 2,
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

  Widget _buildTimeCell(
    String time,
    ThemeData theme,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
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
                    ? color.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16, color: color),
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
    final statusColor = _getStatusColor(attendance.status, theme);
    final statusText = attendance.status.displayName;
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
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
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
          // Actions Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: primaryColor, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEditScreen(attendance);
              } else if (value == 'mark_absent') {
                _markAsAbsent(attendance);
              } else if (value == 'mark_present') {
                _markAsPresent(attendance);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Punch Times'),
                  ],
                ),
              ),
              if (attendance.status == AttendanceStatus.notMarked)
                const PopupMenuItem(
                  value: 'mark_present',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Mark as Present (Emergency)',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              if (attendance.status != AttendanceStatus.absent)
                const PopupMenuItem(
                  value: 'mark_absent',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Mark as Absent',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPresent(Attendance attendance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Present (Emergency)'),
        content: Text(
          'Are you sure you want to manually mark ${attendance.employeeName} as present for ${DateFormat('dd MMM yyyy').format(attendance.date)}?\n\nThis will create an attendance record with current time as check-in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Present'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _attendanceService.markAttendanceManualForDate(
          employeeId: attendance.employeeId,
          date: attendance.date,
          attendanceType: 'PUNCH_IN',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${attendance.employeeName} marked as present'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDailyAttendance(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error marking present: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _markAsAbsent(Attendance attendance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Absent'),
        content: Text(
          'Are you sure you want to mark ${attendance.employeeName} as absent for ${DateFormat('dd MMM yyyy').format(attendance.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Mark Absent'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _attendanceService.markAbsent(
          employeeId: attendance.employeeId,
          date: attendance.date,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${attendance.employeeName} marked as absent'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDailyAttendance(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error marking absent: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Mobile Card View
  Widget _buildMobileCardView() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAttendances.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredAttendances.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final attendance = _filteredAttendances[index];
        return _buildMobileCard(attendance);
      },
    );
  }

  Widget _buildMobileCard(Attendance attendance) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(attendance.status, theme);
    final statusText = attendance.status.displayName;
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToEditScreen(attendance),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Header: Name, ID, and Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.employeeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              attendance.employeeId,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          attendance.status == AttendanceStatus.present
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
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
              const SizedBox(height: 12),
              // Soft Divider
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 12),
              // Punch Logs Block - Clean Two-Column Layout
              _buildPunchLogRow('Check In', attendance.formattedCheckInTime),
              const SizedBox(height: 8),
              _buildPunchLogRow(
                'Lunch Out',
                _formatTime(attendance.lunchOutTime),
              ),
              const SizedBox(height: 8),
              _buildPunchLogRow(
                'Lunch In',
                _formatTime(attendance.lunchInTime),
              ),
              const SizedBox(height: 8),
              _buildPunchLogRow('Check Out', attendance.formattedCheckOutTime),
              const SizedBox(height: 12),
              // Soft Divider
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 12),
              // Summary Row: Working Hours & Overtime
              if (isSmallScreen &&
                  attendance.formattedWorkingHours != null &&
                  attendance.formattedOvertimeHours != null)
                // Compact single line for small screens
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCompactHoursCard(
                      'Working Hours',
                      attendance.formattedWorkingHours!,
                      Colors.green,
                      isDark,
                    ),
                    _buildCompactHoursCard(
                      'Overtime',
                      attendance.formattedOvertimeHours!,
                      Colors.orange,
                      isDark,
                    ),
                  ],
                )
              else
                // Full cards for larger screens
                Row(
                  children: [
                    if (attendance.formattedWorkingHours != null) ...[
                      Expanded(
                        child: _buildHoursCard(
                          'Working Hours',
                          attendance.formattedWorkingHours!,
                          Colors.green,
                          isDark,
                        ),
                      ),
                      if (attendance.formattedOvertimeHours != null)
                        const SizedBox(width: 10),
                    ],
                    if (attendance.formattedOvertimeHours != null) ...[
                      Expanded(
                        child: _buildHoursCard(
                          'Overtime',
                          attendance.formattedOvertimeHours!,
                          Colors.orange,
                          isDark,
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              // Action Buttons
              if (attendance.status == AttendanceStatus.notMarked)
                // Mark as Present button for NOT_MARKED employees
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsPresent(attendance),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Mark as Present (Emergency)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                )
              else
                // Edit Button for employees with attendance records
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToEditScreen(attendance),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text(
                      'Edit Time Logs',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPunchLogRow(String label, String time) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          time,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHoursCard(String label, String value, Color color, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHoursCard(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

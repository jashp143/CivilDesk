import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/holiday_provider.dart';
import '../../core/providers/overtime_provider.dart';
import '../../core/providers/expense_provider.dart';
import '../../models/task.dart';
import '../../models/leave.dart';
import '../../models/overtime.dart';
import '../../models/expense.dart';
import '../../widgets/employee_layout.dart';
import '../../widgets/cached_profile_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _quickActionsController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  double _previousProgress = -1.0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _quickActionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initialize animations
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _quickActionsController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _quickActionsController.dispose();
    super.dispose();
  }

  double _calculateAttendanceProgress(dynamic attendance) {
    if (attendance == null) return 0.0;
    int completed = 0;
    if (attendance.checkInTime != null) completed++;
    if (attendance.lunchOutTime != null) completed++;
    if (attendance.lunchInTime != null) completed++;
    if (attendance.checkOutTime != null) completed++;
    return completed / 4.0;
  }

  int _getCompletedSteps(dynamic attendance) {
    if (attendance == null) return 0;
    int completed = 0;
    if (attendance.checkInTime != null) completed++;
    if (attendance.lunchOutTime != null) completed++;
    if (attendance.lunchInTime != null) completed++;
    if (attendance.checkOutTime != null) completed++;
    return completed;
  }

  Future<void> _loadData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    final holidayProvider = Provider.of<HolidayProvider>(
      context,
      listen: false,
    );
    final overtimeProvider = Provider.of<OvertimeProvider>(
      context,
      listen: false,
    );
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      dashboardProvider.fetchDashboardStats(),
      attendanceProvider.fetchTodayAttendance(),
      taskProvider.fetchMyTasks(),
      leaveProvider.fetchMyLeaves(),
      holidayProvider.loadUpcomingHolidays(),
      overtimeProvider.fetchMyOvertimes(),
      expenseProvider.fetchMyExpenses(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final leaveProvider = Provider.of<LeaveProvider>(context);
    final holidayProvider = Provider.of<HolidayProvider>(context);
    final overtimeProvider = Provider.of<OvertimeProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return EmployeeLayout(
      currentRoute: AppRoutes.home,
      title: const Text('CivilDesk Employee'),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child:
            dashboardProvider.isLoading &&
                dashboardProvider.dashboardStats == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card with Profile
                    _buildWelcomeCard(
                      context,
                      authProvider,
                      dashboardProvider,
                      colorScheme,
                      themeProvider,
                    ),
                    const SizedBox(height: 8),

                    // Today's Attendance Card
                    _buildTodayAttendanceCard(
                      context,
                      attendanceProvider,
                      colorScheme,
                      themeProvider,
                    ),
                    const SizedBox(height: 8),

                    // Quick Actions
                    _buildQuickActions(context, colorScheme),
                    const SizedBox(height: 8),

                    // Upcoming Holidays
                    if (holidayProvider.upcomingHolidays.isNotEmpty)
                      _buildUpcomingHolidays(
                        context,
                        holidayProvider,
                        colorScheme,
                      ),
                    const SizedBox(height: 8),

                    // Pending Tasks
                    if (taskProvider.tasks.isNotEmpty)
                      _buildPendingTasks(context, taskProvider, colorScheme),
                    const SizedBox(height: 8),

                    // Recent Leaves
                    if (leaveProvider.leaves.isNotEmpty)
                      _buildRecentLeaves(context, leaveProvider, colorScheme),
                    const SizedBox(height: 8),

                    // Recent Overtime
                    if (overtimeProvider.overtimes.isNotEmpty)
                      _buildRecentOvertimes(
                        context,
                        overtimeProvider,
                        colorScheme,
                      ),
                    const SizedBox(height: 8),

                    // Recent Expenses
                    if (expenseProvider.expenses.isNotEmpty)
                      _buildRecentExpenses(
                        context,
                        expenseProvider,
                        colorScheme,
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  List<Color> _getGradientColors(ColorPalette palette, bool isDark) {
    switch (palette) {
      case ColorPalette.palette1:
        // Blue tones
        return isDark
            ? [
                const Color(0xFF0047AB),
                const Color(0xFF000080),
                const Color(0xFF82C8E5),
              ]
            : [
                const Color(0xFF0047AB),
                const Color(0xFF000080),
                const Color(0xFF82C8E5),
              ];
      case ColorPalette.palette2:
        // Grayscale
        return isDark
            ? [
                const Color(0xFF2B2B2B),
                const Color(0xFF1A1A1A),
                const Color(0xFFB3B3B3),
              ]
            : [
                const Color(0xFF2B2B2B),
                const Color(0xFF1A1A1A),
                const Color(0xFFB3B3B3),
              ];
      case ColorPalette.palette3:
        // Green/Red tones
        return isDark
            ? [
                const Color(0xFF174D38),
                const Color(0xFF0F3525),
                const Color(0xFF4D1717),
              ]
            : [
                const Color(0xFF174D38),
                const Color(0xFF0F3525),
                const Color(0xFF4D1717),
              ];
    }
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    AuthProvider authProvider,
    DashboardProvider dashboardProvider,
    ColorScheme colorScheme,
    ThemeProvider themeProvider,
  ) {
    final user = authProvider.user;
    final userName = authProvider.userName ?? 'Employee';
    final profilePhotoUrl =
        user?['profilePhotoUrl'] ?? user?['employee']?['profilePhotoUrl'];
    final department =
        user?['department'] ?? user?['employee']?['department'] ?? '';
    final designation =
        user?['designation'] ?? user?['employee']?['designation'] ?? '';
    final personalInfo = dashboardProvider.dashboardStats?.personalInfo;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradientColors = _getGradientColors(
      themeProvider.colorPalette,
      isDark,
    );

    // Get designation from personalInfo or user data
    final displayDesignation = personalInfo?.designation.isNotEmpty == true
        ? personalInfo!.designation
        : (designation.isNotEmpty ? designation : '');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors[0],
                  gradientColors[1],
                  gradientColors[2].withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Animated background pattern
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _WelcomeCardPainter(
                          color: Colors.white.withValues(
                            alpha: 0.05 * _pulseAnimation.value,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting and name row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Greeting
                                AnimatedBuilder(
                                  animation: _fadeAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation.value * 0.9,
                                      child: Text(
                                        _getGreeting(),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontSize: 14,
                                              letterSpacing: 0.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Name
                                AnimatedBuilder(
                                  animation: _slideController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                        (1 - _slideController.value) * 20,
                                        0,
                                      ),
                                      child: Opacity(
                                        opacity: _slideController.value,
                                        child: Text(
                                          userName,
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 28,
                                                letterSpacing: -0.5,
                                                height: 1.2,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Designation below name
                                if (displayDesignation.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  AnimatedBuilder(
                                    animation: _fadeAnimation,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _fadeAnimation.value * 0.9,
                                        child: Text(
                                          displayDesignation,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Profile image with animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child:
                                      profilePhotoUrl != null &&
                                          profilePhotoUrl.isNotEmpty
                                      ? ClipOval(
                                          child: CachedProfileImage(
                                            imageUrl: profilePhotoUrl,
                                            radius: 30,
                                            fallbackInitials:
                                                userName.isNotEmpty
                                                ? userName
                                                      .split(' ')
                                                      .map(
                                                        (n) => n.isNotEmpty
                                                            ? n[0]
                                                            : '',
                                                      )
                                                      .take(2)
                                                      .join()
                                                : 'E',
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.2),
                                            foregroundColor: Colors.white,
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Department (if available and different from designation)
                      if (personalInfo != null) ...[
                        if (personalInfo.department.isNotEmpty &&
                            personalInfo.department != displayDesignation)
                          AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.business_center,
                                        size: 14,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          personalInfo.department,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ] else if (department.isNotEmpty &&
                          department != displayDesignation) ...[
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.business_center,
                                      size: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        department,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Date with icon
                      AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value * 0.8,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat(
                                    'EEEE, MMMM d, y',
                                  ).format(DateTime.now()),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAttendanceCard(
    BuildContext context,
    AttendanceProvider attendanceProvider,
    ColorScheme colorScheme,
    ThemeProvider themeProvider,
  ) {
    final todayAttendance = attendanceProvider.todayAttendance;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = _calculateAttendanceProgress(todayAttendance);
    final completedSteps = _getCompletedSteps(todayAttendance);

    // Update progress animation when progress value changes
    if ((progress - _previousProgress).abs() > 0.001) {
      _previousProgress = progress;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_progressController.value != progress) {
          _progressController.animateTo(progress);
        }
      });
    }

    final gradientColors = _getGradientColors(
      themeProvider.colorPalette,
      isDark,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? theme.colorScheme.surface : Colors.white,
            border: Border.all(
              color: isDark
                  ? theme.colorScheme.outline.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with progress
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: gradientColors[0].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        color: gradientColors[0],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Attendance',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedSteps of 4 completed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Circular progress indicator
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  value: _progressAnimation.value,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    gradientColors[0],
                                  ),
                                ),
                              ),
                              Text(
                                '${(_progressAnimation.value * 100).toInt()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: gradientColors[0],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Progress timeline - always show, even if no attendance marked
                _buildProgressTimeline(
                  context,
                  todayAttendance,
                  gradientColors,
                  isDark,
                ),
                const SizedBox(height: 20),

                // Working hours summary - only show if available
                if (todayAttendance != null &&
                    (todayAttendance.formattedWorkingHours != null ||
                        todayAttendance.formattedOvertimeHours != null))
                  _buildHoursSummary(
                    context,
                    todayAttendance,
                    gradientColors,
                    isDark,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTimeline(
    BuildContext context,
    dynamic attendance,
    List<Color> gradientColors,
    bool isDark,
  ) {
    final steps = [
      {
        'label': 'Check In',
        'icon': Icons.login_rounded,
        'time': attendance?.checkInTime,
        'color': Colors.green,
      },
      {
        'label': 'Lunch Start',
        'icon': Icons.restaurant_outlined,
        'time': attendance?.lunchOutTime,
        'color': Colors.orange,
      },
      {
        'label': 'Lunch End',
        'icon': Icons.restaurant,
        'time': attendance?.lunchInTime,
        'color': Colors.deepOrange,
      },
      {
        'label': 'Check Out',
        'icon': Icons.logout_rounded,
        'time': attendance?.checkOutTime,
        'color': Colors.blue,
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = step['time'] != null;
        final isLast = index == steps.length - 1;

        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: _buildTimelineStep(
                context,
                step['label'] as String,
                step['icon'] as IconData,
                step['time'] as DateTime?,
                step['color'] as Color,
                isCompleted,
                !isLast,
                gradientColors,
                isDark,
                index,
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context,
    String label,
    IconData icon,
    DateTime? time,
    Color color,
    bool isCompleted,
    bool hasConnector,
    List<Color> gradientColors,
    bool isDark,
    int index,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? color
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            if (hasConnector)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 2,
                height: 30,
                color: isCompleted
                    ? color.withValues(alpha: 0.3)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Step content
        Expanded(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCompleted
                  ? color.withValues(alpha: 0.1)
                  : (isDark ? Colors.grey.shade900 : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted
                    ? color.withValues(alpha: 0.3)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? color
                              : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time != null
                            ? DateFormat('hh:mm a').format(time)
                            : 'Not marked',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCompleted
                              ? color
                              : (isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400),
                          fontSize: 13,
                          fontWeight: isCompleted
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, color: color, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoursSummary(
    BuildContext context,
    dynamic attendance,
    List<Color> gradientColors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withValues(alpha: 0.1),
            gradientColors[1].withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors[0].withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          if (attendance.formattedWorkingHours != null) ...[
            Expanded(
              child: _buildHoursItem(
                context,
                'Working Hours',
                attendance.formattedWorkingHours!,
                Icons.schedule_rounded,
                gradientColors[0],
              ),
            ),
            if (attendance.formattedOvertimeHours != null)
              Container(
                width: 1,
                height: 40,
                color: gradientColors[0].withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
          ],
          if (attendance.formattedOvertimeHours != null)
            Expanded(
              child: _buildHoursItem(
                context,
                'Overtime',
                attendance.formattedOvertimeHours!,
                Icons.timer_rounded,
                Colors.orange,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHoursItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = colorScheme.brightness == Brightness.dark;

    final quickActions = [
      {
        'title': 'Attendance',
        'icon': Icons.access_time_rounded,
        'route': AppRoutes.myAttendance,
        'color': const Color(0xFF3B82F6), // Blue
      },
      {
        'title': 'GPS',
        'icon': Icons.location_on_rounded,
        'route': AppRoutes.gpsAttendance,
        'color': const Color(0xFF10B981), // Green
      },
      {
        'title': 'Leaves',
        'icon': Icons.event_busy_rounded,
        'route': AppRoutes.leaves,
        'color': const Color(0xFFF59E0B), // Orange
      },
      {
        'title': 'Salary',
        'icon': Icons.receipt_long_rounded,
        'route': AppRoutes.mySalarySlips,
        'color': const Color(0xFF06B6D4), // Cyan
      },
      {
        'title': 'Tasks',
        'icon': Icons.task_alt_rounded,
        'route': AppRoutes.tasks,
        'color': const Color(0xFF8B5CF6), // Purple
      },
      {
        'title': 'Expenses',
        'icon': Icons.account_balance_wallet_rounded,
        'route': AppRoutes.expenses,
        'color': const Color(0xFF14B8A6), // Teal
      },
      {
        'title': 'Overtime',
        'icon': Icons.schedule_rounded,
        'route': AppRoutes.overtime,
        'color': const Color(0xFF6366F1), // Indigo
      },
      {
        'title': 'Settings',
        'icon': Icons.settings_rounded,
        'route': AppRoutes.settings,
        'color': const Color(0xFF6B7280), // Gray
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 16),
        // Quick actions container
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive grid parameters
            final screenWidth = MediaQuery.of(context).size.width;

            // Determine cross axis count based on screen width
            int crossAxisCount;
            double childAspectRatio;
            double mainAxisSpacing;
            double crossAxisSpacing;

            if (screenWidth < 360) {
              // Very small screens - 2 columns
              crossAxisCount = 2;
              childAspectRatio = 0.75; // More height for content
              mainAxisSpacing = 10;
              crossAxisSpacing = 10;
            } else if (screenWidth < 600) {
              // Small screens - 3 columns
              crossAxisCount = 3;
              childAspectRatio = 0.8; // More height for content
              mainAxisSpacing = 12;
              crossAxisSpacing = 12;
            } else {
              // Normal screens - 4 columns
              crossAxisCount = 4;
              childAspectRatio = 0.85; // More height for content
              mainAxisSpacing = 12;
              crossAxisSpacing = 12;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _buildGraphSheetActionBlock(
                  context,
                  action['title'] as String,
                  action['icon'] as IconData,
                  action['route'] as String,
                  action['color'] as Color,
                  isDark,
                  index,
                  screenWidth,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGraphSheetActionBlock(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
    bool isDark,
    int index,
    double screenWidth,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Responsive sizing based on screen width
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    final cardPadding = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0);
    final iconPadding = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0);
    final iconSize = isSmallScreen ? 24.0 : (isMediumScreen ? 28.0 : 32.0);
    final spacing = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);
    final fontSize = isSmallScreen ? 10.0 : (isMediumScreen ? 11.0 : 12.0);
    final borderRadius = isSmallScreen ? 12.0 : 14.0;

    // Staggered animation delay
    final delay = index * 0.1;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _quickActionsController,
        curve: Interval(
          delay.clamp(0.0, 0.8),
          (delay + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85 + (animation.value * 0.15),
          child: Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - animation.value)),
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(route);
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                // Colored shadow matching the action color
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                // Deeper shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
                // Inner shadow for paper-like effect
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.0 : 0.8),
                  blurRadius: 0,
                  offset: const Offset(0, -1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? colorScheme.surface : Colors.white,
                    isDark
                        ? colorScheme.surface.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.all(iconPadding),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(borderRadius - 2),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(icon, size: iconSize, color: color),
                      ),
                    ),
                    SizedBox(height: spacing),
                    Flexible(
                      flex: 1,
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? colorScheme.onSurface
                              : Colors.grey.shade800,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTasks(
    BuildContext context,
    TaskProvider taskProvider,
    ColorScheme colorScheme,
  ) {
    final pendingTasks = taskProvider.tasks
        .where((task) => task.status == TaskStatus.pending)
        .take(3)
        .toList();

    if (pendingTasks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.tasks);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...pendingTasks.map(
          (task) => Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.tasks);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTaskStatusColor(
                          task.statusDisplay,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.task_alt,
                        color: _getTaskStatusColor(task.statusDisplay),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.location.isNotEmpty ? task.location : 'Task',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTaskStatusColor(
                          task.statusDisplay,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.statusDisplay,
                        style: TextStyle(
                          color: _getTaskStatusColor(task.statusDisplay),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildUpcomingHolidays(
    BuildContext context,
    HolidayProvider holidayProvider,
    ColorScheme colorScheme,
  ) {
    final upcomingHolidays = holidayProvider.upcomingHolidays.take(5).toList();
    final theme = Theme.of(context);
    final isDark = colorScheme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Holidays',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...upcomingHolidays.map((holiday) {
          final daysUntil = holiday.date.difference(DateTime.now()).inDays;
          final isToday = daysUntil == 0;
          final isTomorrow = daysUntil == 1;

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isToday
                      ? [Colors.orange.shade400, Colors.orange.shade600]
                      : isTomorrow
                      ? [Colors.blue.shade400, Colors.blue.shade600]
                      : [
                          isDark ? colorScheme.surface : Colors.white,
                          isDark ? colorScheme.surface : Colors.white,
                        ],
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.white.withValues(alpha: 0.3)
                              : isTomorrow
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.celebration_rounded,
                          color: isToday || isTomorrow
                              ? Colors.white
                              : Colors.orange.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holiday.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isToday || isTomorrow
                                    ? Colors.white
                                    : theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            if (holiday.description != null &&
                                holiday.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                holiday.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isToday || isTomorrow
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: isToday || isTomorrow
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(holiday.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isToday || isTomorrow
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.white.withValues(alpha: 0.3)
                              : isTomorrow
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isToday
                              ? 'Today'
                              : isTomorrow
                              ? 'Tomorrow'
                              : daysUntil > 0
                              ? '$daysUntil days'
                              : 'Past',
                          style: TextStyle(
                            color: isToday || isTomorrow
                                ? Colors.white
                                : Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentLeaves(
    BuildContext context,
    LeaveProvider leaveProvider,
    ColorScheme colorScheme,
  ) {
    final recentLeaves =
        leaveProvider.leaves
            .where(
              (leave) => leave.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final displayLeaves = recentLeaves.take(3).toList();
    if (displayLeaves.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Leaves',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.leaves);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayLeaves.map((leave) {
          final statusColor = _getLeaveStatusColor(leave.status);
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.leaves);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_busy_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.leaveTypeDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (leave.isHalfDay) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Half Day - ${leave.halfDayPeriodDisplay ?? ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leave.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentOvertimes(
    BuildContext context,
    OvertimeProvider overtimeProvider,
    ColorScheme colorScheme,
  ) {
    final recentOvertimes =
        overtimeProvider.overtimes
            .where(
              (overtime) => overtime.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final displayOvertimes = recentOvertimes.take(3).toList();
    if (displayOvertimes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Overtime',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.overtime);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayOvertimes.map((overtime) {
          final statusColor = _getOvertimeStatusColor(overtime.status);
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.overtime);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(overtime.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${overtime.startTime} - ${overtime.endTime}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (overtime.reason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              overtime.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        overtime.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentExpenses(
    BuildContext context,
    ExpenseProvider expenseProvider,
    ColorScheme colorScheme,
  ) {
    final recentExpenses =
        expenseProvider.expenses
            .where(
              (expense) => expense.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final displayExpenses = recentExpenses.take(3).toList();
    if (displayExpenses.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Expenses',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.expenses);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayExpenses.map((expense) {
          final statusColor = _getExpenseStatusColor(expense.status);
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.expenses);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  expense.categoryDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${expense.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(expense.expenseDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (expense.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              expense.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        expense.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUpcomingEvents(
    BuildContext context,
    DashboardProvider dashboardProvider,
    ColorScheme colorScheme,
  ) {
    final events = dashboardProvider.dashboardStats!.upcomingEvents.events
        .take(3)
        .toList();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...events.map(
          (event) => Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                child: const Icon(Icons.event, color: Colors.blue, size: 20),
              ),
              title: Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(DateFormat('MMM d, y').format(event.date)),
              trailing: Text(
                event.type,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTaskStatusColor(String status) {
    final statusUpper = status.toUpperCase();
    if (statusUpper.contains('PENDING')) {
      return Colors.orange;
    } else if (statusUpper.contains('PROGRESS') ||
        statusUpper.contains('IN_PROGRESS')) {
      return Colors.blue;
    } else if (statusUpper.contains('COMPLETED')) {
      return Colors.green;
    } else if (statusUpper.contains('CANCELLED')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  Color _getLeaveStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.PENDING:
        return Colors.orange;
      case LeaveStatus.APPROVED:
        return Colors.green;
      case LeaveStatus.REJECTED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getOvertimeStatusColor(OvertimeStatus status) {
    switch (status) {
      case OvertimeStatus.PENDING:
        return Colors.orange;
      case OvertimeStatus.APPROVED:
        return Colors.green;
      case OvertimeStatus.REJECTED:
        return Colors.red;
    }
  }

  Color _getExpenseStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.PENDING:
        return Colors.orange;
      case ExpenseStatus.APPROVED:
        return Colors.green;
      case ExpenseStatus.REJECTED:
        return Colors.red;
    }
  }
}

// Custom painter for welcome card background pattern
class _WelcomeCardPainter extends CustomPainter {
  final Color color;

  _WelcomeCardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw subtle circles in the background
    final center1 = Offset(size.width * 0.85, size.height * 0.2);
    final center2 = Offset(size.width * 0.15, size.height * 0.8);

    canvas.drawCircle(center1, size.width * 0.15, paint);
    canvas.drawCircle(center2, size.width * 0.12, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/admin_layout.dart';
import '../../widgets/notification_bell.dart';
import '../../core/services/attendance_service.dart';
import '../../models/attendance.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

// Helper class for quick action data
class _QuickActionData {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  _QuickActionData({
    required this.title,
    required this.icon,
    required this.route,
    required this.color,
  });
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<Attendance> _todayAttendances = [];
  bool _isLoadingAttendance = false;
  String? _attendanceError;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      _isLoadingAttendance = true;
      _attendanceError = null;
    });

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await _attendanceService.getDailyAttendance(
        date: today,
        page: 0,
        size: 1000, // Get all employees for today
      );

      debugPrint('=== Attendance Response ===');
      debugPrint('Response keys: ${response.keys}');
      debugPrint('Success: ${response['success']}');
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        debugPrint('Data type: ${data.runtimeType}');
        
        List<Attendance> attendances = [];
        
        // Handle paginated response structure
        if (data is Map<String, dynamic>) {
          debugPrint('Data keys: ${data.keys}');
          
          // Check for 'content' key (Spring Data Page format)
          // Structure: { content: [...], page: {...} }
          if (data.containsKey('content')) {
            final List<dynamic> attendanceList = data['content'] as List<dynamic>;
            debugPrint('Found content list with ${attendanceList.length} items');
            
            if (attendanceList.isNotEmpty) {
              debugPrint('First item: ${attendanceList[0]}');
            }
            
            attendances = attendanceList
                .map((json) {
                  try {
                    final attendance = Attendance.fromJson(json as Map<String, dynamic>);
                    debugPrint('Parsed: ${attendance.employeeName} - ${attendance.status}');
                    return attendance;
                  } catch (e, stackTrace) {
                    debugPrint('Error parsing attendance: $e');
                    debugPrint('Stack trace: $stackTrace');
                    debugPrint('JSON: $json');
                    return null;
                  }
                })
                .whereType<Attendance>()
                .toList();
          } else if (data is List) {
            debugPrint('Data is a list with ${data.length} items');
            final List<dynamic> attendanceList = data as List<dynamic>;
            attendances = attendanceList
                .map((json) {
                  try {
                    return Attendance.fromJson(json as Map<String, dynamic>);
                  } catch (e) {
                    debugPrint('Error parsing attendance: $e');
                    debugPrint('JSON: $json');
                    return null;
                  }
                })
                .whereType<Attendance>()
                .toList();
          } else {
            debugPrint('Data is Map but no content key found. Available keys: ${data.keys}');
          }
        } else if (data is List) {
          debugPrint('Data is a list with ${data.length} items');
          final List<dynamic> attendanceList = data as List<dynamic>;
          attendances = attendanceList
              .map((json) {
                try {
                  return Attendance.fromJson(json as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Error parsing attendance: $e');
                  debugPrint('JSON: $json');
                  return null;
                }
              })
              .whereType<Attendance>()
              .toList();
        } else {
          debugPrint('Unexpected data type: ${data.runtimeType}');
        }

        debugPrint('=== Summary ===');
        debugPrint('Total loaded: ${attendances.length} attendance records');
        final notMarked = attendances.where((a) => a.status == AttendanceStatus.notMarked).toList();
        final present = attendances.where((a) => a.status == AttendanceStatus.present).toList();
        debugPrint('Not marked: ${notMarked.length}');
        debugPrint('Present: ${present.length}');
        
        if (attendances.isNotEmpty) {
          debugPrint('Status breakdown:');
          final statusCounts = <String, int>{};
          for (var a in attendances) {
            final status = a.status.name;
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }
          statusCounts.forEach((status, count) {
            debugPrint('  $status: $count');
          });
        }

        setState(() {
          _todayAttendances = attendances;
          _isLoadingAttendance = false;
        });
      } else {
        debugPrint('No data in response: $response');
        setState(() {
          _todayAttendances = [];
          _isLoadingAttendance = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading today attendance: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _attendanceError = e.toString();
        _isLoadingAttendance = false;
      });
    }
  }

  List<Attendance> get _notMarkedEmployees {
    return _todayAttendances
        .where((a) => a.status == AttendanceStatus.notMarked)
        .toList();
  }

  List<Attendance> get _presentEmployees {
    return _todayAttendances
        .where((a) => a.status == AttendanceStatus.present)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.adminDashboard,
      title: const Text('Admin Dashboard'),
      actions: [
        const NotificationBell(),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
              tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            );
          },
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadTodayAttendance();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(_getPadding(context)),
          child: _buildDashboardContent(context),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        _buildWelcomeSection(context),
        SizedBox(height: _getSpacing(context) * 2),
        
        // Today's Attendance Overview Section
        _buildTodayAttendanceSection(context),
        SizedBox(height: _getSpacing(context) * 2),
        
        // Quick Actions Section
        _buildQuickActionsSection(context),
      ],
    );
  }

  Widget _buildTodayAttendanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.today_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Today's Attendance",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: _getTitleFontSize(context),
                          ),
                        ),
                      ),
                      if (_isLoadingAttendance)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          onPressed: _loadTodayAttendance,
                          tooltip: 'Refresh attendance',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isTablet ? 7 : 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.today_rounded,
                          size: isTablet ? 18 : 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: isTablet ? 10 : 12),
                      Text(
                        "Today's Attendance Overview",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: _getTitleFontSize(context),
                        ),
                      ),
                    ],
                  ),
                  if (_isLoadingAttendance)
                    SizedBox(
                      width: isTablet ? 20 : 24,
                      height: isTablet ? 20 : 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: isTablet ? 22 : 24,
                      ),
                      onPressed: _loadTodayAttendance,
                      tooltip: 'Refresh attendance',
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
        SizedBox(height: _getSpacing(context)),
        if (_attendanceError != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: _getSpacing(context)),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading attendance: $_attendanceError',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        if (_isLoadingAttendance && _todayAttendances.isEmpty)
          Container(
            padding: EdgeInsets.all(_getSpacing(context) * 2),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading today\'s attendance...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Debug info (can be removed in production)
              if (_todayAttendances.isEmpty && !_isLoadingAttendance)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: _getSpacing(context)),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No attendance data found for today. Check console for details.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildResponsiveAttendanceCards(context, isDark),
            ],
          ),
      ],
    );
  }

  Widget _buildResponsiveAttendanceCards(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);
    
    // For mobile: stack vertically
    // For tablet: 2 columns if width > 700, otherwise stack
    // For desktop: always side by side
    if (isMobile || (isTablet && screenWidth < 700)) {
      return Column(
        children: [
          _buildAttendanceCard(
            context,
            title: 'Not Marked',
            count: _notMarkedEmployees.length,
            employees: _notMarkedEmployees,
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          SizedBox(height: _getSpacing(context)),
          _buildAttendanceCard(
            context,
            title: 'Present',
            count: _presentEmployees.length,
            employees: _presentEmployees,
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ],
      );
    } else {
      // Tablet and Desktop: side by side
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildAttendanceCard(
              context,
              title: 'Not Marked',
              count: _notMarkedEmployees.length,
              employees: _notMarkedEmployees,
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
          SizedBox(width: _getSpacing(context)),
          Expanded(
            child: _buildAttendanceCard(
              context,
              title: 'Present',
              count: _presentEmployees.length,
              employees: _presentEmployees,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildAttendanceCard(
    BuildContext context, {
    required String title,
    required int count,
    required List<Attendance> employees,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive max height based on device type
    double maxHeight;
    if (isMobile) {
      maxHeight = screenHeight * 0.4; // 40% of screen height on mobile
    } else if (isTablet) {
      maxHeight = screenHeight * 0.45; // 45% of screen height on tablet
    } else {
      maxHeight = 500.0; // Fixed height for desktop
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        side: BorderSide(
          color: isDark ? Colors.white : Colors.black,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          color: isDark ? Colors.black : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isDark ? Colors.white : Colors.black,
                    size: isMobile ? 24 : 28,
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 18 : 20,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count ${count == 1 ? 'employee' : 'employees'}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            SizedBox(
              height: maxHeight,
                  child: employees.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(_getSpacing(context) * 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: isMobile ? 48 : 56,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No employees',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(isMobile ? 14 : 16),
                          bottomRight: Radius.circular(isMobile ? 14 : 16),
                        ),
                      ),
                      child: employees.isEmpty
                          ? const SizedBox.shrink()
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
                              itemCount: employees.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final attendance = employees[index];
                                return _buildEmployeeListItem(context, attendance, color, isDark);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeListItem(
    BuildContext context,
    Attendance attendance,
    Color color,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          border: Border.all(
            color: isDark ? Colors.white38 : Colors.black26,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Could navigate to employee details or attendance details
            },
            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
            splashColor: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
            highlightColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 14),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 40 : (isTablet ? 44 : 48),
                    height: isMobile ? 40 : (isTablet ? 44 : 48),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black12,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white38 : Colors.black38,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        attendance.employeeName.isNotEmpty
                            ? attendance.employeeName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 16 : (isTablet ? 18 : 20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.employeeName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.badge_rounded,
                                  size: 12,
                                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  attendance.employeeId,
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (attendance.checkInTime != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    attendance.formattedCheckInTime,
                                    style: TextStyle(
                                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = _isMobile(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: _getSpacing(context)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  WelcomeColors.getDarkGradientStart(),
                  WelcomeColors.getDarkGradientEnd(),
                ]
              : [
                  WelcomeColors.getLightGradientStart(),
                  WelcomeColors.getLightGradientEnd(),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? WelcomeColors.getDarkBorder()
              : WelcomeColors.getLightBorder(),
          width: 1,
        ),
        boxShadow: isDark
            ? AppThemeShadows.getDarkWelcomeShadows()
            : AppThemeShadows.getLightWelcomeShadows(),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? _getPadding(context) : _getPadding(context) * 1.5),
        child: isMobile
            ? _buildMobileWelcomeLayout(context, isDark)
            : _buildDesktopWelcomeLayout(context, isDark),
      ),
    );
  }

  Widget _buildMobileWelcomeLayout(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? WelcomeColors.getDarkDateBadgeBackground()
                      : WelcomeColors.getLightDateBadgeBackground(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? WelcomeColors.getDarkDateBadgeText()
                        : WelcomeColors.getLightDateBadgeText(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? WelcomeColors.getDarkIconGradient()
                      : WelcomeColors.getLightIconGradient(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppThemeShadows.getIconShadow()],
              ),
              child: Icon(
                Icons.dashboard_customize,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: _getSpacing(context) * 0.75),
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.2,
            color: isDark
                ? WelcomeColors.getDarkGreetingText()
                : WelcomeColors.getLightGreetingText(),
          ),
        ),
        SizedBox(height: _getSpacing(context) * 0.5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.trending_up,
                size: 14,
                color: isDark
                    ? WelcomeColors.getDarkTrendingIcon()
                    : WelcomeColors.getLightTrendingIcon(),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Manage your workforce efficiently with quick access to essential features.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: isDark
                      ? WelcomeColors.getDarkSubtitleText()
                      : WelcomeColors.getLightSubtitleText(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopWelcomeLayout(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? WelcomeColors.getDarkDateBadgeBackground()
                          : WelcomeColors.getLightDateBadgeBackground(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getFormattedDate(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? WelcomeColors.getDarkDateBadgeText()
                            : WelcomeColors.getLightDateBadgeText(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getSpacing(context)),
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                  height: 1.1,
                  color: isDark
                      ? WelcomeColors.getDarkGreetingText()
                      : WelcomeColors.getLightGreetingText(),
                ),
              ),
              SizedBox(height: _getSpacing(context) / 2),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: isDark
                        ? WelcomeColors.getDarkTrendingIcon()
                        : WelcomeColors.getLightTrendingIcon(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Manage your workforce efficiently with quick access to essential features.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? WelcomeColors.getDarkSubtitleText()
                            : WelcomeColors.getLightSubtitleText(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? WelcomeColors.getDarkIconGradient()
                  : WelcomeColors.getLightIconGradient(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [AppThemeShadows.getIconShadow()],
          ),
          child: Icon(
            Icons.dashboard_customize,
            size: 24,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    if (_isMobile(context)) {
      return _buildMobileQuickActions(context);
    } else {
      return _buildDesktopQuickActions(context);
    }
  }

  Widget _buildMobileQuickActions(BuildContext context) {
    final allActions = _getAllActions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: _getTitleFontSize(context),
              ),
        ),
        SizedBox(height: _getSpacing(context)),
        
        // Mobile: Compact grid with all actions
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allActions.length,
          itemBuilder: (context, index) {
            return _buildMobileActionCard(
              context,
              title: allActions[index].title,
              icon: allActions[index].icon,
              route: allActions[index].route,
              color: allActions[index].color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesktopQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: _getTitleFontSize(context),
                  ),
            ),
            Text(
              'Access all admin features',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
        SizedBox(height: _getSpacing(context) * 1.5),
        
        // Employee Management Section
        _buildActionCategory(
          context,
          title: 'Employee Management',
          icon: Icons.people_outline,
          actions: [
            _QuickActionData(
              title: 'Employees',
              icon: Icons.people_rounded,
              route: AppRoutes.adminEmployeeList,
              color: const Color(0xFF3B82F6), // Blue
            ),
          ],
        ),
        SizedBox(height: _getSpacing(context) * 1.5),
        
        // Attendance Section
        _buildActionCategory(
          context,
          title: 'Attendance',
          icon: Icons.access_time_outlined,
          actions: [
            _QuickActionData(
              title: 'Daily Overview',
              icon: Icons.calendar_view_day_rounded,
              route: AppRoutes.adminAttendance,
              color: const Color(0xFF06B6D4), // Cyan
            ),
            _QuickActionData(
              title: 'Mark Attendance',
              icon: Icons.camera_alt_rounded,
              route: AppRoutes.attendanceMarking,
              color: const Color(0xFF8B5CF6), // Purple
            ),
            _QuickActionData(
              title: 'View Analytics',
              icon: Icons.analytics_rounded,
              route: AppRoutes.attendanceAnalytics,
              color: const Color(0xFF6366F1), // Indigo
            ),
            _QuickActionData(
              title: 'GPS Attendance',
              icon: Icons.map_rounded,
              route: AppRoutes.gpsAttendanceMap,
              color: const Color(0xFF10B981), // Green
            ),
          ],
        ),
        SizedBox(height: _getSpacing(context) * 1.5),
        
        // Site Management Section
        _buildActionCategory(
          context,
          title: 'Site Management',
          icon: Icons.location_city_outlined,
          actions: [
            _QuickActionData(
              title: 'Manage Sites',
              icon: Icons.location_on_rounded,
              route: AppRoutes.siteManagement,
              color: const Color(0xFF059669), // Emerald
            ),
          ],
        ),
        SizedBox(height: _getSpacing(context) * 1.5),
        
        // Salary & Finance Section
        _buildActionCategory(
          context,
          title: 'Salary & Finance',
          icon: Icons.account_balance_wallet_outlined,
          actions: [
            _QuickActionData(
              title: 'Calculate Salary',
              icon: Icons.calculate_rounded,
              route: AppRoutes.adminSalaryCalculation,
              color: const Color(0xFFF59E0B), // Amber
            ),
            _QuickActionData(
              title: 'Salary Slips',
              icon: Icons.receipt_long_rounded,
              route: AppRoutes.adminSalarySlips,
              color: const Color(0xFFEC4899), // Pink
            ),
            _QuickActionData(
              title: 'Expenses',
              icon: Icons.account_balance_wallet_rounded,
              route: AppRoutes.adminExpenses,
              color: const Color(0xFF10B981), // Green
            ),
          ],
        ),
        SizedBox(height: _getSpacing(context) * 1.5),
        
        // Leave & Time Management Section
        _buildActionCategory(
          context,
          title: 'Leave & Time Management',
          icon: Icons.event_note_outlined,
          actions: [
            _QuickActionData(
              title: 'Manage Holidays',
              icon: Icons.event_rounded,
              route: AppRoutes.holidayManagement,
              color: const Color(0xFF14B8A6), // Teal
            ),
            _QuickActionData(
              title: 'Leave Management',
              icon: Icons.beach_access_rounded,
              route: AppRoutes.adminLeave,
              color: const Color(0xFF0EA5E9), // Sky
            ),
            _QuickActionData(
              title: 'Overtime',
              icon: Icons.access_time_filled_rounded,
              route: AppRoutes.adminOvertime,
              color: const Color(0xFFA855F7), // Violet
            ),
          ],
        ),
        SizedBox(height: _getSpacing(context) * 1.5),
        
        // Tasks & Settings Section
        _buildActionCategory(
          context,
          title: 'Tasks & Settings',
          icon: Icons.settings_outlined,
          actions: [
            _QuickActionData(
              title: 'Tasks',
              icon: Icons.assignment_rounded,
              route: AppRoutes.adminTasks,
              color: const Color(0xFF6366F1), // Indigo
            ),
            _QuickActionData(
              title: 'Broadcasts',
              icon: Icons.campaign_rounded,
              route: AppRoutes.adminBroadcasts,
              color: const Color(0xFFEF4444), // Red
            ),
            _QuickActionData(
              title: 'Settings',
              icon: Icons.settings_rounded,
              route: AppRoutes.adminSettings,
              color: const Color(0xFF64748B), // Slate
            ),
          ],
        ),
      ],
    );
  }

  List<_QuickActionData> _getAllActions() {
    return [
      _QuickActionData(
        title: 'Employees',
        icon: Icons.people_rounded,
        route: AppRoutes.adminEmployeeList,
        color: const Color(0xFF3B82F6),
      ),
      _QuickActionData(
        title: 'Daily Overview',
        icon: Icons.calendar_view_day_rounded,
        route: AppRoutes.adminAttendance,
        color: const Color(0xFF06B6D4),
      ),
      _QuickActionData(
        title: 'Mark Attendance',
        icon: Icons.camera_alt_rounded,
        route: AppRoutes.attendanceMarking,
        color: const Color(0xFF8B5CF6),
      ),
      _QuickActionData(
        title: 'View Analytics',
        icon: Icons.analytics_rounded,
        route: AppRoutes.attendanceAnalytics,
        color: const Color(0xFF6366F1),
      ),
      _QuickActionData(
        title: 'GPS Attendance',
        icon: Icons.map_rounded,
        route: AppRoutes.gpsAttendanceMap,
        color: const Color(0xFF10B981),
      ),
      _QuickActionData(
        title: 'Manage Sites',
        icon: Icons.location_on_rounded,
        route: AppRoutes.siteManagement,
        color: const Color(0xFF059669),
      ),
      _QuickActionData(
        title: 'Calculate Salary',
        icon: Icons.calculate_rounded,
        route: AppRoutes.adminSalaryCalculation,
        color: const Color(0xFFF59E0B),
      ),
      _QuickActionData(
        title: 'Salary Slips',
        icon: Icons.receipt_long_rounded,
        route: AppRoutes.adminSalarySlips,
        color: const Color(0xFFEC4899),
      ),
      _QuickActionData(
        title: 'Expenses',
        icon: Icons.account_balance_wallet_rounded,
        route: AppRoutes.adminExpenses,
        color: const Color(0xFF10B981),
      ),
      _QuickActionData(
        title: 'Manage Holidays',
        icon: Icons.event_rounded,
        route: AppRoutes.holidayManagement,
        color: const Color(0xFF14B8A6),
      ),
      _QuickActionData(
        title: 'Leave Management',
        icon: Icons.beach_access_rounded,
        route: AppRoutes.adminLeave,
        color: const Color(0xFF0EA5E9),
      ),
      _QuickActionData(
        title: 'Overtime',
        icon: Icons.access_time_filled_rounded,
        route: AppRoutes.adminOvertime,
        color: const Color(0xFFA855F7),
      ),
      _QuickActionData(
        title: 'Tasks',
        icon: Icons.assignment_rounded,
        route: AppRoutes.adminTasks,
        color: const Color(0xFF6366F1),
      ),
      _QuickActionData(
        title: 'Broadcasts',
        icon: Icons.campaign_rounded,
        route: AppRoutes.adminBroadcasts,
        color: const Color(0xFFEF4444),
      ),
      _QuickActionData(
        title: 'Settings',
        icon: Icons.settings_rounded,
        route: AppRoutes.adminSettings,
        color: const Color(0xFF64748B),
      ),
    ];
  }

  Widget _buildActionCategory(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_QuickActionData> actions,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: _isMobile(context) ? 16 : 18,
              ),
            ),
          ],
        ),
        SizedBox(height: _getSpacing(context)),
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            crossAxisSpacing: _getGridSpacing(context),
            mainAxisSpacing: _getGridSpacing(context),
            childAspectRatio: _getChildAspectRatio(context),
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _buildQuickActionCard(
              context,
              title: actions[index].title,
              icon: actions[index].icon,
              route: actions[index].route,
              color: actions[index].color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.1)
              : theme.colorScheme.outline.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: isDark ? 0.25 : 0.15),
                        color.withValues(alpha: isDark ? 0.15 : 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: color,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
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
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(_getCardPadding(context)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isDark
                  ? null
                  : LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.05),
                        color.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(_getIconPadding(context) * 1.2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: isDark ? 0.25 : 0.15),
                        color.withValues(alpha: isDark ? 0.15 : 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: _getCardIconSize(context),
                    color: color,
                  ),
                ),
                SizedBox(height: _getCardSpacing(context) * 1.2),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: _getCardTitleFontSize(context),
                        color: theme.colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: _getCardSpacing(context) * 0.4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: color.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Responsive helper methods
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  bool _isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600 && shortestSide < 1024;
  }

  double _getPadding(BuildContext context) {
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 16.0;
    return 20.0;
  }

  double _getSpacing(BuildContext context) {
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 16.0;
    return 20.0;
  }

  double _getTitleFontSize(BuildContext context) {
    if (_isMobile(context)) return 20.0;
    if (_isTablet(context)) return 22.0;
    return 24.0;
  }

  int _getCrossAxisCount(BuildContext context) {
    // Responsive grid columns
    if (_isMobile(context)) return 2; // Mobile: 2 columns
    if (_isTablet(context)) return 3; // Tablet: 3 columns
    return 4; // Desktop: 4 columns
  }

  double _getChildAspectRatio(BuildContext context) {
    // Adjust aspect ratio for better card proportions
    if (_isMobile(context)) return 1.1; // Mobile: slightly taller cards
    if (_isTablet(context)) return 1.3; // Tablet: balanced cards
    return 1.4; // Desktop: wider cards
  }

  double _getCardPadding(BuildContext context) {
    if (_isMobile(context)) return 14.0;
    if (_isTablet(context)) return 16.0;
    return 18.0;
  }

  double _getIconPadding(BuildContext context) {
    if (_isMobile(context)) return 8.0;
    if (_isTablet(context)) return 10.0;
    return 12.0;
  }

  double _getCardIconSize(BuildContext context) {
    if (_isMobile(context)) return 26.0;
    if (_isTablet(context)) return 30.0;
    return 34.0;
  }

  double _getCardSpacing(BuildContext context) {
    if (_isMobile(context)) return 8.0;
    if (_isTablet(context)) return 10.0;
    return 12.0;
  }

  double _getCardTitleFontSize(BuildContext context) {
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 13.0;
    return 14.0;
  }

  double _getGridSpacing(BuildContext context) {
    // Balanced spacing for better visual hierarchy
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 14.0;
    return 16.0; // More breathing room on desktop
  }
}

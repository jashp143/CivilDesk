import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/admin_layout.dart';

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
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.adminDashboard,
      title: const Text('Admin Dashboard'),
      actions: [
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
          // Refresh functionality can be added here when needed
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
        
        // Quick Actions Section
        _buildQuickActionsSection(context),
      ],
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                color: theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
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
              ? theme.colorScheme.outline.withOpacity(0.1)
              : theme.colorScheme.outline.withOpacity(0.05),
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
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
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
                        color.withOpacity(isDark ? 0.25 : 0.15),
                        color.withOpacity(isDark ? 0.15 : 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.15),
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
              ? theme.colorScheme.outline.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.1),
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
                        color.withOpacity(0.05),
                        color.withOpacity(0.02),
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
                        color.withOpacity(isDark ? 0.25 : 0.15),
                        color.withOpacity(isDark ? 0.15 : 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
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
                  color: color.withOpacity(0.5),
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

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 1024;
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

  double _getActionTitleFontSize(BuildContext context) {
    if (_isMobile(context)) return 14.0;
    if (_isTablet(context)) return 15.0;
    return 16.0;
  }

  double _getIconSize(BuildContext context) {
    if (_isMobile(context)) return 32.0;
    if (_isTablet(context)) return 36.0;
    return 40.0;
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

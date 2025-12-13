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
        GridView.count(
          crossAxisCount: _getCrossAxisCount(context),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: _getGridSpacing(context),
          mainAxisSpacing: _getGridSpacing(context),
          childAspectRatio: _getChildAspectRatio(context),
          children: [
            _buildQuickActionCard(
              context,
              title: 'Employees',
              icon: Icons.people,
              route: AppRoutes.adminEmployeeList,
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildQuickActionCard(
              context,
              title: 'Mark Attendance',
              icon: Icons.camera_alt,
              route: AppRoutes.attendanceMarking,
              color: Theme.of(context).colorScheme.secondary,
            ),
            _buildQuickActionCard(
              context,
              title: 'View Analytics',
              icon: Icons.analytics,
              route: AppRoutes.attendanceAnalytics,
              color: Colors.blue,
            ),
            _buildQuickActionCard(
              context,
              title: 'Manage Sites',
              icon: Icons.location_on,
              route: AppRoutes.siteManagement,
              color: Colors.green,
            ),
            _buildQuickActionCard(
              context,
              title: 'Calculate Salary',
              icon: Icons.calculate,
              route: AppRoutes.adminSalaryCalculation,
              color: Colors.orange,
            ),
            _buildQuickActionCard(
              context,
              title: 'GPS Attendance',
              icon: Icons.map,
              route: AppRoutes.gpsAttendanceMap,
              color: Colors.purple,
            ),
            _buildQuickActionCard(
              context,
              title: 'Manage Holidays',
              icon: Icons.event,
              route: AppRoutes.holidayManagement,
              color: Colors.teal,
            ),
            _buildQuickActionCard(
              context,
              title: 'Salary Slips',
              icon: Icons.receipt_long,
              route: AppRoutes.adminSalarySlips,
              color: Colors.indigo,
            ),
          ],
        ),
      ],
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(_getCardPadding(context)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(_getIconPadding(context)),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: _getCardIconSize(context),
                  color: color,
                ),
              ),
              SizedBox(height: _getCardSpacing(context)),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: _getCardTitleFontSize(context),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
    // Always 4 columns for 4x2 grid
    if (_isMobile(context)) return 2; // Mobile: 2 columns (4x2 becomes 2x4)
    return 4; // Tablet and Desktop: 4 columns
  }

  double _getChildAspectRatio(BuildContext context) {
    // Adjust aspect ratio for 4 columns, 2 rows layout
    if (_isMobile(context)) return 1.2; // Mobile: 2 columns
    if (_isTablet(context)) return 1.5; // Tablet: 4 columns, taller cards
    return 1.6; // Desktop: 4 columns, taller cards
  }

  double _getCardPadding(BuildContext context) {
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 14.0;
    return 16.0;
  }

  double _getIconPadding(BuildContext context) {
    if (_isMobile(context)) return 8.0;
    if (_isTablet(context)) return 10.0;
    return 12.0;
  }

  double _getCardIconSize(BuildContext context) {
    if (_isMobile(context)) return 24.0;
    if (_isTablet(context)) return 28.0;
    return 32.0;
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
    // Reduced spacing for tablet/desktop to make cards closer
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 8.0; // Tighter spacing on tablet
    return 10.0; // Tighter spacing on desktop
  }
}

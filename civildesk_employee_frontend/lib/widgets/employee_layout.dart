import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_routes.dart';
import '../core/providers/auth_provider.dart';

class EmployeeLayout extends StatefulWidget {
  final Widget child;
  final Widget title;
  final List<Widget>? actions;
  final String currentRoute;
  final Widget? floatingActionButton;
  final Widget? leading;

  const EmployeeLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    required this.currentRoute,
    this.floatingActionButton,
    this.leading,
  });

  @override
  State<EmployeeLayout> createState() => _EmployeeLayoutState();
}

class _EmployeeLayoutState extends State<EmployeeLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Menu items (flat list)
  List<DrawerItem> _buildDrawerItems() {
    return [
      DrawerItem(
        title: 'Home',
        icon: Icons.home_outlined,
        route: AppRoutes.home,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.home) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'My Attendance',
        icon: Icons.access_time_outlined,
        route: AppRoutes.myAttendance,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.myAttendance) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.myAttendance,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'Mark GPS Attendance',
        icon: Icons.location_on_outlined,
        route: AppRoutes.gpsAttendance,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.gpsAttendance) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.gpsAttendance,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'My Salary Slips',
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.mySalarySlips,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.mySalarySlips) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.mySalarySlips,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'Expenses',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.expenses,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.expenses) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.expenses,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'Overtime',
        icon: Icons.schedule_outlined,
        route: AppRoutes.overtime,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.overtime) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.overtime,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'Leaves',
        icon: Icons.event_busy_outlined,
        route: AppRoutes.leaves,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.leaves) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.leaves,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'Responsibilities',
        icon: Icons.assignment_ind_outlined,
        route: AppRoutes.responsibilities,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.responsibilities) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.responsibilities,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'Tasks',
        icon: Icons.task_alt_outlined,
        route: AppRoutes.tasks,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.tasks) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.tasks,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'Broadcasts',
        icon: Icons.campaign_outlined,
        route: AppRoutes.broadcasts,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.broadcasts) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.broadcasts,
              (route) => false,
            );
          }
        },
      ),
      DrawerItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        route: AppRoutes.settings,
        onTap: () {
          Navigator.pop(context);
          if (widget.currentRoute != AppRoutes.settings) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.settings,
              (route) => false,
            );
          }
        },
      ),
    ];
  }

  Widget _buildDrawer() {
    final items = _buildDrawerItems();
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    
    // Get user data
    final user = authProvider.user;
    final fullName = authProvider.userName ?? 'Employee';
    final designation = user?['designation'] ?? user?['employee']?['designation'] ?? '';
    final profilePhotoUrl = user?['profilePhotoUrl'] ?? user?['employee']?['profilePhotoUrl'];
    
    // Get initials for avatar
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((n) => n.isNotEmpty ? n[0].toUpperCase() : '').take(2).join()
        : 'E';

    // Theme-adaptive colors
    final menuTextColor = isDark 
        ? colorScheme.onSurface 
        : const Color(0xFF1F2937);
    final secondaryTextColor = isDark
        ? colorScheme.onSurfaceVariant
        : const Color(0xFF6B7280);
    final dividerColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.2)
        : const Color(0xFFE5E7EB);
    // Dark background for header
    final headerBgColor = colorScheme.primary;
    final headerTextColor = colorScheme.onPrimary;
    final headerSecondaryTextColor = colorScheme.onPrimary.withValues(alpha: 0.8);

    return Drawer(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerBgColor,
              border: Border(
                bottom: BorderSide(
                  color: dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Avatar (40px)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.onPrimary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: profilePhotoUrl != null && profilePhotoUrl.toString().isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              profilePhotoUrl.toString(),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarFallback(colorScheme, initials, 40, isInHeader: true);
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildAvatarFallback(colorScheme, initials, 40, isInHeader: true);
                              },
                            ),
                          )
                        : _buildAvatarFallback(colorScheme, initials, 40, isInHeader: true),
                  ),
                  const SizedBox(width: 12),
                  // Name and Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                                color: headerTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          designation.isNotEmpty ? designation : 'Employee',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: headerSecondaryTextColor,
                                fontSize: 12,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu Items (Flat List)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final active = widget.currentRoute == item.route;
                return _buildMenuItem(
                  item: item,
                  active: active,
                  theme: theme,
                  colorScheme: colorScheme,
                  menuTextColor: menuTextColor,
                  secondaryTextColor: secondaryTextColor,
                );
              },
            ),
          ),
          
          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),
          
          // Logout (Simple text + icon)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(
              Icons.logout_outlined,
              size: 20,
              color: colorScheme.error,
            ),
            title: Text(
              'Logout',
              style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        context.read<AuthProvider>().logout();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required DrawerItem item,
    required bool active,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color menuTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // Left accent bar (active state)
            if (active)
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
            // Icon
            Padding(
              padding: EdgeInsets.only(
                left: active ? 12 : 16,
                right: 12,
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: active
                    ? colorScheme.primary
                    : secondaryTextColor,
              ),
            ),
            // Title
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                      color: active ? colorScheme.primary : menuTextColor,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 15,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(ColorScheme colorScheme, String initials, double size, {bool isInHeader = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isInHeader 
            ? colorScheme.onPrimary.withValues(alpha: 0.2)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: isInHeader
                ? colorScheme.onPrimary
                : colorScheme.primary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: widget.leading,
        automaticallyImplyLeading: widget.leading == null,
        title: widget.title,
        actions: widget.actions,
      ),
      drawer: _buildDrawer(),
      body: widget.child,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class DrawerItem {
  final String title;
  final IconData icon;
  final String route;
  final VoidCallback onTap;

  DrawerItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.onTap,
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_routes.dart';
import '../core/providers/auth_provider.dart';

class EmployeeLayout extends StatefulWidget {
  final Widget child;
  final Widget title;
  final List<Widget>? actions;
  final String currentRoute;

  const EmployeeLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    required this.currentRoute,
  });

  @override
  State<EmployeeLayout> createState() => _EmployeeLayoutState();
}

class _EmployeeLayoutState extends State<EmployeeLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<DrawerItem> _buildDrawerItems() {
    return [
      DrawerItem(
        title: 'Home',
        icon: Icons.home,
        route: AppRoutes.home,
        onTap: () {
          Navigator.pop(context); // Close drawer
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
        icon: Icons.access_time,
        route: AppRoutes.myAttendance,
        onTap: () {
          Navigator.pop(context); // Close drawer
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
        title: 'My Salary Slips',
        icon: Icons.receipt_long,
        route: AppRoutes.mySalarySlips,
        onTap: () {
          Navigator.pop(context); // Close drawer
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
        title: 'Leaves',
        icon: Icons.event_busy,
        route: AppRoutes.leaves,
        onTap: () {
          Navigator.pop(context); // Close drawer
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
        title: 'Overtime',
        icon: Icons.schedule,
        route: AppRoutes.overtime,
        onTap: () {
          Navigator.pop(context); // Close drawer
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
        title: 'Expenses',
        icon: Icons.account_balance_wallet,
        route: AppRoutes.expenses,
        onTap: () {
          Navigator.pop(context); // Close drawer
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
        title: 'Tasks',
        icon: Icons.task_alt,
        route: AppRoutes.tasks,
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (widget.currentRoute != AppRoutes.tasks) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.tasks,
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
    final isActive = (String route) => widget.currentRoute == route;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.person,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  authProvider.userName ?? 'Employee',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  authProvider.user?['email'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final active = isActive(item.route);
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  selected: active,
                  onTap: item.onTap,
                );
              },
            ),
          ),
          // Logout Button
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: widget.title,
        actions: widget.actions,
      ),
      drawer: _buildDrawer(),
      body: widget.child,
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


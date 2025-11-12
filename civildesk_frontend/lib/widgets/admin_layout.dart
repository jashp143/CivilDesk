import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_routes.dart';
import '../core/providers/auth_provider.dart';
import 'collapsible_sidebar.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  final Widget title;
  final List<Widget>? actions;
  final String currentRoute;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    required this.currentRoute,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  List<SidebarItem> _buildSidebarItems() {
    return [
      SidebarItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: AppRoutes.adminDashboard,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminDashboard) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.adminDashboard,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Employees',
        icon: Icons.people,
        route: AppRoutes.adminEmployeeList,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminEmployeeList) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.adminEmployeeList,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Attendance',
        icon: Icons.access_time,
        route: AppRoutes.adminAttendance,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminAttendance) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.adminAttendance,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Mark Attendance',
        icon: Icons.camera_alt,
        route: AppRoutes.attendanceMarking,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.attendanceMarking,
          );
        },
      ),
      SidebarItem(
        title: 'Salary',
        icon: Icons.payments,
        route: AppRoutes.adminSalary,
        onTap: () {
          // Placeholder for future implementation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salary feature coming soon')),
          );
        },
      ),
      SidebarItem(
        title: 'Leave',
        icon: Icons.event_busy,
        route: AppRoutes.adminLeave,
        onTap: () {
          // Placeholder for future implementation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave feature coming soon')),
          );
        },
      ),
      SidebarItem(
        title: 'Reports',
        icon: Icons.assessment,
        route: AppRoutes.adminReports,
        onTap: () {
          // Placeholder for future implementation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reports feature coming soon')),
          );
        },
      ),
      SidebarItem(
        title: 'Settings',
        icon: Icons.settings,
        route: AppRoutes.adminSettings,
        onTap: () {
          // Placeholder for future implementation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings feature coming soon')),
          );
        },
      ),
      SidebarItem(
        title: 'Logout',
        icon: Icons.logout,
        route: '/logout',
        onTap: () {
          context.read<AuthProvider>().logout();
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CollapsibleSidebar(
        currentRoute: widget.currentRoute,
        items: _buildSidebarItems(),
        title: widget.title,
        actions: widget.actions,
        child: widget.child,
      ),
    );
  }
}


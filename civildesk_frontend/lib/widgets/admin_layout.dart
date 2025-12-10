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
  final bool showBackButton;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    required this.currentRoute,
    this.showBackButton = false,
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
        title: 'Site Management',
        icon: Icons.location_on,
        route: AppRoutes.siteManagement,
        onTap: () {
          if (widget.currentRoute != AppRoutes.siteManagement) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.siteManagement,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'GPS Attendance Map',
        icon: Icons.map,
        route: AppRoutes.gpsAttendanceMap,
        onTap: () {
          if (widget.currentRoute != AppRoutes.gpsAttendanceMap) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.gpsAttendanceMap,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Attendance Analytics',
        icon: Icons.analytics,
        route: AppRoutes.attendanceAnalytics,
        onTap: () {
          if (widget.currentRoute != AppRoutes.attendanceAnalytics) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.attendanceAnalytics,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Holidays',
        icon: Icons.event,
        route: AppRoutes.holidayManagement,
        onTap: () {
          if (widget.currentRoute != AppRoutes.holidayManagement) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.holidayManagement,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Salary Slips',
        icon: Icons.receipt_long,
        route: AppRoutes.adminSalarySlips,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminSalarySlips) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.adminSalarySlips,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Calculate Salary',
        icon: Icons.calculate,
        route: AppRoutes.adminSalaryCalculation,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminSalaryCalculation) {
            Navigator.pushNamed(
              context,
              AppRoutes.adminSalaryCalculation,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Leave',
        icon: Icons.event_busy,
        route: AppRoutes.adminLeave,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminLeave) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.adminLeave,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Overtime',
        icon: Icons.schedule,
        route: AppRoutes.adminOvertime,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminOvertime) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.adminOvertime,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Expenses',
        icon: Icons.receipt_long,
        route: AppRoutes.adminExpenses,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminExpenses) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.adminExpenses,
              (route) => false,
            );
          }
        },
      ),
      SidebarItem(
        title: 'Tasks',
        icon: Icons.task_alt,
        route: AppRoutes.adminTasks,
        onTap: () {
          if (widget.currentRoute != AppRoutes.adminTasks) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.adminTasks,
              (route) => false,
            );
          }
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
    ];
  }

  SidebarItem _getLogoutItem() {
    return SidebarItem(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CollapsibleSidebar(
        currentRoute: widget.currentRoute,
        items: _buildSidebarItems(),
        logoutItem: _getLogoutItem(),
        title: widget.title,
        actions: widget.actions,
        showBackButton: widget.showBackButton,
        child: widget.child,
      ),
    );
  }
}


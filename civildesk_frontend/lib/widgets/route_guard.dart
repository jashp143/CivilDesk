import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/auth_provider.dart';

/// Route guard widget that checks authentication and role requirements
class RouteGuard extends StatelessWidget {
  final Widget child;
  final List<String>? allowedRoles;
  final bool requireAuth;

  const RouteGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if authentication is required
        if (requireAuth && !authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user has required role
        if (requireAuth && allowedRoles != null && allowedRoles!.isNotEmpty) {
          final userRole = authProvider.userRole;
          if (userRole == null || !allowedRoles!.contains(userRole)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You do not have permission to access this page.'),
                  backgroundColor: Colors.red,
                ),
              );
            });
            return const Scaffold(
              body: Center(
                child: Text('Access Denied'),
              ),
            );
          }
        }

        return child;
      },
    );
  }
}

/// Helper widget for admin-only routes
class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      allowedRoles: [AppConstants.roleAdmin],
      child: child,
    );
  }
}

/// Helper widget for HR Manager and Admin routes
class ManagerRouteGuard extends StatelessWidget {
  final Widget child;

  const ManagerRouteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      allowedRoles: [AppConstants.roleAdmin, AppConstants.roleHrManager],
      child: child,
    );
  }
}

/// Helper widget for employee-only routes
class EmployeeRouteGuard extends StatelessWidget {
  final Widget child;

  const EmployeeRouteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      allowedRoles: [AppConstants.roleEmployee],
      child: child,
    );
  }
}


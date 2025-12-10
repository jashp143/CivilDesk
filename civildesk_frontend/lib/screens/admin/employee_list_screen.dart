import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/services/face_recognition_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employee.dart';
import '../../widgets/admin_layout.dart';
import '../../widgets/cached_profile_image.dart';
import 'employee_detail_dialog.dart';
import 'employee_registration_dialog.dart';
import 'employee_edit_dialog.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<EmployeeProvider>().loadMoreEmployees();
    }
  }

  void _handleSearch(String query) {
    final provider = context.read<EmployeeProvider>();
    provider.setSearchQuery(query.isEmpty ? null : query);
    provider.loadEmployees(refresh: true);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.adminEmployeeList,
      title: const Text('Employee Management'),
      actions: [
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: _showFilters,
          tooltip: 'Filters',
        ),
        IconButton(
          icon: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const EmployeeRegistrationDialog(),
            ).then((result) {
              if (result == true && mounted) {
                context.read<EmployeeProvider>().loadEmployees(refresh: true);
              }
            });
          },
          tooltip: 'Add Employee',
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _handleSearch,
            ),
          ),
          Expanded(
            child: Consumer<EmployeeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.employees.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${provider.error}',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadEmployees(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.employees.isEmpty) {
                  return const Center(
                    child: Text('No employees found'),
                  );
                }

                final isMobile = MediaQuery.of(context).size.shortestSide < 600;
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadEmployees(refresh: true);
                  },
                  color: Theme.of(context).colorScheme.primary,
                  child: isMobile
                      ? _buildMobileView(provider)
                      : _buildDesktopTableView(context, provider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView(EmployeeProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.employees.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.employees.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final employee = provider.employees[index];
        return _EmployeeListItem(
          employee: employee,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => EmployeeDetailDialog(
                employeeId: employee.id!,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopTableView(BuildContext context, EmployeeProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Table Header - Sticky
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline,
                  width: 2,
                ),
              ),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.8), // Employee ID
                1: FlexColumnWidth(3.0), // Full Name
                2: FlexColumnWidth(2.2), // Department
                3: FlexColumnWidth(2.2), // Designation
                4: FlexColumnWidth(1.8), // Status
                5: FlexColumnWidth(2.0), // Actions
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeaderCell('Employee ID', theme, Icons.badge),
                    _buildTableHeaderCell('Full Name', theme, Icons.person),
                    _buildTableHeaderCell('Department', theme, Icons.business),
                    _buildTableHeaderCell('Designation', theme, Icons.work),
                    _buildTableHeaderCell('Status', theme, Icons.circle),
                    _buildTableHeaderCell('Actions', theme, Icons.more_vert),
                  ],
                ),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.8), // Employee ID
                  1: FlexColumnWidth(3.0), // Full Name
                  2: FlexColumnWidth(2.2), // Department
                  3: FlexColumnWidth(2.2), // Designation
                  4: FlexColumnWidth(1.8), // Status
                  5: FlexColumnWidth(2.0), // Actions
                },
                children: [
                  ...provider.employees.asMap().entries.map((entry) {
                    final index = entry.key;
                    final employee = entry.value;
                    return _buildTableRow(context, employee, theme, index);
                  }).toList(),
                ],
              ),
            ),
          ),
          // Loading indicator for pagination
          if (provider.hasMore)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, ThemeData theme, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(BuildContext context, Employee employee, ThemeData theme, int index) {
    final colorScheme = theme.colorScheme;
    final isEven = index % 2 == 0;
    
    return TableRow(
      decoration: BoxDecoration(
        color: isEven 
            ? colorScheme.surface 
            : colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      children: [
        _buildTableCell(
          employee.employeeId,
          theme,
          icon: Icons.badge_outlined,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => EmployeeDetailDialog(
                employeeId: employee.id!,
              ),
            );
          },
        ),
        _buildNameCell(context, employee, theme),
        _buildTableCell(
          employee.department ?? 'N/A',
          theme,
          icon: Icons.business_outlined,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => EmployeeDetailDialog(
                employeeId: employee.id!,
              ),
            );
          },
        ),
        _buildTableCell(
          employee.designation ?? 'N/A',
          theme,
          icon: Icons.work_outline,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => EmployeeDetailDialog(
                employeeId: employee.id!,
              ),
            );
          },
        ),
        _buildStatusCell(employee, theme),
        _buildActionsCell(context, employee, theme),
      ],
    );
  }

  Widget _buildTableCell(String text, ThemeData theme, {IconData? icon, VoidCallback? onTap}) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: onTap,
        hoverColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameCell(BuildContext context, Employee employee, ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    final colorScheme = theme.colorScheme;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => EmployeeDetailDialog(
              employeeId: employee.id!,
            ),
          );
        },
        hoverColor: primaryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CachedProfileImage(
                imageUrl: employee.profilePhotoUrl,
                fallbackInitials: employee.firstName,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                radius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      employee.fullName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (employee.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        employee.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCell(Employee employee, ThemeData theme) {
    final isActive = employee.employmentStatus == EmploymentStatus.active;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.statusApproved.withOpacity(0.15)
              : AppTheme.statusRejected.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.statusApproved.withOpacity(0.3)
                : AppTheme.statusRejected.withOpacity(0.3),
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
                color: isActive
                    ? AppTheme.statusApproved
                    : AppTheme.statusRejected,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isActive ? 'Active' : 'Inactive',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive
                    ? AppTheme.statusApproved
                    : AppTheme.statusRejected,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCell(BuildContext context, Employee employee, ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'View Details',
            child: IconButton(
              icon: Icon(
                Icons.visibility_outlined,
                color: primaryColor,
                size: 20,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => EmployeeDetailDialog(
                    employeeId: employee.id!,
                  ),
                );
              },
              tooltip: 'View Details',
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Edit Employee',
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: primaryColor,
                size: 20,
              ),
              onPressed: () => _handleEdit(context, employee),
              tooltip: 'Edit Employee',
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Delete Employee',
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              onPressed: () => _handleDelete(context, employee),
              tooltip: 'Delete Employee',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEdit(BuildContext context, Employee employee) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EmployeeEditDialog(employee: employee),
    );
    
    if (result == true && mounted) {
      context.read<EmployeeProvider>().loadEmployees(refresh: true);
    }
  }

  Future<void> _handleDelete(BuildContext context, Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete ${employee.fullName}?\n\nThis will also delete their face recognition data.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<EmployeeProvider>();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Delete face embeddings if they exist
        final faceService = FaceRecognitionService();
        await faceService.deleteFaceEmbeddings(employee.employeeId);

        // Delete employee
        final success = await provider.deleteEmployee(employee.id!);
        
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Employee deleted successfully'
                    : 'Failed to delete employee: ${provider.error ?? "Unknown error"}',
              ),
              backgroundColor: success ? AppTheme.statusApproved : Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting employee: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class _EmployeeListItem extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const _EmployeeListItem({
    required this.employee,
    required this.onTap,
  });

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete ${employee.fullName}?\n\nThis will also delete their face recognition data.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<EmployeeProvider>();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Delete face embeddings if they exist
        final faceService = FaceRecognitionService();
        await faceService.deleteFaceEmbeddings(employee.employeeId);

        // Delete employee
        final success = await provider.deleteEmployee(employee.id!);
        
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Employee deleted successfully'
                    : 'Failed to delete employee: ${provider.error ?? "Unknown error"}',
              ),
              backgroundColor: success ? AppTheme.statusApproved : Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting employee: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EmployeeEditDialog(employee: employee),
    );
    
    if (result == true && context.mounted) {
      context.read<EmployeeProvider>().loadEmployees(refresh: true);
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    
    if (isMobile) {
      return _buildMobileCard(context);
    } else {
      return _buildDesktopCard(context);
    }
  }

  Widget _buildMobileCard(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Profile Image, Name, and Status
              Row(
                children: [
                  CachedProfileImage(
                    imageUrl: employee.profilePhotoUrl,
                    fallbackInitials: employee.firstName,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: employee.employmentStatus == EmploymentStatus.active
                                ? AppTheme.statusApproved.withOpacity(0.1)
                                : AppTheme.statusRejected.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                employee.employmentStatus == EmploymentStatus.active
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: employee.employmentStatus == EmploymentStatus.active
                                    ? AppTheme.statusApproved
                                    : AppTheme.statusRejected,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                employee.employmentStatus == EmploymentStatus.active
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: employee.employmentStatus == EmploymentStatus.active
                                      ? AppTheme.statusApproved
                                      : AppTheme.statusRejected,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Employee Details
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildMobileInfoRow(
                      context,
                      Icons.badge,
                      'ID: ${employee.employeeId}',
                    ),
                    if (employee.department != null) ...[
                      const SizedBox(height: 6),
                      _buildMobileInfoRow(
                        context,
                        Icons.business,
                        employee.department!,
                      ),
                    ],
                    if (employee.designation != null) ...[
                      const SizedBox(height: 6),
                      _buildMobileInfoRow(
                        context,
                        Icons.work,
                        employee.designation!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Action Buttons - Full Width
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleEdit(context),
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: primaryColor,
                      ),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        foregroundColor: primaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDelete(context),
                      icon: Icon(
                        Icons.delete,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        foregroundColor: Theme.of(context).colorScheme.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildMobileInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Profile Image
              CachedProfileImage(
                imageUrl: employee.profilePhotoUrl,
                fallbackInitials: employee.firstName,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              const SizedBox(width: 16),
              // Employee Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: employee.employmentStatus == EmploymentStatus.active
                                ? AppTheme.statusApproved.withOpacity(0.1)
                                : AppTheme.statusRejected.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                employee.employmentStatus == EmploymentStatus.active
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: employee.employmentStatus == EmploymentStatus.active
                                    ? AppTheme.statusApproved
                                    : AppTheme.statusRejected,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                employee.employmentStatus == EmploymentStatus.active
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: employee.employmentStatus == EmploymentStatus.active
                                      ? AppTheme.statusApproved
                                      : AppTheme.statusRejected,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ID: ${employee.employeeId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (employee.department != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            employee.department!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (employee.designation != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            employee.designation!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: primaryColor,
                    ),
                    onPressed: () => _handleEdit(context),
                    tooltip: 'Edit Employee',
                    style: IconButton.styleFrom(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _handleDelete(context),
                    tooltip: 'Delete Employee',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      padding: const EdgeInsets.all(8),
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
}

class _FilterBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: provider.departmentFilter,
            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Departments')),
              // Add more departments as needed
            ],
            onChanged: (value) {
              provider.setDepartmentFilter(value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<EmploymentStatus>(
            initialValue: provider.statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Statuses')),
              DropdownMenuItem(
                value: EmploymentStatus.active,
                child: Text('Active'),
              ),
              DropdownMenuItem(
                value: EmploymentStatus.inactive,
                child: Text('Inactive'),
              ),
            ],
            onChanged: (value) {
              provider.setStatusFilter(value);
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  provider.clearFilters();
                  provider.loadEmployees(refresh: true);
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  provider.loadEmployees(refresh: true);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
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
    _searchController.addListener(() {
      setState(() {}); // Rebuild to update suffix icons
    });
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

  Widget? _buildSuffixIcons(BuildContext context, EmployeeProvider provider, bool hasActiveFilters) {
    final List<Widget> icons = [];
    
    // Add filter button
    icons.add(
      Tooltip(
        message: 'Filters',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: hasActiveFilters
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: _showFilters,
              tooltip: 'Filters',
            ),
            if (hasActiveFilters)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    
    // Add clear button if search text is not empty
    if (_searchController.text.isNotEmpty) {
      icons.add(
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            _handleSearch('');
          },
          tooltip: 'Clear search',
        ),
      );
    }
    
    if (icons.isEmpty) return null;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    
    return AdminLayout(
      currentRoute: AppRoutes.adminEmployeeList,
      title: Text(
        'Employee Management',
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: isMobile ? 20 : 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.2,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.add_rounded,
            size: isMobile ? 24 : 26,
          ),
          iconSize: isMobile ? 24 : 26,
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          constraints: BoxConstraints(
            minWidth: isMobile ? 40 : 48,
            minHeight: isMobile ? 40 : 48,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const EmployeeRegistrationDialog(),
            ).then((result) {
              if (result == true && context.mounted) {
                final provider = context.read<EmployeeProvider>();
                provider.loadEmployees(refresh: true);
              }
            });
          },
          tooltip: 'Add Employee',
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
            child: Consumer<EmployeeProvider>(
              builder: (context, provider, child) {
                final hasActiveFilters = provider.departmentFilter != null ||
                    provider.statusFilter != null ||
                    provider.designationFilter != null ||
                    provider.typeFilter != null;
                
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search employees...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buildSuffixIcons(context, provider, hasActiveFilters),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _handleSearch,
                );
              },
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate minimum table width based on content
        // Actions column (170) + other columns need at least 1000px
        final minTableWidth = 1200.0;
        final tableWidth = constraints.maxWidth > minTableWidth 
            ? constraints.maxWidth - 32 
            : minTableWidth;
        
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.8), // Employee ID
                      1: FlexColumnWidth(3.0), // Full Name
                      2: FlexColumnWidth(2.2), // Department
                      3: FlexColumnWidth(2.2), // Designation
                      4: FlexColumnWidth(1.8), // Status
                      5: FixedColumnWidth(170), // Actions column needs fixed width for 3 icons
                    },
                    children: [
                      // Header Row
                      TableRow(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outline,
                              width: 2,
                            ),
                          ),
                        ),
                        children: [
                          _buildTableHeaderCell('Employee ID', theme, Icons.badge),
                          _buildTableHeaderCell('Full Name', theme, Icons.person),
                          _buildTableHeaderCell('Department', theme, Icons.business),
                          _buildTableHeaderCell('Designation', theme, Icons.work),
                          _buildTableHeaderCell('Status', theme, Icons.circle),
                          _buildTableHeaderCell('Actions', theme, Icons.more_vert),
                        ],
                      ),
                      // Data Rows
                      ...provider.employees.asMap().entries.map((entry) {
                        final index = entry.key;
                        final employee = entry.value;
                        return _buildTableRow(context, employee, theme, index);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
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
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
        hoverColor: primaryColor.withValues(alpha: 0.1),
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
              ? AppTheme.statusApproved.withValues(alpha: 0.15)
              : AppTheme.statusRejected.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.statusApproved.withValues(alpha: 0.3)
                : AppTheme.statusRejected.withValues(alpha: 0.3),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Tooltip(
            message: 'View Details',
            child: IconButton(
              icon: Icon(
                Icons.visibility_outlined,
                color: primaryColor,
                size: 18,
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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
                maxWidth: 36,
                maxHeight: 36,
              ),
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: 'Edit Employee',
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: primaryColor,
                size: 18,
              ),
              onPressed: () => _handleEdit(context, employee),
              tooltip: 'Edit Employee',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
                maxWidth: 36,
                maxHeight: 36,
              ),
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: 'Delete Employee',
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 18,
              ),
              onPressed: () => _handleDelete(context, employee),
              tooltip: 'Delete Employee',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
                maxWidth: 36,
                maxHeight: 36,
              ),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
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
    
    if (result == true && context.mounted) {
      final provider = context.read<EmployeeProvider>();
      provider.loadEmployees(refresh: true);
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Name, Status, and 3-dot Menu
              Row(
                children: [
                  CachedProfileImage(
                    imageUrl: employee.profilePhotoUrl,
                    fallbackInitials: employee.firstName,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Status Badge - Clean Pill Design
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: employee.employmentStatus == EmploymentStatus.active
                                ? AppTheme.statusApproved.withValues(alpha: 0.12)
                                : AppTheme.statusRejected.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                employee.employmentStatus == EmploymentStatus.active
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 14,
                                color: employee.employmentStatus == EmploymentStatus.active
                                    ? AppTheme.statusApproved
                                    : AppTheme.statusRejected,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                employee.employmentStatus == EmploymentStatus.active
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                  // 3-dot Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _handleEdit(context);
                      } else if (value == 'delete') {
                        _handleDelete(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Soft Divider
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              // Key Details - Clean Two-Column Layout (No Icons, No Boxes)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Employee ID, Department, Designation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCleanDetailRow(
                          context,
                          'Employee ID',
                          employee.employeeId,
                        ),
                        if (employee.department != null) ...[
                          const SizedBox(height: 8),
                          _buildCleanDetailRow(
                            context,
                            'Department',
                            employee.department!,
                          ),
                        ],
                        if (employee.designation != null) ...[
                          const SizedBox(height: 8),
                          _buildCleanDetailRow(
                            context,
                            'Designation',
                            employee.designation!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Column: Date of Birth, Gender, Attendance Method
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (employee.dateOfBirth != null) ...[
                          _buildCleanDetailRow(
                            context,
                            'Date of Birth',
                            _formatDateOfBirth(employee.dateOfBirth!),
                          ),
                          if (employee.gender != null || employee.attendanceMethod != null)
                            const SizedBox(height: 8),
                        ],
                        if (employee.gender != null) ...[
                          _buildCleanDetailRow(
                            context,
                            'Gender',
                            _formatGender(employee.gender!),
                          ),
                          if (employee.attendanceMethod != null)
                            const SizedBox(height: 8),
                        ],
                        if (employee.attendanceMethod != null)
                          _buildCleanDetailRow(
                            context,
                            'Attendance Method',
                            _formatAttendanceMethod(employee.attendanceMethod!),
                          ),
                      ],
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

  Widget _buildCleanDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDateOfBirth(DateTime dateOfBirth) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateOfBirth.day} ${months[dateOfBirth.month - 1]}, ${dateOfBirth.year}';
  }

  String _formatGender(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  String _formatAttendanceMethod(AttendanceMethod method) {
    switch (method) {
      case AttendanceMethod.faceRecognition:
        return 'Face Recognition';
      case AttendanceMethod.gpsBased:
        return 'GPS Based';
    }
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
                                ? AppTheme.statusApproved.withValues(alpha: 0.1)
                                : AppTheme.statusRejected.withValues(alpha: 0.1),
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
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
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
                      backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
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


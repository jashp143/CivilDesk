import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/services/face_recognition_service.dart';
import '../../models/employee.dart';
import '../../widgets/admin_layout.dart';
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
      title: const Text('Employees'),
      actions: [
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: _showFilters,
          tooltip: 'Filters',
        ),
        IconButton(
          icon: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onPrimary,
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
                          style: const TextStyle(color: Colors.red),
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

                return RefreshIndicator(
                  onRefresh: () => provider.loadEmployees(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting employee: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            employee.firstName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(employee.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${employee.employeeId}'),
            if (employee.department != null)
              Text('Dept: ${employee.department}'),
            if (employee.designation != null)
              Text('Designation: ${employee.designation}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            employee.employmentStatus == EmploymentStatus.active
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _handleDelete(context),
              tooltip: 'Delete Employee',
            ),
          ],
        ),
        onTap: onTap,
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


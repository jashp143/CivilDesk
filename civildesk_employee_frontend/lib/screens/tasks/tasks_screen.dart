import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/employee_layout.dart';
import '../../core/providers/task_provider.dart';
import '../../models/task.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchMyTasks();
    });
  }

  Future<void> _refreshTasks() async {
    await Provider.of<TaskProvider>(context, listen: false).fetchMyTasks();
  }

  void _showFilterDialog() {
    final provider = Provider.of<TaskProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TaskStatus?>(
                    value: provider.selectedStatusFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'All Statuses',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<TaskStatus?>(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      ...TaskStatus.values.map((status) {
                        return DropdownMenuItem<TaskStatus?>(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      provider.setStatusFilter(value);
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearFilter();
              Navigator.pop(context);
            },
            child: const Text('CLEAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  void _viewTaskDetails(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
    if (result == true) {
      _refreshTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      currentRoute: AppRoutes.tasks,
      title: const Text('Tasks'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filter',
        ),
      ],
      child: Column(
        children: [
          // Filter Chip Bar
          Consumer<TaskProvider>(
            builder: (context, provider, child) {
              if (provider.selectedStatusFilter != null) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(
                          'Status: ${provider.selectedStatusFilter!.displayName}',
                        ),
                        onDeleted: () {
                          provider.clearFilter();
                        },
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Tasks List
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshTasks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = provider.filteredTasks;

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        Text(
                          provider.selectedStatusFilter != null
                              ? 'No tasks found with selected filter'
                              : 'No Tasks Assigned',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        if (provider.selectedStatusFilter != null)
                          ElevatedButton(
                            onPressed: () {
                              provider.clearFilter();
                            },
                            child: const Text('Clear Filter'),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(task);
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

  Widget _buildTaskCard(Task task) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case TaskStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          task.statusDisplay,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Location
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.location,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date Range
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${DateFormat('dd MMM').format(task.startDate)} - ${DateFormat('dd MMM yyyy').format(task.endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Mode of Travel
              Row(
                children: [
                  Icon(Icons.directions_transit, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.modeOfTravelDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Description Preview
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Assigned By
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'By: ${task.assignedBy.name}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

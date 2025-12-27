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
  String? _selectedStatusFilter; // null means 'All'
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = null; // Show all by default
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).refreshTasks();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMoreTasks();
      }
    }
  }

  Future<void> _refreshTasks() async {
    await Provider.of<TaskProvider>(context, listen: false).refreshTasks();
  }

  void _viewTaskDetails(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
    // Refresh tasks list when returning from detail screen
    // The provider's reviewTask method updates the task locally,
    // but we refresh to ensure consistency
    if (result == true) {
      await _refreshTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return EmployeeLayout(
      currentRoute: AppRoutes.tasks,
      title: const Text('My Tasks'),
      child: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'All',
                    _selectedStatusFilter == null,
                    () {
                      setState(() {
                        _selectedStatusFilter = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'Pending',
                    _selectedStatusFilter == 'pending',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'pending';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'Approved',
                    _selectedStatusFilter == 'approved',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'approved';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'Rejected',
                    _selectedStatusFilter == 'rejected',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'rejected';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Tasks List
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                // Filter tasks based on selected status
                final filteredTasks = _selectedStatusFilter == null
                    ? provider.tasks
                    : provider.tasks.where((task) {
                        return task.status.toString().split('.').last.toLowerCase() == _selectedStatusFilter;
                      }).toList();
                
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: _getErrorColor(colorScheme),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
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

                if (provider.tasks.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Tasks Assigned',
                              style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'You don\'t have any tasks assigned yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshTasks,
                  color: Theme.of(context).colorScheme.primary,
                  child: filteredTasks.isEmpty && provider.tasks.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off_rounded,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${_selectedStatusFilter ?? ''} tasks found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                          itemCount: filteredTasks.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredTasks.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final task = filteredTasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 0),
                              child: _buildTaskCard(task),
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

  Widget _buildFilterChip(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(task.status, colorScheme);
    final statusIcon = _getStatusIcon(task.status);
    final statusLabel = task.statusDisplay.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shadowColor: Colors.transparent,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Location + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Icon + Location
                  Expanded(
                    child: Row(
                      children: [
                        // Task Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.assignment_rounded,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Location
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.location.toUpperCase(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_view_week_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${DateFormat('MMM dd').format(task.startDate)} - ${DateFormat('MMM dd, yyyy').format(task.endDate)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 13,
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
                      ],
                    ),
                  ),
                  // Right: Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date Range Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // Start Date
                    Row(
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy').format(task.startDate),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Divider
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    // End Date
                    Row(
                      children: [
                        Icon(
                          Icons.stop_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy').format(task.endDate),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Mode of Travel
              Row(
                children: [
                  Icon(
                    Icons.directions_transit_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mode: ${task.modeOfTravelDisplay}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ],
              ),
              
              // Your Comment (if exists)
              if (task.reviewNote != null && task.reviewNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.comment_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Comment',
                              style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.reviewNote!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Assigned By (only show if role is ADMIN or HR_MANAGER)
              if (task.assignedBy.role.toUpperCase() == 'ADMIN' || 
                  task.assignedBy.role.toUpperCase() == 'HR_MANAGER')
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Assigned by: ${task.assignedBy.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              
              // Submitted timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(task.createdAt)} • ${DateFormat('hh:mm a').format(task.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
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

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.approved:
        return Icons.check_circle;
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.rejected:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(TaskStatus status, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    switch (status) {
      case TaskStatus.approved:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case TaskStatus.pending:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      case TaskStatus.rejected:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
    }
  }

  Color _getErrorColor(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? const Color(0xFFEF5350) // More vibrant red for dark mode
        : const Color(0xFFC62828);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/broadcast_provider.dart';
import '../../models/broadcast.dart';
import '../../widgets/admin_layout.dart';
import '../../widgets/toast.dart';

class BroadcastManagementScreen extends StatefulWidget {
  const BroadcastManagementScreen({super.key});

  @override
  State<BroadcastManagementScreen> createState() =>
      _BroadcastManagementScreenState();
}

class _BroadcastManagementScreenState extends State<BroadcastManagementScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BroadcastProvider>().refreshBroadcasts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !mounted) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (maxScroll > 0 && currentScroll >= maxScroll * 0.8) {
      final provider = context.read<BroadcastProvider>();
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMore();
      }
    }
  }

  // Responsive helper methods
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  bool _isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600 && shortestSide < 1024;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 1024;
  }

  double _getPadding(BuildContext context) {
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 16.0;
    return 20.0;
  }

  double _getSpacing(BuildContext context) {
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 16.0;
    return 20.0;
  }

  double _getCardPadding(BuildContext context) {
    if (_isMobile(context)) return 12.0;
    if (_isTablet(context)) return 16.0;
    return 20.0;
  }

  void _showAddBroadcastDialog({BroadcastMessage? broadcast}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: broadcast?.title ?? '');
    final messageController = TextEditingController(
      text: broadcast?.message ?? '',
    );
    String selectedPriority = broadcast?.priority ?? 'NORMAL';
    bool isActive = broadcast?.isActive ?? true;

    final isMobile = _isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          ),
          contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
          actionsPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 8 : 16,
          ),
          title: Row(
            children: [
              Icon(
                broadcast == null ? Icons.campaign : Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                broadcast == null ? 'Create Broadcast' : 'Edit Broadcast',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Enter broadcast title',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Message Field
                  TextFormField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Message *',
                      hintText: 'Enter broadcast message',
                      prefixIcon: const Icon(Icons.message),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Message is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Priority Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: InputDecoration(
                      labelText: 'Priority *',
                      prefixIcon: const Icon(Icons.priority_high),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPriority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // Active Toggle
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text(
                      'Make this broadcast visible to employees',
                    ),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final provider = context.read<BroadcastProvider>();
                  bool success;

                  if (broadcast == null) {
                    success = await provider.createBroadcast(
                      title: titleController.text.trim(),
                      message: messageController.text.trim(),
                      priority: selectedPriority,
                      isActive: isActive,
                    );
                  } else {
                    success = await provider.updateBroadcast(
                      id: broadcast.id!,
                      title: titleController.text.trim(),
                      message: messageController.text.trim(),
                      priority: selectedPriority,
                      isActive: isActive,
                    );
                  }

                  if (context.mounted) {
                    if (success) {
                      Navigator.pop(context);
                      Toast.success(
                        context,
                        broadcast == null
                            ? 'Broadcast created and notifications sent to all employees!'
                            : 'Broadcast updated successfully!',
                      );
                    } else {
                      Toast.error(
                        context,
                        provider.error ?? 'Operation failed',
                      );
                    }
                  }
                }
              },
              child: Text(broadcast == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BroadcastMessage broadcast) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Broadcast'),
          ],
        ),
        content: Text('Are you sure you want to delete "${broadcast.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<BroadcastProvider>();
              final success = await provider.deleteBroadcast(broadcast.id!);

              if (context.mounted) {
                if (success) {
                  Toast.success(context, 'Broadcast deleted successfully!');
                } else {
                  Toast.error(
                    context,
                    provider.error ?? 'Failed to delete broadcast',
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'NORMAL':
        return Colors.blue;
      case 'LOW':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'URGENT':
        return Icons.error;
      case 'HIGH':
        return Icons.warning;
      case 'NORMAL':
        return Icons.info;
      case 'LOW':
        return Icons.low_priority;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);
    final isDesktop = _isDesktop(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdminLayout(
      currentRoute: AppRoutes.adminBroadcasts,
      title: const Text('Broadcast Messages'),
      actions: isMobile
          ? null
          : [
              FilledButton.icon(
                onPressed: () => _showAddBroadcastDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Broadcast'),
              ),
            ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          // For desktop, use a centered constrained width layout
          if (isDesktop) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildContent(
                  context,
                  isMobile,
                  isTablet,
                  isDesktop,
                  isDark,
                ),
              ),
            );
          }

          return _buildContent(context, isMobile, isTablet, isDesktop, isDark);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    bool isDark,
  ) {
    return SizedBox.expand(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await context.read<BroadcastProvider>().refreshBroadcasts();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: _getPadding(context),
                right: _getPadding(context),
                top: _getPadding(context),
                bottom: isMobile ? 100 : _getPadding(context),
              ),
              child: Consumer<BroadcastProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.broadcasts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(_getPadding(context) * 2),
                        child: const CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (provider.error != null && provider.broadcasts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(_getPadding(context) * 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: isMobile
                                  ? 56
                                  : isTablet
                                  ? 64
                                  : 72,
                              color: Colors.red,
                            ),
                            SizedBox(height: _getSpacing(context)),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontSize: isMobile ? 16 : 18),
                            ),
                            SizedBox(height: _getSpacing(context)),
                            FilledButton(
                              onPressed: () => provider.refreshBroadcasts(),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 24,
                                  vertical: isMobile ? 12 : 16,
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (provider.broadcasts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(_getPadding(context) * 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.campaign,
                              size: isMobile
                                  ? 56
                                  : isTablet
                                  ? 64
                                  : 72,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            SizedBox(height: _getSpacing(context)),
                            Text(
                              'No broadcast messages yet',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: isMobile
                                        ? 20
                                        : isTablet
                                        ? 22
                                        : 24,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: _getSpacing(context) / 2),
                            Text(
                              'Create your first broadcast message to notify all employees',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            SizedBox(height: _getSpacing(context) * 1.5),
                            FilledButton.icon(
                              onPressed: () => _showAddBroadcastDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Broadcast'),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 24,
                                  vertical: isMobile ? 12 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      if (!isMobile)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: _getSpacing(context),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Broadcasts (${provider.totalElements})',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if (isMobile)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: _getSpacing(context),
                          ),
                          child: FilledButton.icon(
                            onPressed: () => _showAddBroadcastDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Broadcast'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      SizedBox(height: _getSpacing(context)),
                      // Broadcast List
                      ...provider.broadcasts.map((broadcast) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        final borderColor = isDark
                            ? Colors.white
                            : Colors.black;

                        return Card(
                          margin: EdgeInsets.only(bottom: _getSpacing(context)),
                          elevation: isDark ? 0 : 2,
                          color: isDark
                              ? Theme.of(context).colorScheme.surface
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _isMobile(context) ? 12 : 16,
                            ),
                            side: BorderSide(
                              color: borderColor,
                              width: isDark ? 1.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            onTap: () =>
                                _showAddBroadcastDialog(broadcast: broadcast),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.all(_getCardPadding(context)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(
                                            broadcast.priority,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _getPriorityColor(
                                              broadcast.priority,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getPriorityIcon(
                                                broadcast.priority,
                                              ),
                                              size: 16,
                                              color: _getPriorityColor(
                                                broadcast.priority,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              broadcast.priorityDisplay,
                                              style: TextStyle(
                                                color: _getPriorityColor(
                                                  broadcast.priority,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      if (broadcast.isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            'Active',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            'Inactive',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    broadcast.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    broadcast.message,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'By ${broadcast.createdBy?.name ?? 'Unknown'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        broadcast.createdAt != null
                                            ? DateFormat(
                                                'MMM dd, yyyy • hh:mm a',
                                              ).format(broadcast.createdAt!)
                                            : 'Unknown date',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red,
                                        onPressed: () =>
                                            _showDeleteConfirmation(broadcast),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      // Loading indicator for pagination
                      if (provider.isLoading && provider.broadcasts.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(_getSpacing(context)),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      // End of list message
                      if (!provider.hasMore && provider.broadcasts.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(_getSpacing(context)),
                          child: Center(
                            child: Text(
                              'No more broadcasts',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Floating Action Button for mobile
          if (isMobile)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddBroadcastDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
            ),
        ],
      ),
    );
  }
}

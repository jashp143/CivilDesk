import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../models/notification.dart';
import '../../widgets/employee_layout.dart';
import '../../widgets/toast.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().initialize();
    });

    _scrollController.addListener(_onScroll);
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
    
    // Load more when user scrolls to 80% of the list
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.8) {
      final provider = context.read<NotificationProvider>();
      if (provider.hasMore && !provider.isLoading && !provider.isLoadingMore) {
        provider.loadMore();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<NotificationProvider>().refresh();
  }

  Future<void> _handleMarkAllAsRead() async {
    try {
      await context.read<NotificationProvider>().markAllAsRead();
      if (mounted) {
        Toast.show(context, message: 'All notifications marked as read', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, message: 'Failed to mark all as read', type: ToastType.error);
      }
    }
  }

  Future<void> _handleDelete(int notificationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<NotificationProvider>().deleteNotification(notificationId);
      if (mounted) {
        if (success) {
          Toast.show(context, message: 'Notification deleted', type: ToastType.success);
        } else {
          Toast.show(context, message: 'Failed to delete notification', type: ToastType.error);
        }
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.id!);
    }

    // Navigate based on notification type
    final type = notification.type;
    final data = notification.data;

    // Navigate based on notification type
    if (type == 'TASK_ASSIGNED' || type == 'TASK_STATUS_CHANGED') {
      Navigator.pushNamed(context, AppRoutes.tasks);
    } else if (type.contains('LEAVE')) {
      Navigator.pushNamed(context, AppRoutes.leaves);
    } else if (type.contains('EXPENSE')) {
      Navigator.pushNamed(context, AppRoutes.expenses);
    } else if (type.contains('OVERTIME')) {
      Navigator.pushNamed(context, AppRoutes.overtime);
    } else if (type == 'FINALIZED_SALARY_SLIPS') {
      Navigator.pushNamed(context, AppRoutes.mySalarySlips);
    } else if (type == 'BROADCAST_MESSAGE') {
      Navigator.pushNamed(context, AppRoutes.broadcasts);
    }
  }

  IconData _getNotificationIcon(String type) {
    if (type.contains('TASK')) return Icons.assignment;
    if (type.contains('LEAVE')) return Icons.event_note;
    if (type.contains('EXPENSE')) return Icons.receipt;
    if (type.contains('OVERTIME')) return Icons.access_time;
    if (type.contains('SALARY')) return Icons.account_balance_wallet;
    if (type == 'BROADCAST_MESSAGE') return Icons.campaign;
    return Icons.notifications;
  }

  Color _getNotificationColor(NotificationModel notification, ColorScheme colorScheme) {
    if (notification.isPositive) {
      return Colors.green;
    } else if (notification.isNegative) {
      return Colors.red;
    }
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EmployeeLayout(
      currentRoute: AppRoutes.notifications,
      title: const Text('Notifications'),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            if (provider.unreadCount > 0) {
              return TextButton.icon(
                onPressed: _handleMarkAllAsRead,
                icon: const Icon(Icons.done_all),
                label: const Text('Mark All Read'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      child: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollEndNotification) {
                  final metrics = notification.metrics;
                  if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
                    if (provider.hasMore && !provider.isLoading && !provider.isLoadingMore) {
                      provider.loadMore();
                    }
                  }
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: provider.notifications.length + (provider.hasMore && !provider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= provider.notifications.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                final notification = provider.notifications[index];
                return Dismissible(
                  key: Key('notification_${notification.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: colorScheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _handleDelete(notification.id!),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    elevation: notification.isRead ? 0 : 2,
                    color: notification.isRead
                        ? null
                        : colorScheme.surfaceContainerHighest,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getNotificationColor(notification, colorScheme)
                            .withOpacity(0.1),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: _getNotificationColor(notification, colorScheme),
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notification.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a')
                                .format(notification.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      trailing: notification.isRead
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () => _handleNotificationTap(notification),
                    ),
                  ),
                );
              },
              ),
            ),
          );
        },
      ),
    );
  }
}


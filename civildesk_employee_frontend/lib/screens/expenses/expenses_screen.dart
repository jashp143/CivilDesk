import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/employee_layout.dart';
import '../../core/providers/expense_provider.dart';
import '../../models/expense.dart';
import 'apply_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? _selectedStatusFilter; // null means 'All'
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = null; // Show all by default
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).refreshExpenses();
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
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMoreExpenses();
      }
    }
  }

  Future<void> _refreshExpenses() async {
    await Provider.of<ExpenseProvider>(context, listen: false).refreshExpenses();
  }

  void _navigateToApplyExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplyExpenseScreen(),
      ),
    );
    if (result == true) {
      _refreshExpenses();
    }
  }

  void _editExpense(Expense expense) async {
    if (expense.status != ExpenseStatus.PENDING) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pending expenses can be edited'),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyExpenseScreen(existingExpense: expense),
      ),
    );
    if (result == true) {
      _refreshExpenses();
    }
  }

  void _deleteExpense(Expense expense) {
    if (expense.status != ExpenseStatus.PENDING) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pending expenses can be deleted'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<ExpenseProvider>(context, listen: false);
              final success = await provider.deleteExpense(expense.id);
              if (!mounted) return;
              
              final messenger = ScaffoldMessenger.of(context);
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Expense deleted successfully')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Failed to delete expense'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _viewExpenseDetails(Expense expense) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(expense.status, colorScheme);
    final statusIcon = _getStatusIcon(expense.status);
    final categoryIcon = _getCategoryIcon(expense.category);
    final categoryColor = _getCategoryColor(expense.category, colorScheme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              
              // Header Bar with Category
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        categoryIcon,
                        size: 22,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            expense.categoryDisplay.toUpperCase(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
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
                            expense.statusDisplay.toUpperCase(),
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
                    const SizedBox(width: 8),
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurface,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.currency_rupee_rounded,
                        'Amount',
                        [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.currency_rupee_rounded,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Amount',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${expense.amount.toStringAsFixed(2)}',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 16),
                      
                      // Date Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.calendar_today_rounded,
                        'Date',
                        [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Color(0xFF4CAF50),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Expense Date',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(expense.expenseDate),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 16),
                      
                      // Description Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.description_rounded,
                        'Description',
                        [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.format_quote_rounded,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    expense.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Receipts (if exists)
                      if (expense.receiptUrls != null && expense.receiptUrls!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          theme,
                          colorScheme,
                          Icons.receipt_long_rounded,
                          'Receipts',
                          expense.receiptUrls!.map((url) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.description,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    url.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Icon(
                                    Icons.open_in_new,
                                    color: colorScheme.primary,
                                  ),
                                  onTap: () {
                                    // TODO: Open receipt URL
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Timeline Section
                      _buildDetailSection(
                        theme,
                        colorScheme,
                        Icons.access_time_rounded,
                        'Timeline',
                        [
                          // Submitted
                          _buildTimelineItem(
                            theme,
                            colorScheme,
                            Icons.send_rounded,
                            'Submitted',
                            '${DateFormat('MMM dd, yyyy').format(expense.createdAt)} • ${DateFormat('hh:mm a').format(expense.createdAt)}',
                            colorScheme.primaryContainer,
                            true,
                          ),
                          // Reviewed (if exists)
                          if (expense.reviewedAt != null) ...[
                            const SizedBox(height: 8),
                            _buildTimelineItem(
                              theme,
                              colorScheme,
                              expense.status == ExpenseStatus.APPROVED
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              expense.status == ExpenseStatus.APPROVED
                                  ? 'Approved'
                                  : 'Rejected',
                              '${DateFormat('MMM dd, yyyy').format(expense.reviewedAt!)} • ${DateFormat('hh:mm a').format(expense.reviewedAt!)}',
                              expense.status == ExpenseStatus.APPROVED
                                  ? _getStatusColor(ExpenseStatus.APPROVED, colorScheme).withValues(alpha: 0.2)
                                  : _getStatusColor(ExpenseStatus.REJECTED, colorScheme).withValues(alpha: 0.2),
                              false,
                            ),
                          ],
                        ],
                      ),

                      // Review Information (if exists)
                      if (expense.reviewedBy != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          theme,
                          colorScheme,
                          Icons.verified_user_rounded,
                          'Review Information',
                          [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(theme, colorScheme, 'Reviewed By', expense.reviewedBy!.name),
                                  _buildDetailRow(theme, colorScheme, 'Role', expense.reviewedBy!.role),
                                  _buildDetailRow(theme, colorScheme, 'Email', expense.reviewedBy!.email),
                                  if (expense.reviewedAt != null)
                                    _buildDetailRow(
                                      theme,
                                      colorScheme,
                                      'Reviewed At',
                                      DateFormat('MMM dd, yyyy, hh:mm a').format(expense.reviewedAt!),
                                    ),
                                  if (expense.reviewNote != null && expense.reviewNote!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
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
                                            child: Text(
                                              expense.reviewNote!,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: colorScheme.onSurface,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildTimelineItem(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String subtitle,
    Color iconBackgroundColor,
    bool showLine,
  ) {
    Color iconColor;
    if (iconBackgroundColor == colorScheme.primaryContainer) {
      iconColor = colorScheme.primary;
    } else if (iconBackgroundColor == _getStatusColor(ExpenseStatus.APPROVED, colorScheme).withValues(alpha: 0.2)) {
      iconColor = _getStatusColor(ExpenseStatus.APPROVED, colorScheme);
    } else {
      iconColor = _getStatusColor(ExpenseStatus.REJECTED, colorScheme);
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              if (showLine) ...[
                const SizedBox(height: 4),
                Container(
                  width: 2,
                  height: 20,
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ],
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, ColorScheme colorScheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.APPROVED:
        return Icons.check_circle;
      case ExpenseStatus.PENDING:
        return Icons.pending;
      case ExpenseStatus.REJECTED:
        return Icons.cancel;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.TRAVEL:
        return Icons.flight_rounded;
      case ExpenseCategory.MEALS:
        return Icons.restaurant_rounded;
      case ExpenseCategory.ACCOMMODATION:
        return Icons.hotel_rounded;
      case ExpenseCategory.SUPPLIES:
        return Icons.inventory_2_rounded;
      case ExpenseCategory.EQUIPMENT:
        return Icons.build_rounded;
      case ExpenseCategory.COMMUNICATION:
        return Icons.phone_rounded;
      case ExpenseCategory.TRANSPORTATION:
        return Icons.directions_car_rounded;
      case ExpenseCategory.ENTERTAINMENT:
        return Icons.movie_rounded;
      case ExpenseCategory.TRAINING:
        return Icons.school_rounded;
      case ExpenseCategory.OTHER:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(ExpenseCategory category, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    switch (category) {
      case ExpenseCategory.TRAVEL:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
      case ExpenseCategory.MEALS:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      case ExpenseCategory.ACCOMMODATION:
        return isDark ? const Color(0xFFBA68C8) : const Color(0xFF9C27B0);
      case ExpenseCategory.SUPPLIES:
        return isDark ? const Color(0xFF81C784) : const Color(0xFF388E3C);
      case ExpenseCategory.EQUIPMENT:
        return isDark ? const Color(0xFF90A4AE) : const Color(0xFF546E7A);
      case ExpenseCategory.COMMUNICATION:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case ExpenseCategory.TRANSPORTATION:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
      case ExpenseCategory.ENTERTAINMENT:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F);
      case ExpenseCategory.TRAINING:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case ExpenseCategory.OTHER:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return EmployeeLayout(
      currentRoute: AppRoutes.expenses,
      title: const Text('My Expenses'),
      actions: [
        IconButton(
          onPressed: _navigateToApplyExpense,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Apply Expense',
        ),
      ],
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
                    _selectedStatusFilter == 'PENDING',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'PENDING';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'Approved',
                    _selectedStatusFilter == 'APPROVED',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'APPROVED';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    theme,
                    colorScheme,
                    'Rejected',
                    _selectedStatusFilter == 'REJECTED',
                    () {
                      setState(() {
                        _selectedStatusFilter = 'REJECTED';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Expenses List
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                // Filter expenses based on selected status
                final filteredExpenses = _selectedStatusFilter == null
                    ? provider.expenses
                    : provider.expenses.where((expense) {
                        return expense.status.toString().split('.').last == _selectedStatusFilter;
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
                          onPressed: _refreshExpenses,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.expenses.isEmpty) {
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
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Expense Applications',
                              style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'You haven\'t applied for any expenses yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _navigateToApplyExpense,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Apply for Expense'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshExpenses,
                  color: Theme.of(context).colorScheme.primary,
                  child: filteredExpenses.isEmpty && provider.expenses.isNotEmpty
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
                                'No ${_selectedStatusFilter?.toLowerCase() ?? ''} expenses found',
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
                          itemCount: filteredExpenses.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredExpenses.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final expense = filteredExpenses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 0),
                              child: _buildExpenseCard(expense),
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

  Widget _buildExpenseCard(Expense expense) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(expense.status, colorScheme);
    final statusIcon = _getStatusIcon(expense.status);
    final statusLabel = expense.statusDisplay.toUpperCase();
    final categoryIcon = _getCategoryIcon(expense.category);
    final categoryColor = _getCategoryColor(expense.category, colorScheme);

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
        onTap: () => _viewExpenseDetails(expense),
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category Icon + Title + Amount + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Icon + Category
                  Expanded(
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            categoryIcon,
                            size: 22,
                            color: categoryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Category + Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.categoryDisplay.toUpperCase(),
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
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(expense.expenseDate),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 13,
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
              
              // Amount Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.currency_rupee_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (expense.receiptUrls != null && expense.receiptUrls!.isNotEmpty) ...[
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${expense.receiptUrls!.length} receipt(s)',
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
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
                      expense.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ],
              ),
              
              // Admin Comment (if exists)
              if (expense.reviewNote != null && expense.reviewNote!.isNotEmpty) ...[
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
                              'Admin Comment',
                              style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expense.reviewNote!,
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
                    'Submitted: ${DateFormat('MMM dd, yyyy').format(expense.createdAt)} • ${DateFormat('hh:mm a').format(expense.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
              
              // Actions (only for pending)
              if (expense.status == ExpenseStatus.PENDING) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editExpense(expense),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteExpense(expense),
                        icon: const Icon(Icons.delete_rounded, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getErrorColor(colorScheme),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ExpenseStatus status, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    switch (status) {
      case ExpenseStatus.APPROVED:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case ExpenseStatus.PENDING:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      case ExpenseStatus.REJECTED:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
    }
  }

  Color _getErrorColor(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? const Color(0xFFEF5350) // More vibrant red for dark mode
        : const Color(0xFFC62828);
  }
}

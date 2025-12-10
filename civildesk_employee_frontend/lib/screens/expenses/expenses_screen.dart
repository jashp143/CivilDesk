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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).fetchMyExpenses();
    });
  }

  Future<void> _refreshExpenses() async {
    await Provider.of<ExpenseProvider>(context, listen: false).fetchMyExpenses();
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
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error ?? 'Failed to delete expense'),
                    ),
                  );
                }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${expense.categoryDisplay} Expense Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Employee', expense.employeeName),
              _buildDetailRow('Employee ID', expense.employeeIdStr),
              _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(expense.expenseDate)),
              _buildDetailRow('Category', expense.categoryDisplay),
              _buildDetailRow('Amount', '₹${expense.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Description', expense.description),
              if (expense.receiptUrls != null && expense.receiptUrls!.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Receipts:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...expense.receiptUrls!.map((url) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        url,
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    )),
              ],
              const Divider(),
              _buildDetailRow('Status', expense.statusDisplay),
              if (expense.reviewedBy != null) ...[
                const Divider(),
                _buildDetailRow('Reviewed By', expense.reviewedBy!.name),
                _buildDetailRow('Role', expense.reviewedBy!.role),
                if (expense.reviewedAt != null)
                  _buildDetailRow(
                    'Reviewed At',
                    DateFormat('dd MMM yyyy, hh:mm a').format(expense.reviewedAt!),
                  ),
                if (expense.reviewNote != null && expense.reviewNote!.isNotEmpty)
                  _buildDetailRow('Note', expense.reviewNote!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.PENDING:
        return Colors.orange;
      case ExpenseStatus.APPROVED:
        return Colors.green;
      case ExpenseStatus.REJECTED:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      currentRoute: AppRoutes.expenses,
      title: const Text('Expenses'),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToApplyExpense,
        child: const Icon(Icons.add),
      ),
      child: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.expenses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to apply for an expense',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshExpenses,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.expenses.length,
              itemBuilder: (context, index) {
                final expense = provider.expenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _viewExpenseDetails(expense),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense.categoryDisplay,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(expense.expenseDate),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(expense.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getStatusColor(expense.status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  expense.statusDisplay,
                                  style: TextStyle(
                                    color: _getStatusColor(expense.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${expense.amount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                              if (expense.receiptUrls != null && expense.receiptUrls!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.receipt, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${expense.receiptUrls!.length} receipt(s)',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            expense.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (expense.status == ExpenseStatus.PENDING) ...[
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editExpense(expense),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _deleteExpense(expense),
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

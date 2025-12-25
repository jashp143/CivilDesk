import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../models/expense.dart';
import '../../core/providers/expense_provider.dart';
import '../../widgets/toast.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  void _showReviewDialog(ExpenseStatus status) {
    _noteController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == ExpenseStatus.APPROVED ? 'Approve Expense' : 'Reject Expense',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${status == ExpenseStatus.APPROVED ? 'approve' : 'reject'} this expense application?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add a note for the employee',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewExpense(status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == ExpenseStatus.APPROVED 
                  ? Colors.green 
                  : Colors.red,
            ),
            child: Text(
              status == ExpenseStatus.APPROVED ? 'APPROVE' : 'REJECT',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewExpense(ExpenseStatus status) async {
    setState(() => _isSubmitting = true);

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    
    final success = await provider.reviewExpense(widget.expense.id, status, note);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Toast.success(
          context,
          'Expense ${status == ExpenseStatus.APPROVED ? 'approved' : 'rejected'} successfully',
        );
        Navigator.pop(context, true); // Return true to refresh parent screen
      } else {
        Toast.error(context, provider.error ?? 'Failed to review expense');
      }
    }
  }

  Future<void> _openReceipt(String receiptUrl) async {
    try {
      // Construct full URL
      String urlString = receiptUrl;
      
      // If URL doesn't start with http, construct full URL
      if (!urlString.startsWith('http')) {
        // Get base URL without /api
        String serverUrl;
        if (Platform.isAndroid) {
          serverUrl = 'http://10.0.2.2:8080';
        } else if (Platform.isIOS) {
          serverUrl = 'http://localhost:8080';
        } else {
          serverUrl = 'http://localhost:8080';
        }
        
        if (urlString.startsWith('/')) {
          urlString = serverUrl + urlString;
        } else {
          urlString = '$serverUrl/$urlString';
        }
      }
      
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          Toast.error(context, 'Could not open receipt');
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, 'Error opening receipt: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (widget.expense.status) {
      case ExpenseStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case ExpenseStatus.APPROVED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ExpenseStatus.REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          widget.expense.statusDisplay,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Employee Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employee Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Name', widget.expense.employeeName),
                        _buildInfoRow('Employee ID', widget.expense.employeeIdStr),
                        _buildInfoRow('Email', widget.expense.employeeEmail),
                        if (widget.expense.department != null)
                          _buildInfoRow('Department', widget.expense.department!),
                        if (widget.expense.designation != null)
                          _buildInfoRow('Designation', widget.expense.designation!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Expense Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Date', DateFormat('dd MMM yyyy').format(widget.expense.expenseDate)),
                        _buildInfoRow('Category', widget.expense.categoryDisplay),
                        _buildInfoRow('Amount', '₹${widget.expense.amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 12),
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.expense.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                // Receipts Section
                if (widget.expense.receiptUrls != null && widget.expense.receiptUrls!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receipts (${widget.expense.receiptUrls!.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...widget.expense.receiptUrls!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final receiptUrl = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.receipt, color: Colors.blue),
                                title: Text('Receipt ${index + 1}'),
                                subtitle: Text(
                                  receiptUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.open_in_new),
                                onTap: () => _openReceipt(receiptUrl),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
                // Review Information
                if (widget.expense.reviewedBy != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Reviewed By', widget.expense.reviewedBy!.name),
                          _buildInfoRow('Role', widget.expense.reviewedBy!.role),
                          _buildInfoRow('Email', widget.expense.reviewedBy!.email),
                          if (widget.expense.reviewedAt != null)
                            _buildInfoRow(
                              'Reviewed At',
                              DateFormat('dd MMM yyyy, hh:mm a').format(widget.expense.reviewedAt!),
                            ),
                          if (widget.expense.reviewNote != null && widget.expense.reviewNote!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Note',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.expense.reviewNote!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),
          // Action Buttons (only for pending expenses)
          if (widget.expense.status == ExpenseStatus.PENDING)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _showReviewDialog(ExpenseStatus.REJECTED),
                        icon: const Icon(Icons.close),
                        label: const Text('REJECT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _showReviewDialog(ExpenseStatus.APPROVED),
                        icon: const Icon(Icons.check),
                        label: const Text('APPROVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

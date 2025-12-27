import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../models/expense.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/utils/message_builder.dart';
import '../../widgets/toast.dart';
import '../../widgets/detail_screen_components.dart';

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
        
        // Show WhatsApp option dialog
        _showWhatsAppOption(status, note);
        
        Navigator.pop(context, true); // Return true to refresh parent screen
      } else {
        Toast.error(context, provider.error ?? 'Failed to review expense');
      }
    }
  }

  Future<void> _showWhatsAppOption(ExpenseStatus status, String? note) async {
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.message, color: const Color(0xFF25D366)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Send WhatsApp Notification',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Would you like to send a WhatsApp notification to the employee?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('SKIP'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.message, color: Colors.white, size: 18),
            label: const Text('SEND'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );

    if (shouldSend == true && mounted) {
      await _sendExpenseWhatsApp(status, note);
    }
  }

  Future<void> _sendExpenseWhatsApp(ExpenseStatus status, String? note) async {
    try {
      // Fetch employee to get phone number
      final employeeService = EmployeeService();
      final employee = await employeeService.getEmployeeById(widget.expense.employeeId);
      
      if (employee.phoneNumber.isEmpty) {
        if (mounted) {
          Toast.warning(context, 'Employee phone number not available');
        }
        return;
      }

      // Build message
      final message = MessageBuilder.buildExpenseMessage(
        expense: widget.expense,
        status: status,
        adminNote: note,
      );

      // Launch WhatsApp
      final launched = await WhatsAppService.launchWhatsApp(
        phoneNumber: employee.phoneNumber,
        message: message,
      );

      if (!launched && mounted) {
        Toast.warning(context, 'Could not launch WhatsApp. Please check if WhatsApp is installed.');
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, 'Failed to send WhatsApp message: $e');
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
        title: Text(
          'Expense Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: DetailScreenComponents.buildStatusBadge(
                context: context,
                status: widget.expense.statusDisplay,
                color: statusColor,
                icon: statusIcon,
                isCompact: true,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: DetailScreenComponents.buildResponsiveContainer(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Employee Information
                  DetailScreenComponents.buildSectionCard(
                    context: context,
                    title: 'Employee Information',
                    icon: Icons.person,
                    accentColor: Colors.blue,
                    children: [
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Name',
                        value: widget.expense.employeeName,
                        icon: Icons.person,
                        isHighlighted: true,
                      ),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Employee ID',
                        value: widget.expense.employeeIdStr,
                        icon: Icons.badge,
                      ),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Email',
                        value: widget.expense.employeeEmail,
                        icon: Icons.email,
                      ),
                      if (widget.expense.department != null)
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Department',
                          value: widget.expense.department!,
                          icon: Icons.business,
                        ),
                      if (widget.expense.designation != null)
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Designation',
                          value: widget.expense.designation!,
                          icon: Icons.work,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Expense Information
                  DetailScreenComponents.buildSectionCard(
                    context: context,
                    title: 'Expense Information',
                    icon: Icons.receipt_long,
                    accentColor: Colors.purple,
                    children: [
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Date',
                        value: DateFormat('dd MMM yyyy').format(widget.expense.expenseDate),
                        icon: Icons.calendar_today,
                      ),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Category',
                        value: widget.expense.categoryDisplay,
                        icon: Icons.category,
                      ),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Amount',
                        value: '₹${widget.expense.amount.toStringAsFixed(2)}',
                        icon: Icons.currency_rupee,
                        isHighlighted: true,
                      ),
                      const SizedBox(height: 8),
                      DetailScreenComponents.buildTextContent(
                        context: context,
                        text: widget.expense.description,
                        icon: Icons.description,
                        accentColor: Colors.purple,
                      ),
                    ],
                  ),
                  // Receipts Section
                  if (widget.expense.receiptUrls != null && widget.expense.receiptUrls!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    DetailScreenComponents.buildSectionCard(
                      context: context,
                      title: 'Receipts (${widget.expense.receiptUrls!.length})',
                      icon: Icons.receipt,
                      accentColor: Colors.blue,
                      children: widget.expense.receiptUrls!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final receiptUrl = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.receipt,
                              color: Colors.blue.shade700,
                            ),
                            title: Text(
                              'Receipt ${index + 1}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              receiptUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Icon(
                              Icons.open_in_new,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () => _openReceipt(receiptUrl),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  // Review Information
                  if (widget.expense.reviewedBy != null) ...[
                    const SizedBox(height: 16),
                    DetailScreenComponents.buildSectionCard(
                      context: context,
                      title: 'Review Information',
                      icon: Icons.rate_review,
                      accentColor: widget.expense.status == ExpenseStatus.APPROVED
                          ? Colors.green
                          : Colors.red,
                      children: [
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Reviewed By',
                          value: widget.expense.reviewedBy!.name,
                          icon: Icons.person,
                          isHighlighted: true,
                        ),
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Role',
                          value: widget.expense.reviewedBy!.role,
                          icon: Icons.badge,
                        ),
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Email',
                          value: widget.expense.reviewedBy!.email,
                          icon: Icons.email,
                        ),
                        if (widget.expense.reviewedAt != null)
                          DetailScreenComponents.buildDetailRow(
                            context: context,
                            label: 'Reviewed At',
                            value: DateFormat('dd MMM yyyy, hh:mm a').format(widget.expense.reviewedAt!),
                            icon: Icons.access_time,
                          ),
                        if (widget.expense.reviewNote != null && widget.expense.reviewNote!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          DetailScreenComponents.buildTextContent(
                            context: context,
                            text: widget.expense.reviewNote!,
                            icon: Icons.note,
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (widget.expense.status == ExpenseStatus.PENDING)
                    const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Action Buttons
          if (widget.expense.status == ExpenseStatus.PENDING)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DetailScreenComponents.buildActionButtons(
                context: context,
                buttons: [
                  ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _showReviewDialog(ExpenseStatus.REJECTED),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('REJECT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _showReviewDialog(ExpenseStatus.APPROVED),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isSubmitting)
            Container(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
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

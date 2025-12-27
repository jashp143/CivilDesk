import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/overtime.dart';
import '../../core/providers/overtime_provider.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/utils/message_builder.dart';
import '../../widgets/toast.dart';
import '../../widgets/detail_screen_components.dart';

class OvertimeDetailScreen extends StatefulWidget {
  final Overtime overtime;

  const OvertimeDetailScreen({super.key, required this.overtime});

  @override
  State<OvertimeDetailScreen> createState() => _OvertimeDetailScreenState();
}

class _OvertimeDetailScreenState extends State<OvertimeDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showReviewDialog(OvertimeStatus status) {
    _noteController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == OvertimeStatus.APPROVED ? 'Approve Overtime' : 'Reject Overtime',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${status == OvertimeStatus.APPROVED ? 'approve' : 'reject'} this overtime application?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add a note for the employee',
                border: OutlineInputBorder(),
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
              _reviewOvertime(status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == OvertimeStatus.APPROVED 
                  ? Colors.green 
                  : Colors.red,
            ),
            child: Text(
              status == OvertimeStatus.APPROVED ? 'APPROVE' : 'REJECT',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewOvertime(OvertimeStatus status) async {
    setState(() => _isSubmitting = true);

    final provider = Provider.of<OvertimeProvider>(context, listen: false);
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    
    final success = await provider.reviewOvertime(widget.overtime.id, status, note);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Toast.success(
          context,
          'Overtime ${status == OvertimeStatus.APPROVED ? 'approved' : 'rejected'} successfully',
        );
        
        // Show WhatsApp option dialog
        _showWhatsAppOption(status, note);
        
        Navigator.pop(context, true); // Return true to refresh parent screen
      } else {
        Toast.error(context, provider.error ?? 'Failed to review overtime');
      }
    }
  }

  Future<void> _showWhatsAppOption(OvertimeStatus status, String? note) async {
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
      await _sendOvertimeWhatsApp(status, note);
    }
  }

  Future<void> _sendOvertimeWhatsApp(OvertimeStatus status, String? note) async {
    try {
      // Fetch employee to get phone number
      final employeeService = EmployeeService();
      final employee = await employeeService.getEmployeeById(widget.overtime.employeeId);
      
      if (employee.phoneNumber.isEmpty) {
        if (mounted) {
          Toast.warning(context, 'Employee phone number not available');
        }
        return;
      }

      // Build message
      final message = MessageBuilder.buildOvertimeMessage(
        overtime: widget.overtime,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overtime = widget.overtime;
    Color statusColor;
    IconData statusIcon;

    switch (overtime.status) {
      case OvertimeStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case OvertimeStatus.APPROVED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case OvertimeStatus.REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Overtime Details',
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
                status: overtime.statusDisplay,
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
                        value: overtime.employeeName,
                        icon: Icons.person,
                        isHighlighted: true,
                      ),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Employee ID',
                        value: overtime.employeeIdStr,
                        icon: Icons.badge,
                      ),
                      if (overtime.designation != null)
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Designation',
                          value: overtime.designation!,
                          icon: Icons.work,
                        ),
                      if (overtime.department != null)
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Department',
                          value: overtime.department!,
                          icon: Icons.business,
                        ),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Email',
                        value: overtime.employeeEmail,
                        icon: Icons.email,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Overtime Details
                  DetailScreenComponents.buildSectionCard(
                    context: context,
                    title: 'Overtime Details',
                    icon: Icons.access_time,
                    accentColor: Colors.purple,
                    children: [
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Date',
                        value: DateFormat('dd MMMM yyyy (EEEE)').format(overtime.date),
                        icon: Icons.calendar_today,
                        isHighlighted: true,
                      ),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Start Time',
                        value: overtime.startTime,
                        icon: Icons.play_arrow,
                      ),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'End Time',
                        value: overtime.endTime,
                        icon: Icons.stop,
                      ),
                      const SizedBox(height: 8),
                      DetailScreenComponents.buildTextContent(
                        context: context,
                        text: overtime.reason,
                        icon: Icons.description,
                        accentColor: Colors.purple,
                      ),
                    ],
                  ),
                  // Review Information
                  if (overtime.reviewedBy != null) ...[
                    const SizedBox(height: 16),
                    DetailScreenComponents.buildSectionCard(
                      context: context,
                      title: 'Review Information',
                      icon: Icons.rate_review,
                      accentColor: overtime.status == OvertimeStatus.APPROVED
                          ? Colors.green
                          : Colors.red,
                      children: [
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Reviewed By',
                          value: overtime.reviewedBy!.name,
                          icon: Icons.person,
                          isHighlighted: true,
                        ),
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Role',
                          value: overtime.reviewedBy!.role,
                          icon: Icons.badge,
                        ),
                        if (overtime.reviewedAt != null)
                          DetailScreenComponents.buildDetailRow(
                            context: context,
                            label: 'Reviewed At',
                            value: DateFormat('dd MMM yyyy, hh:mm a').format(overtime.reviewedAt!),
                            icon: Icons.access_time,
                          ),
                        if (overtime.reviewNote != null && overtime.reviewNote!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          DetailScreenComponents.buildTextContent(
                            context: context,
                            text: overtime.reviewNote!,
                            icon: Icons.note,
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (overtime.status == OvertimeStatus.PENDING)
                    const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Action Buttons
          if (overtime.status == OvertimeStatus.PENDING)
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
                        : () => _showReviewDialog(OvertimeStatus.REJECTED),
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
                        : () => _showReviewDialog(OvertimeStatus.APPROVED),
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
}

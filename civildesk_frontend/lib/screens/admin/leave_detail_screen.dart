import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../models/leave.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/utils/message_builder.dart';
import '../../widgets/toast.dart';
import '../../widgets/detail_screen_components.dart';

class LeaveDetailScreen extends StatefulWidget {
  final Leave leave;

  const LeaveDetailScreen({super.key, required this.leave});

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  void _showReviewDialog(LeaveStatus status) {
    _noteController.clear();
    
    final isApprove = status == LeaveStatus.APPROVED;
    final color = isApprove ? Colors.green : Colors.red;
    final icon = isApprove ? Icons.check_circle : Icons.cancel;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isApprove ? 'Approve Leave' : 'Reject Leave',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Confirmation message
              Text(
                'Are you sure you want to ${isApprove ? 'approve' : 'reject'} this leave application?',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              
              // Note field
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add a note for the employee',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reviewLeave(status);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isApprove ? 'APPROVE' : 'REJECT',
                          style: const TextStyle(
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
      ),
    );
  }

  Future<void> _reviewLeave(LeaveStatus status) async {
    setState(() => _isSubmitting = true);

    final provider = Provider.of<LeaveProvider>(context, listen: false);
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    
    final success = await provider.reviewLeave(widget.leave.id, status, note);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Toast.success(
          context,
          'Leave ${status == LeaveStatus.APPROVED ? 'approved' : 'rejected'} successfully',
        );
        
        // Show WhatsApp option dialog
        _showWhatsAppOption(status, note);
        
        Navigator.pop(context, true); // Return true to refresh parent screen
      } else {
        Toast.error(context, provider.error ?? 'Failed to review leave');
      }
    }
  }

  Future<void> _showWhatsAppOption(LeaveStatus status, String? note) async {
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
      await _sendLeaveWhatsApp(status, note);
    }
  }

  Future<void> _sendLeaveWhatsApp(LeaveStatus status, String? note) async {
    try {
      // Fetch employee to get phone number
      final employeeService = EmployeeService();
      final employee = await employeeService.getEmployeeById(widget.leave.employeeId);
      
      if (employee.phoneNumber.isEmpty) {
        if (mounted) {
          Toast.warning(context, 'Employee phone number not available');
        }
        return;
      }

      // Build message
      final message = MessageBuilder.buildLeaveMessage(
        leave: widget.leave,
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

  Future<void> _openMedicalCertificate() async {
    if (widget.leave.medicalCertificateUrl != null) {
      try {
        // Construct full URL
        String urlString = widget.leave.medicalCertificateUrl!;
        
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
            Toast.error(context, 'Could not open certificate');
          }
        }
      } catch (e) {
        if (mounted) {
          Toast.error(context, 'Error opening certificate: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    Color statusColor;
    IconData statusIcon;

    switch (widget.leave.status) {
      case LeaveStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case LeaveStatus.APPROVED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case LeaveStatus.REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case LeaveStatus.CANCELLED:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leave Details',
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
                status: widget.leave.statusDisplay,
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
                // Employee Information Section
                  DetailScreenComponents.buildSectionCard(
                    context: context,
                  title: 'Employee Information',
                  icon: Icons.person,
                    accentColor: Colors.blue,
                  children: [
                    // Employee Avatar and Name
                    Row(
                      children: [
                        Container(
                            width: 56,
                            height: 56,
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2),
                                width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.leave.employeeName.isNotEmpty
                                  ? widget.leave.employeeName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.leave.employeeName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.leave.employeeIdStr,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Email',
                        value: widget.leave.employeeEmail,
                        icon: Icons.email,
                      ),
                    if (widget.leave.department != null)
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Department',
                          value: widget.leave.department!,
                          icon: Icons.business,
                        ),
                    if (widget.leave.designation != null)
                        DetailScreenComponents.buildDetailRow(
                          context: context,
                          label: 'Designation',
                          value: widget.leave.designation!,
                          icon: Icons.work,
                        ),
                  ],
                ),
                const SizedBox(height: 16),

                // Leave Details Section
                  DetailScreenComponents.buildSectionCard(
                    context: context,
                  title: 'Leave Details',
                  icon: Icons.event_note,
                    accentColor: Colors.purple,
                  children: [
                    // Leave Type Badge
                      DetailScreenComponents.buildInfoChip(
                        context: context,
                        label: 'Type',
                        value: widget.leave.leaveTypeDisplay,
                        icon: Icons.event_note,
                        color: Colors.purple,
                    ),
                    const SizedBox(height: 16),
                      // Date Range
                      DetailScreenComponents.buildDateRange(
                        context: context,
                        startDate: widget.leave.startDate,
                        endDate: widget.leave.endDate,
                      ),
                      const SizedBox(height: 16),
                      // Total Days
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 400;
                          if (isMobile) {
                            // Stack vertically on mobile
                            return Column(
                        children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: DetailScreenComponents.buildInfoChip(
                                    context: context,
                                    label: 'Total Days',
                                    value: '${widget.leave.totalDays} ${widget.leave.totalDays == 1 ? 'day' : 'days'}',
                                    icon: Icons.access_time,
                                  ),
                                ),
                                if (widget.leave.isHalfDay) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: DetailScreenComponents.buildInfoChip(
                                      context: context,
                                      label: 'Period',
                                      value: widget.leave.halfDayPeriodDisplay ?? '',
                                      icon: Icons.schedule,
                                      color: Colors.orange,
                                  ),
                                ),
                              ],
                              ],
                            );
                          } else {
                            // Show side-by-side on larger screens
                            return Row(
                      children: [
                        Expanded(
                                  child: DetailScreenComponents.buildInfoChip(
                                    context: context,
                                    label: 'Total Days',
                                    value: '${widget.leave.totalDays} ${widget.leave.totalDays == 1 ? 'day' : 'days'}',
                                    icon: Icons.access_time,
                          ),
                        ),
                        if (widget.leave.isHalfDay) ...[
                          const SizedBox(width: 12),
                          Expanded(
                                    child: DetailScreenComponents.buildInfoChip(
                                      context: context,
                                      label: 'Period',
                                      value: widget.leave.halfDayPeriodDisplay ?? '',
                                      icon: Icons.schedule,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                        ],
                            );
                          }
                        },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact Information Section
                  DetailScreenComponents.buildSectionCard(
                    context: context,
                  title: 'Contact Information',
                  icon: Icons.phone,
                    accentColor: Colors.teal,
                  children: [
                      DetailScreenComponents.buildDetailRow(
                        context: context,
                        label: 'Phone',
                        value: widget.leave.contactNumber,
                        icon: Icons.phone,
                        isHighlighted: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Handover Responsibilities Section
                if (widget.leave.handoverEmployees != null &&
                      widget.leave.handoverEmployees!.isNotEmpty) ...[
                    DetailScreenComponents.buildSectionCard(
                      context: context,
                    title: 'Handover Responsibilities',
                    icon: Icons.supervisor_account,
                      accentColor: Colors.amber,
                    children: widget.leave.handoverEmployees!.map((emp) {
                      return _buildHandoverEmployeeCard(emp);
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                  ],

                // Reason Section
                  DetailScreenComponents.buildSectionCard(
                    context: context,
                  title: 'Reason for Leave',
                  icon: Icons.description,
                    accentColor: Colors.indigo,
                  children: [
                      DetailScreenComponents.buildTextContent(
                        context: context,
                        text: widget.leave.reason,
                        icon: Icons.format_quote,
                        accentColor: Colors.indigo,
                    ),
                  ],
                ),

                // Medical Certificate Section
                if (widget.leave.leaveType == LeaveType.MEDICAL_LEAVE) ...[
                    DetailScreenComponents.buildSectionCard(
                      context: context,
                    title: 'Medical Certificate',
                    icon: Icons.file_present,
                      accentColor: Colors.red,
                    children: [
                      if (widget.leave.medicalCertificateUrl != null)
                          Column(
                            children: [
                              Icon(
                                Icons.description,
                                size: 48,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Medical Certificate Available',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openMedicalCertificate,
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('View Certificate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                        )
                      else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, 
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Text(
                                'No certificate uploaded',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                        ),
                    ],
                  ),
                    const SizedBox(height: 16),
                ],

                // Review Information Section
                if (widget.leave.reviewedBy != null) ...[
                    DetailScreenComponents.buildSectionCard(
                      context: context,
                    title: 'Review Information',
                    icon: Icons.rate_review,
                      accentColor: widget.leave.status == LeaveStatus.APPROVED
                        ? Colors.green
                        : Colors.red,
                    children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (widget.leave.status == LeaveStatus.APPROVED
                                        ? Colors.green
                                        : Colors.red)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.leave.status == LeaveStatus.APPROVED
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: widget.leave.status == LeaveStatus.APPROVED
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.leave.reviewedBy!.name,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.leave.reviewedBy!.role,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (widget.leave.reviewedAt != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('dd MMM yyyy, hh:mm a')
                                              .format(widget.leave.reviewedAt!),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                      ),
                      if (widget.leave.reviewNote != null &&
                          widget.leave.reviewNote!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                          DetailScreenComponents.buildTextContent(
                            context: context,
                            text: widget.leave.reviewNote!,
                            icon: Icons.note,
                                    ),
                        ],
                                ],
                              ),
                    const SizedBox(height: 16),
                ],
                
                // Add spacing for the bottom buttons
                if (widget.leave.status == LeaveStatus.PENDING)
                    const SizedBox(height: 100),
              ],
              ),
            ),
          ),

          // Bottom Action Buttons (only for PENDING status)
          if (widget.leave.status == LeaveStatus.PENDING)
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
                              : () => _showReviewDialog(LeaveStatus.REJECTED),
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
                              : () => _showReviewDialog(LeaveStatus.APPROVED),
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

          // Loading Overlay
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    final sectionColor = color ?? Colors.blue;
    // Create a darker version of the color for text/icons
    final darkerColor = Color.fromRGBO(
      ((sectionColor.r * 255.0) * 0.7).round().clamp(0, 255),
      ((sectionColor.g * 255.0) * 0.7).round().clamp(0, 255),
      ((sectionColor.b * 255.0) * 0.7).round().clamp(0, 255),
      1.0,
    );
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sectionColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sectionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: darkerColor),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkerColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: icon != null ? 120 : 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverEmployeeCard(HandoverEmployee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                employee.name.isNotEmpty
                    ? employee.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.badge,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      employee.employeeId,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (employee.designation != null) ...[
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        employee.designation!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        employee.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

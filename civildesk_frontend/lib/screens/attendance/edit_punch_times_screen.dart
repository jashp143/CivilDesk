import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/attendance_service.dart';
import '../../models/attendance.dart';

class EditPunchTimesDialog extends StatefulWidget {
  final Attendance attendance;

  const EditPunchTimesDialog({
    super.key,
    required this.attendance,
  });

  @override
  State<EditPunchTimesDialog> createState() => _EditPunchTimesDialogState();
}

class _EditPunchTimesDialogState extends State<EditPunchTimesDialog>
    with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = false;
  String? _error;
  String? _updatingPunchType; // Track which punch type is being updated

  // Controllers for date and time pickers
  DateTime? _checkInTime;
  DateTime? _lunchOutTime;
  DateTime? _lunchInTime;
  DateTime? _checkOutTime;

  // Calculated hours (updated after punch time changes)
  double? _workingHours;
  double? _overtimeHours;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize with existing times
    _checkInTime = widget.attendance.checkInTime;
    _lunchOutTime = widget.attendance.lunchOutTime;
    _lunchInTime = widget.attendance.lunchInTime;
    _checkOutTime = widget.attendance.checkOutTime;
    // Initialize calculated hours
    _workingHours = widget.attendance.workingHours;
    _overtimeHours = widget.attendance.overtimeHours;

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeDialog() {
    Navigator.of(context).pop();
  }

  Future<void> _selectDateTime({
    required String punchType,
    required DateTime? currentTime,
    required Function(DateTime) onTimeSelected,
  }) async {
    // First select date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentTime ?? widget.attendance.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // Then select time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime != null
          ? TimeOfDay.fromDateTime(currentTime)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // Combine date and time
    final DateTime selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    onTimeSelected(selectedDateTime);
  }

  Future<void> _updatePunchTime(String punchType, DateTime newTime) async {
    if (widget.attendance.id == null) {
      _showErrorSnackBar('Invalid attendance record');
      return;
    }

    setState(() {
      _isLoading = true;
      _updatingPunchType = punchType;
      _error = null;
    });

    try {
      final response = await _attendanceService.updatePunchTime(
        attendanceId: widget.attendance.id!,
        punchType: punchType,
        newTime: newTime,
      );

      if (mounted) {
        if (response['success'] == true) {
          // Extract updated attendance data with recalculated hours
          final updatedData = response['data'];
          if (updatedData != null) {
            try {
              final updatedAttendance =
                  Attendance.fromJson(updatedData as Map<String, dynamic>);

              // Update local state with new times and calculated hours
              setState(() {
                switch (punchType) {
                  case 'CHECK_IN':
                    _checkInTime = newTime;
                    break;
                  case 'LUNCH_OUT':
                    _lunchOutTime = newTime;
                    break;
                  case 'LUNCH_IN':
                    _lunchInTime = newTime;
                    break;
                  case 'CHECK_OUT':
                    _checkOutTime = newTime;
                    break;
                }
                // Update calculated hours from backend
                _workingHours = updatedAttendance.workingHours;
                _overtimeHours = updatedAttendance.overtimeHours;
              });

              // Trigger animation for updated hours
              _animationController.reset();
              _animationController.forward();

              _showSuccessSnackBar('${_getPunchTypeName(punchType)} updated successfully');
            } catch (e) {
              // If parsing fails, just update the time
              setState(() {
                switch (punchType) {
                  case 'CHECK_IN':
                    _checkInTime = newTime;
                    break;
                  case 'LUNCH_OUT':
                    _lunchOutTime = newTime;
                    break;
                  case 'LUNCH_IN':
                    _lunchInTime = newTime;
                    break;
                  case 'CHECK_OUT':
                    _checkOutTime = newTime;
                    break;
                }
              });
            }
          } else {
            // Fallback: just update the time
            setState(() {
              switch (punchType) {
                case 'CHECK_IN':
                  _checkInTime = newTime;
                  break;
                case 'LUNCH_OUT':
                  _lunchOutTime = newTime;
                  break;
                case 'LUNCH_IN':
                  _lunchInTime = newTime;
                  break;
                case 'CHECK_OUT':
                  _checkOutTime = newTime;
                  break;
              }
            });
          }
        } else {
          _showErrorSnackBar(
              response['message'] ?? 'Failed to update punch time');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _updatingPunchType = null;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getPunchTypeName(String punchType) {
    switch (punchType) {
      case 'CHECK_IN':
        return 'Check In';
      case 'LUNCH_OUT':
        return 'Lunch Out';
      case 'LUNCH_IN':
        return 'Lunch In';
      case 'CHECK_OUT':
        return 'Check Out';
      default:
        return punchType;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatHours(double hours) {
    final hoursInt = hours.floor();
    final minutes = ((hours - hoursInt) * 60).round();
    if (minutes == 0) {
      return '${hoursInt}h';
    }
    return '${hoursInt}h ${minutes}m';
  }

  Widget _buildPunchTimeCard({
    required String title,
    required String punchType,
    required DateTime? currentTime,
    required IconData icon,
    required Color color,
    required bool isTablet,
  }) {
    final isUpdating = _updatingPunchType == punchType;
    final isDisabled = _isLoading && !isUpdating;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUpdating
            ? BorderSide(color: color, width: 2)
            : BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isUpdating 
              ? color.withOpacity(0.05) 
              : colorScheme.surface,
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (currentTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(currentTime),
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isUpdating)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: isDisabled
                            ? null
                            : () => _selectDateTime(
                                  punchType: punchType,
                                  currentTime: currentTime,
                                  onTimeSelected: (newTime) {
                                    _updatePunchTime(punchType, newTime);
                                  },
                                ),
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 12 : 10),
                          child: Icon(
                            Icons.edit_outlined,
                            size: isTablet ? 22 : 18,
                            color: isDisabled 
                                ? colorScheme.onSurfaceVariant.withOpacity(0.5)
                                : color,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isTablet ? 18 : 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateTime(currentTime),
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 14,
                        color: currentTime != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                        fontWeight: currentTime != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600;
  }

  bool _isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);
    final isMobile = _isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing
    final dialogWidth = isTablet
        ? math.min(math.max(screenWidth * 0.65, 550.0), 750.0)
        : screenWidth * 0.95;
    final dialogHeight = isTablet
        ? math.min(math.max(screenHeight * 0.85, 650.0), 850.0)
        : screenHeight * 0.92;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.0 : 24.0,
        vertical: isMobile ? 8.0 : 32.0,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxWidth: isTablet ? 750 : double.infinity,
            maxHeight: dialogHeight,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_calendar,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Punch Times',
                            style: TextStyle(
                              fontSize: isTablet ? 24 : 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update attendance times',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 24,
                      ),
                      onPressed: _closeDialog,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee info card
                      Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.attendance.employeeName,
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${widget.attendance.employeeId}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('EEEE, MMMM dd, yyyy')
                                            .format(widget.attendance.date),
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      SizedBox(height: isTablet ? 28 : 24),
                      // Section header
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Punch Times',
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 16 : 14),
                      _buildPunchTimeCard(
                        title: 'Check In',
                        punchType: 'CHECK_IN',
                        currentTime: _checkInTime,
                        icon: Icons.login_rounded,
                        color: Colors.green,
                        isTablet: isTablet,
                      ),
                      _buildPunchTimeCard(
                        title: 'Lunch Out',
                        punchType: 'LUNCH_OUT',
                        currentTime: _lunchOutTime,
                        icon: Icons.restaurant_outlined,
                        color: Colors.orange,
                        isTablet: isTablet,
                      ),
                      _buildPunchTimeCard(
                        title: 'Lunch In',
                        punchType: 'LUNCH_IN',
                        currentTime: _lunchInTime,
                        icon: Icons.restaurant,
                        color: Colors.blue,
                        isTablet: isTablet,
                      ),
                      _buildPunchTimeCard(
                        title: 'Check Out',
                        punchType: 'CHECK_OUT',
                        currentTime: _checkOutTime,
                        icon: Icons.logout_rounded,
                        color: Colors.red,
                        isTablet: isTablet,
                      ),
                      // Calculated Hours Section
                      if (_workingHours != null || _overtimeHours != null) ...[
                        SizedBox(height: isTablet ? 32 : 28),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Calculated Hours',
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 18 : 16),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Row(
                            children: [
                              if (_workingHours != null)
                                Expanded(
                                  child: _buildHoursCard(
                                    icon: Icons.access_time_rounded,
                                    value: _formatHours(_workingHours!),
                                    label: 'Working Hours',
                                    color: Colors.blue,
                                    isTablet: isTablet,
                                  ),
                                ),
                              if (_workingHours != null &&
                                  _overtimeHours != null &&
                                  _overtimeHours! > 0)
                                SizedBox(width: isTablet ? 16 : 12),
                              if (_overtimeHours != null && _overtimeHours! > 0)
                                Expanded(
                                  child: _buildHoursCard(
                                    icon: Icons.timer_rounded,
                                    value: _formatHours(_overtimeHours!),
                                    label: 'Overtime',
                                    color: Colors.orange,
                                    isTablet: isTablet,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        SizedBox(height: isTablet ? 24 : 20),
                        Container(
                          padding: EdgeInsets.all(isTablet ? 16 : 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: Theme.of(context).colorScheme.error,
                                size: isTablet ? 24 : 20,
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                    fontSize: isTablet ? 15 : 13,
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
              ),
              // Footer
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _closeDialog,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 20,
                          vertical: isTablet ? 14 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoursCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.4 : 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: isTablet ? 32 : 28,
              ),
            ),
            SizedBox(height: isTablet ? 14 : 12),
            Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 26 : 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

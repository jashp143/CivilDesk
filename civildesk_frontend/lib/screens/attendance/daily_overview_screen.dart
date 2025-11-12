import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/attendance_service.dart';
import '../../models/attendance.dart';
import '../../widgets/admin_layout.dart';
import '../../core/constants/app_routes.dart';

class DailyOverviewScreen extends StatefulWidget {
  const DailyOverviewScreen({super.key});

  @override
  State<DailyOverviewScreen> createState() => _DailyOverviewScreenState();
}

class _DailyOverviewScreenState extends State<DailyOverviewScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<Attendance> _attendances = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDailyAttendance();
  }

  Future<void> _loadDailyAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _attendanceService.getDailyAttendance(date: dateString);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> attendanceList = response['data'] as List<dynamic>;
        setState(() {
          _attendances = attendanceList
              .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _attendances = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.adminAttendance,
      title: const Text('Daily Attendance Overview'),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          tooltip: 'Select Date',
          onPressed: _selectDate,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _loadDailyAttendance,
        ),
      ],
      child: Column(
        children: [
          // Date selector and summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Change Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Present',
                        _attendances
                            .where((a) => a.status == AttendanceStatus.present)
                            .length
                            .toString(),
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Absent',
                        _attendances
                            .where((a) => a.status == AttendanceStatus.absent)
                            .length
                            .toString(),
                        Colors.red,
                        Icons.cancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'On Leave',
                        _attendances
                            .where((a) => a.status == AttendanceStatus.onLeave)
                            .length
                            .toString(),
                        Colors.orange,
                        Icons.airplane_ticket,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Attendance list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDailyAttendance,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _attendances.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No attendance records for this date',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDailyAttendance,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _attendances.length,
                              itemBuilder: (context, index) {
                                final attendance = _attendances[index];
                                return _buildAttendanceCard(attendance);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance attendance) {
    Color statusColor;
    IconData statusIcon;

    switch (attendance.status) {
      case AttendanceStatus.present:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AttendanceStatus.absent:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case AttendanceStatus.onLeave:
        statusColor = Colors.orange;
        statusIcon = Icons.airplane_ticket;
        break;
      case AttendanceStatus.late:
        statusColor = Colors.amber;
        statusIcon = Icons.schedule;
        break;
      case AttendanceStatus.halfDay:
        statusColor = Colors.blue;
        statusIcon = Icons.access_time;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.employeeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${attendance.employeeId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'Check In',
                    attendance.formattedCheckInTime,
                    Icons.login,
                  ),
                ),
                if (attendance.lunchOutTime != null) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildTimeInfo(
                      'Lunch Out',
                      _formatTime(attendance.lunchOutTime),
                      Icons.restaurant,
                    ),
                  ),
                ],
                if (attendance.lunchInTime != null) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildTimeInfo(
                      'Lunch In',
                      _formatTime(attendance.lunchInTime),
                      Icons.restaurant_menu,
                    ),
                  ),
                ],
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildTimeInfo(
                    'Check Out',
                    attendance.formattedCheckOutTime,
                    Icons.logout,
                  ),
                ),
                if (attendance.workingHours != null) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildTimeInfo(
                      'Working Hours',
                      attendance.workingHours!,
                      Icons.access_time,
                    ),
                  ),
                ],
              ],
            ),
            if (attendance.recognitionMethod != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    attendance.recognitionMethod == 'FACE_RECOGNITION'
                        ? Icons.face
                        : Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    attendance.recognitionMethod == 'FACE_RECOGNITION'
                        ? 'Face Recognition'
                        : 'Manual',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (attendance.faceRecognitionConfidence != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${(attendance.faceRecognitionConfidence! * 100).toStringAsFixed(1)}% confidence)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}


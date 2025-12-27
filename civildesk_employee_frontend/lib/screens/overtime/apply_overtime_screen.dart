import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/overtime.dart';
import '../../core/providers/overtime_provider.dart';
import '../../widgets/toast.dart';

class ApplyOvertimeScreen extends StatefulWidget {
  final Overtime? existingOvertime; // For editing existing overtime

  const ApplyOvertimeScreen({super.key, this.existingOvertime});

  @override
  State<ApplyOvertimeScreen> createState() => _ApplyOvertimeScreenState();
}

class _ApplyOvertimeScreenState extends State<ApplyOvertimeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // If editing, populate fields
    if (widget.existingOvertime != null) {
      _populateFields();
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final overtime = widget.existingOvertime!;
    setState(() {
      _selectedDate = overtime.date;
      // Parse time strings (format: "HH:mm:ss" or "HH:mm")
      final startParts = overtime.startTime.split(':');
      final endParts = overtime.endTime.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      _endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
      _reasonController.text = overtime.reason;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Overtime Date',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      helpText: 'Select Start Time',
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      helpText: 'Select End Time',
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitOvertime() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final request = OvertimeRequest(
      date: _selectedDate!,
      startTime: _formatTime(_startTime!),
      endTime: _formatTime(_endTime!),
      reason: _reasonController.text.trim(),
    );

    final overtimeProvider = Provider.of<OvertimeProvider>(context, listen: false);
    bool success;

    if (widget.existingOvertime != null) {
      success = await overtimeProvider.updateOvertime(widget.existingOvertime!.id, request);
    } else {
      success = await overtimeProvider.applyOvertime(request);
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      Toast.success(context, widget.existingOvertime != null
          ? 'Overtime updated successfully'
          : 'Overtime application submitted successfully');
      Navigator.pop(context, true);
    } else {
      Toast.error(context, overtimeProvider.error ?? 'Failed to submit overtime');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingOvertime != null ? 'Edit Overtime' : 'Apply for Overtime'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date field
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    _selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _selectedDate != null ? null : Colors.grey,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectDate(context),
                ),
              ),
              if (_selectedDate == null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(
                    'Please select a date',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),

              const SizedBox(height: 16),

              // Start time field
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Start Time'),
                  subtitle: Text(
                    _startTime != null
                        ? _formatTime(_startTime!)
                        : 'Select start time',
                    style: TextStyle(
                      color: _startTime != null ? null : Colors.grey,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectStartTime(context),
                ),
              ),
              if (_startTime == null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(
                    'Please select start time',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),

              const SizedBox(height: 16),

              // End time field
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('End Time'),
                  subtitle: Text(
                    _endTime != null
                        ? _formatTime(_endTime!)
                        : 'Select end time',
                    style: TextStyle(
                      color: _endTime != null ? null : Colors.grey,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectEndTime(context),
                ),
              ),
              if (_endTime != null && _startTime != null &&
                  (_endTime!.hour < _startTime!.hour ||
                      (_endTime!.hour == _startTime!.hour &&
                          _endTime!.minute <= _startTime!.minute)))
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(
                    'End time must be after start time',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),

              const SizedBox(height: 16),

              // Reason field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason for Overtime *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          hintText: 'Enter reason for overtime',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a reason';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_selectedDate == null ||
                            _startTime == null ||
                            _endTime == null) {
                          Toast.warning(context, 'Please fill all required fields');
                          return;
                        }

                        if (_endTime!.hour < _startTime!.hour ||
                            (_endTime!.hour == _startTime!.hour &&
                                _endTime!.minute <= _startTime!.minute)) {
                          Toast.warning(context, 'End time must be after start time');
                          return;
                        }

                        _submitOvertime();
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.existingOvertime != null
                            ? 'Update Overtime'
                            : 'Submit Overtime',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

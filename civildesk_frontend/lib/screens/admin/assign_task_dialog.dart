import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/task_provider.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/utils/message_builder.dart';
import '../../models/task.dart';
import '../../models/employee.dart';
import '../../widgets/toast.dart';

class AssignTaskDialog extends StatefulWidget {
  final Task? existingTask;

  const AssignTaskDialog({super.key, this.existingTask});

  @override
  State<AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<AssignTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeService _employeeService = EmployeeService();
  final TaskService _taskService = TaskService();

  List<Employee> _allEmployees = [];
  List<int> _selectedEmployeeIds = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _location = '';
  String _description = '';
  String _modeOfTravel = '';
  String _siteName = '';
  String _siteContactPersonName = '';
  String _siteContactPhone = '';
  bool _isLoading = false;
  bool _loadingEmployees = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _startDate = task.startDate;
      _endDate = task.endDate;
      _location = task.location;
      _description = task.description;
      _modeOfTravel = task.modeOfTravelDisplay;
      _siteName = task.siteName ?? '';
      _siteContactPersonName = task.siteContactPersonName ?? '';
      _siteContactPhone = task.siteContactPhone ?? '';
      _selectedEmployeeIds = task.assignedEmployees.map((e) => e.id).toList();
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await _employeeService.getAllEmployees(page: 0, size: 1000);
      setState(() {
        _allEmployees = response.content;
        _loadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _loadingEmployees = false;
      });
      if (mounted) {
        Toast.error(context, 'Failed to load employees: $e');
      }
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _toggleEmployeeSelection(int employeeId) {
    setState(() {
      if (_selectedEmployeeIds.contains(employeeId)) {
        _selectedEmployeeIds.remove(employeeId);
      } else {
        _selectedEmployeeIds.add(employeeId);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmployeeIds.isEmpty) {
      Toast.warning(context, 'Please select at least one employee');
      return;
    }

    if (_startDate == null || _endDate == null) {
      Toast.warning(context, 'Please select date range');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = TaskRequest(
      employeeIds: _selectedEmployeeIds,
      startDate: _startDate!,
      endDate: _endDate!,
      location: _location,
      description: _description,
      modeOfTravel: _modeOfTravel,
      siteName: _siteName.isEmpty ? null : _siteName,
      siteContactPersonName: _siteContactPersonName.isEmpty ? null : _siteContactPersonName,
      siteContactPhone: _siteContactPhone.isEmpty ? null : _siteContactPhone,
    );

    final provider = Provider.of<TaskProvider>(context, listen: false);
    Task? createdTask;
    bool success;

    try {
      if (widget.existingTask != null) {
        createdTask = await _taskService.updateTask(widget.existingTask!.id, request);
        success = true;
      } else {
        createdTask = await _taskService.assignTask(request);
        success = true;
      }
      
      // Refresh provider
      await provider.refreshTasks();
    } catch (e) {
      success = false;
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success && createdTask != null) {
        Navigator.pop(context, true);
        Toast.success(
          context,
          widget.existingTask != null
              ? 'Task updated successfully'
              : 'Task assigned successfully',
        );
        
        // Show WhatsApp option for new task assignments
        if (widget.existingTask == null) {
          _showWhatsAppOptionForTask(createdTask!);
        }
      } else {
        Toast.error(
          context,
          'Failed to ${widget.existingTask != null ? 'update' : 'assign'} task',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.existingTask != null ? 'Edit Task' : 'Assign Task',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Selection
                      const Text(
                        'Select Employees *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_loadingEmployees)
                        const Center(child: CircularProgressIndicator())
                      else
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _allEmployees.isEmpty
                              ? const Center(child: Text('No employees available'))
                              : ListView.builder(
                                  itemCount: _allEmployees.length,
                                  itemBuilder: (context, index) {
                                    final employee = _allEmployees[index];
                                    final isSelected = _selectedEmployeeIds.contains(employee.id);
                                    return CheckboxListTile(
                                      title: Text('${employee.firstName} ${employee.lastName}'),
                                      subtitle: Text(employee.employeeId),
                                      value: isSelected,
                                      onChanged: (value) => _toggleEmployeeSelection(employee.id!),
                                    );
                                  },
                                ),
                        ),
                      const SizedBox(height: 16),
                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat('dd MMM yyyy').format(_startDate!)
                                      : 'Select start date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('dd MMM yyyy').format(_endDate!)
                                      : 'Select end date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Location
                      TextFormField(
                        initialValue: _location,
                        decoration: const InputDecoration(
                          labelText: 'Location *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                        onSaved: (value) => _location = value ?? '',
                        onChanged: (value) => _location = value,
                      ),
                      const SizedBox(height: 16),
                      // Mode of Travel
                      TextFormField(
                        initialValue: _modeOfTravel,
                        decoration: const InputDecoration(
                          labelText: 'Mode of Travel *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_transit),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter mode of travel';
                          }
                          return null;
                        },
                        onSaved: (value) => _modeOfTravel = value ?? '',
                        onChanged: (value) => _modeOfTravel = value,
                      ),
                      const SizedBox(height: 16),
                      // Site Name (Optional)
                      TextFormField(
                        initialValue: _siteName,
                        decoration: const InputDecoration(
                          labelText: 'Site Name (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        onSaved: (value) => _siteName = value ?? '',
                        onChanged: (value) => _siteName = value,
                      ),
                      const SizedBox(height: 16),
                      // Site Contact Person Name (Optional)
                      TextFormField(
                        initialValue: _siteContactPersonName,
                        decoration: const InputDecoration(
                          labelText: 'Site Contact Person Name (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        onSaved: (value) => _siteContactPersonName = value ?? '',
                        onChanged: (value) => _siteContactPersonName = value,
                      ),
                      const SizedBox(height: 16),
                      // Site Contact Phone (Optional)
                      TextFormField(
                        initialValue: _siteContactPhone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (Site person) (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        onSaved: (value) => _siteContactPhone = value ?? '',
                        onChanged: (value) => _siteContactPhone = value,
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        initialValue: _description,
                        decoration: const InputDecoration(
                          labelText: 'Task Description *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter task description';
                          }
                          return null;
                        },
                        onSaved: (value) => _description = value ?? '',
                        onChanged: (value) => _description = value,
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.existingTask != null ? 'UPDATE' : 'ASSIGN'),
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

  Future<void> _showWhatsAppOptionForTask(Task task) async {
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.message, color: const Color(0xFF25D366)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Send WhatsApp Notifications',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Would you like to send WhatsApp notifications to ${task.assignedEmployees.length} assigned employee(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('SKIP'),
          ),
          Flexible(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.message, color: Colors.white, size: 18),
              label: const Text('SEND TO ALL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );

    if (shouldSend == true && mounted) {
      await _sendTaskWhatsAppToEmployees(task);
    }
  }

  Future<void> _sendTaskWhatsAppToEmployees(Task task) async {
    int successCount = 0;
    int failCount = 0;

    for (final assignedEmployee in task.assignedEmployees) {
      try {
        // Fetch employee to get phone number
        final employee = await _employeeService.getEmployeeById(assignedEmployee.id);
        
        if (employee.phoneNumber.isEmpty) {
          failCount++;
          continue;
        }

        // Build message
        final message = MessageBuilder.buildTaskAssignmentMessage(
          task: task,
          employeeName: assignedEmployee.name,
        );

        // Launch WhatsApp
        final launched = await WhatsAppService.launchWhatsApp(
          phoneNumber: employee.phoneNumber,
          message: message,
        );

        if (launched) {
          successCount++;
          // Add a small delay between messages to avoid overwhelming the system
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      if (successCount > 0 && failCount == 0) {
        Toast.success(context, 'WhatsApp notifications sent to all employees');
      } else if (successCount > 0 && failCount > 0) {
        Toast.warning(
          context,
          'Sent to $successCount employee(s). Failed to send to $failCount employee(s).',
        );
      } else {
        Toast.error(context, 'Failed to send WhatsApp notifications');
      }
    }
  }
}

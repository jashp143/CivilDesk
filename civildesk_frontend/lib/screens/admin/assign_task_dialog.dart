import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/task_provider.dart';
import '../../core/services/employee_service.dart';
import '../../models/task.dart';
import '../../models/employee.dart';

class AssignTaskDialog extends StatefulWidget {
  final Task? existingTask;

  const AssignTaskDialog({Key? key, this.existingTask}) : super(key: key);

  @override
  State<AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<AssignTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeService _employeeService = EmployeeService();

  List<Employee> _allEmployees = [];
  List<int> _selectedEmployeeIds = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _location = '';
  String _description = '';
  String _modeOfTravel = '';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load employees: $e')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one employee')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date range')),
      );
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
    );

    final provider = Provider.of<TaskProvider>(context, listen: false);
    bool success;

    if (widget.existingTask != null) {
      success = await provider.updateTask(widget.existingTask!.id, request);
    } else {
      success = await provider.assignTask(request);
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingTask != null
                  ? 'Task updated successfully'
                  : 'Task assigned successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to ${widget.existingTask != null ? 'update' : 'assign'} task'),
          ),
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
                  color: Theme.of(context).colorScheme.primary,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
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
}

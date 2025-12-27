import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/leave.dart';
import '../../models/employee.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/services/employee_service.dart';
import '../../widgets/toast.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final Leave? existingLeave; // For editing existing leave

  const ApplyLeaveScreen({super.key, this.existingLeave});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeService _employeeService = EmployeeService();

  // Form fields
  LeaveType? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHalfDay = false;
  HalfDayPeriod? _halfDayPeriod;
  final TextEditingController _contactController = TextEditingController();
  List<int> _selectedEmployeeIds = [];
  final TextEditingController _reasonController = TextEditingController();
  String? _medicalCertificateUrl;
  
  List<Employee> _employees = [];
  bool _loadingEmployees = false;
  bool _isSubmitting = false;
  final TextEditingController _employeeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    
    // If editing, populate fields
    if (widget.existingLeave != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final leave = widget.existingLeave!;
    setState(() {
      _selectedLeaveType = leave.leaveType;
      _startDate = leave.startDate;
      _endDate = leave.endDate;
      _isHalfDay = leave.isHalfDay;
      _halfDayPeriod = leave.halfDayPeriod;
      _contactController.text = leave.contactNumber;
      _selectedEmployeeIds = leave.handoverEmployees?.map((e) => e.id).toList() ?? [];
      _reasonController.text = leave.reason;
      _medicalCertificateUrl = leave.medicalCertificateUrl;
    });
  }

  Future<void> _loadEmployees({String? search}) async {
    setState(() => _loadingEmployees = true);
    try {
      final employees = await _employeeService.getAllEmployees(search: search);
      setState(() {
        _employees = employees;
        _loadingEmployees = false;
      });
    } catch (e) {
      setState(() => _loadingEmployees = false);
      if (mounted) {
        Toast.error(context, 'Failed to load employees: $e');
      }
    }
  }

  Future<void> _pickMedicalCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
        final url = await leaveProvider.uploadMedicalCertificate(result.files.single.path!);
        
        if (url != null && mounted) {
          setState(() => _medicalCertificateUrl = url);
          Toast.success(context, 'Certificate uploaded successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, 'Failed to upload certificate: $e');
      }
    }
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate medical certificate for medical leave
    if (_selectedLeaveType == LeaveType.MEDICAL_LEAVE && _medicalCertificateUrl == null) {
      Toast.warning(context, 'Medical certificate is required for medical leave');
      return;
    }

    // Validate half day
    if (_isHalfDay && _halfDayPeriod == null) {
      Toast.warning(context, 'Please select half day period');
      return;
    }

    setState(() => _isSubmitting = true);

    final request = LeaveRequest(
      leaveType: _selectedLeaveType!,
      startDate: _startDate!,
      endDate: _endDate!,
      isHalfDay: _isHalfDay,
      halfDayPeriod: _halfDayPeriod,
      contactNumber: _contactController.text.trim(),
      handoverEmployeeIds: _selectedEmployeeIds.isEmpty ? null : _selectedEmployeeIds,
      reason: _reasonController.text.trim(),
      medicalCertificateUrl: _medicalCertificateUrl,
    );

    final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    bool success;

    if (widget.existingLeave != null) {
      success = await leaveProvider.updateLeave(widget.existingLeave!.id, request);
    } else {
      success = await leaveProvider.applyLeave(request);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Toast.success(context, widget.existingLeave != null 
          ? 'Leave updated successfully' 
          : 'Leave application submitted successfully');
        Navigator.pop(context, true);
      } else {
        Toast.error(context, leaveProvider.error ?? 'Failed to submit leave');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLeave != null ? 'Edit Leave' : 'Apply for Leave'),
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      backgroundColor: colorScheme.surface,
      body: _loadingEmployees
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeaveTypeDropdown(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildDateRange(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildHalfDaySwitch(theme, colorScheme),
                    if (_isHalfDay) ...[
                      const SizedBox(height: 16),
                      _buildHalfDayPeriodDropdown(theme, colorScheme),
                    ],
                    const SizedBox(height: 16),
                    _buildContactNumberField(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildHandoverEmployeesDropdown(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildReasonField(theme, colorScheme),
                    if (_selectedLeaveType == LeaveType.MEDICAL_LEAVE) ...[
                      const SizedBox(height: 16),
                      _buildMedicalCertificateUpload(theme, colorScheme),
                    ],
                    const SizedBox(height: 32),
                    _buildSubmitButton(theme, colorScheme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLeaveTypeDropdown(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<LeaveType>(
      initialValue: _selectedLeaveType,
      decoration: InputDecoration(
        labelText: 'Leave Type *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(Icons.category_rounded, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      dropdownColor: colorScheme.surface,
      style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
      items: LeaveType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedLeaveType = value);
      },
      validator: (value) => value == null ? 'Please select leave type' : null,
    );
  }

  Widget _buildDateRange(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: colorScheme,
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() {
                  _startDate = date;
                  // If end date is before start date, reset it
                  if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                    _endDate = _startDate;
                  }
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Start Date *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(Icons.calendar_today_rounded, color: colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surface,
                errorText: _startDate == null && _formKey.currentState?.validate() == false
                    ? 'Required'
                    : null,
              ),
              child: Text(
                _startDate != null
                    ? DateFormat('dd MMM yyyy').format(_startDate!)
                    : 'Select date',
                style: theme.textTheme.bodyLarge?.copyWith(
                      color: _startDate != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _endDate ?? _startDate ?? DateTime.now(),
                firstDate: _startDate ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: colorScheme,
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _endDate = date);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'End Date *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(Icons.calendar_today_rounded, color: colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surface,
                errorText: _endDate == null && _formKey.currentState?.validate() == false
                    ? 'Required'
                    : null,
              ),
              child: Text(
                _endDate != null
                    ? DateFormat('dd MMM yyyy').format(_endDate!)
                    : 'Select date',
                style: theme.textTheme.bodyLarge?.copyWith(
                      color: _endDate != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHalfDaySwitch(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          'Half Day Leave',
          style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
        ),
        subtitle: Text(
          'Check this if applying for half day',
          style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        value: _isHalfDay,
        activeThumbColor: colorScheme.primary,
        onChanged: (value) {
          setState(() {
            _isHalfDay = value;
            if (value) {
              // Set end date same as start date for half day
              _endDate = _startDate;
            }
          });
        },
      ),
    );
  }

  Widget _buildHalfDayPeriodDropdown(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<HalfDayPeriod>(
      initialValue: _halfDayPeriod,
      decoration: InputDecoration(
        labelText: 'Half Day Period *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(Icons.access_time_rounded, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      dropdownColor: colorScheme.surface,
      style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
      items: HalfDayPeriod.values.map((period) {
        return DropdownMenuItem(
          value: period,
          child: Text(period.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _halfDayPeriod = value);
      },
      validator: (value) => _isHalfDay && value == null 
          ? 'Please select half day period' 
          : null,
    );
  }

  Widget _buildContactNumberField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _contactController,
      decoration: InputDecoration(
        labelText: 'Contact Number During Leave *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(Icons.phone_rounded, color: colorScheme.primary),
        hintText: 'Enter contact number',
        filled: true,
        fillColor: colorScheme.surface,
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Contact number is required';
        }
        return null;
      },
    );
  }

  Widget _buildHandoverEmployeesDropdown(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hand Over Responsibility To',
          style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showEmployeeSelectionDialog(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(Icons.people_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedEmployeeIds.isEmpty
                        ? 'Select employees (Optional)'
                        : '${_selectedEmployeeIds.length} employee(s) selected',
                    style: theme.textTheme.bodyLarge?.copyWith(
                          color: _selectedEmployeeIds.isEmpty
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                        ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_selectedEmployeeIds.isNotEmpty && _startDate != null && _endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Conflicts will be checked automatically. Check "My Responsibilities" screen after approval to view any conflicts.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showEmployeeSelectionDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    _employeeSearchController.clear();
    
    showDialog(
      context: context,
      builder: (context) {
        List<int> tempSelected = List.from(_selectedEmployeeIds);
        List<Employee> filteredEmployees = List.from(_employees);
        bool isLoading = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> performSearch(String searchTerm) async {
              if (searchTerm.isEmpty) {
                // Reload all employees
                setDialogState(() => isLoading = true);
                try {
                  await _loadEmployees();
                  setDialogState(() {
                    filteredEmployees = List.from(_employees);
                    isLoading = false;
                  });
                } catch (e) {
                  setDialogState(() => isLoading = false);
                }
              } else {
                // Search on server
                setDialogState(() => isLoading = true);
                try {
                  await _loadEmployees(search: searchTerm);
                  setDialogState(() {
                    filteredEmployees = List.from(_employees);
                    isLoading = false;
                  });
                } catch (e) {
                  setDialogState(() => isLoading = false);
                }
              }
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.people_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Select Employees')),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    StatefulBuilder(
                      builder: (context, setSearchState) {
                        return TextField(
                          controller: _employeeSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search employees...',
                            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                            suffixIcon: _employeeSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                                    onPressed: () {
                                      _employeeSearchController.clear();
                                      setSearchState(() {});
                                      performSearch('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                          onChanged: (value) {
                            setSearchState(() {});
                            // Debounce search - wait 500ms after user stops typing
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (_employeeSearchController.text == value) {
                                performSearch(value);
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Employee list
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            )
                          : filteredEmployees.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      _employeeSearchController.text.isNotEmpty
                                          ? 'No employees found'
                                          : 'No employees available',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredEmployees.length,
                                  itemBuilder: (context, index) {
                                    final employee = filteredEmployees[index];
                                    final isSelected = tempSelected.contains(employee.id);
                                    return CheckboxListTile(
                                      title: Text(
                                        employee.fullName,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                      subtitle: Text(
                                        '${employee.employeeId} - ${employee.designation ?? "N/A"}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      value: isSelected,
                                      activeColor: colorScheme.primary,
                                      onChanged: (checked) {
                                        setDialogState(() {
                                          if (checked == true) {
                                            tempSelected.add(employee.id);
                                          } else {
                                            tempSelected.remove(employee.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedEmployeeIds = tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReasonField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _reasonController,
      decoration: InputDecoration(
        labelText: 'Reason for Leave *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(Icons.description_rounded, color: colorScheme.primary),
        hintText: 'Enter reason',
        alignLabelWithHint: true,
        filled: true,
        fillColor: colorScheme.surface,
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Reason is required';
        }
        return null;
      },
    );
  }

  Widget _buildMedicalCertificateUpload(ThemeData theme, ColorScheme colorScheme) {
    final successColor = colorScheme.brightness == Brightness.dark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Certificate *',
          style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickMedicalCertificate,
          icon: Icon(
            _medicalCertificateUrl != null
                ? Icons.check_circle_rounded
                : Icons.upload_file_rounded,
          ),
          label: Text(
            _medicalCertificateUrl != null
                ? 'Certificate Uploaded'
                : 'Upload Certificate',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _medicalCertificateUrl != null
                ? successColor
                : colorScheme.primary,
            foregroundColor: _medicalCertificateUrl != null
                ? Colors.white
                : colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_medicalCertificateUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: successColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Certificate uploaded successfully',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitLeave,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                widget.existingLeave != null ? 'UPDATE LEAVE' : 'SUBMIT LEAVE',
                style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    _reasonController.dispose();
    _employeeSearchController.dispose();
    super.dispose();
  }
}

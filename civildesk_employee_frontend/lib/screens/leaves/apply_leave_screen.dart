import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/leave.dart';
import '../../models/employee.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/services/employee_service.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final Leave? existingLeave; // For editing existing leave

  const ApplyLeaveScreen({Key? key, this.existingLeave}) : super(key: key);

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

  Future<void> _loadEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final employees = await _employeeService.getAllEmployees();
      setState(() {
        _employees = employees;
        _loadingEmployees = false;
      });
    } catch (e) {
      setState(() => _loadingEmployees = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load employees: $e')),
        );
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
        
        if (url != null) {
          setState(() => _medicalCertificateUrl = url);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Certificate uploaded successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload certificate: $e')),
        );
      }
    }
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate medical certificate for medical leave
    if (_selectedLeaveType == LeaveType.MEDICAL_LEAVE && _medicalCertificateUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical certificate is required for medical leave')),
      );
      return;
    }

    // Validate half day
    if (_isHalfDay && _halfDayPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select half day period')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingLeave != null 
              ? 'Leave updated successfully' 
              : 'Leave application submitted successfully'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(leaveProvider.error ?? 'Failed to submit leave')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLeave != null ? 'Edit Leave' : 'Apply for Leave'),
        elevation: 0,
      ),
      body: _loadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeaveTypeDropdown(),
                    const SizedBox(height: 16),
                    _buildDateRange(),
                    const SizedBox(height: 16),
                    _buildHalfDaySwitch(),
                    if (_isHalfDay) ...[
                      const SizedBox(height: 16),
                      _buildHalfDayPeriodDropdown(),
                    ],
                    const SizedBox(height: 16),
                    _buildContactNumberField(),
                    const SizedBox(height: 16),
                    _buildHandoverEmployeesDropdown(),
                    const SizedBox(height: 16),
                    _buildReasonField(),
                    if (_selectedLeaveType == LeaveType.MEDICAL_LEAVE) ...[
                      const SizedBox(height: 16),
                      _buildMedicalCertificateUpload(),
                    ],
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLeaveTypeDropdown() {
    return DropdownButtonFormField<LeaveType>(
      value: _selectedLeaveType,
      decoration: InputDecoration(
        labelText: 'Leave Type *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.category),
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

  Widget _buildDateRange() {
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.calendar_today),
                errorText: _startDate == null && _formKey.currentState?.validate() == false
                    ? 'Required'
                    : null,
              ),
              child: Text(
                _startDate != null
                    ? DateFormat('dd MMM yyyy').format(_startDate!)
                    : 'Select date',
                style: TextStyle(
                  color: _startDate != null ? null : Colors.grey,
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
              );
              if (date != null) {
                setState(() => _endDate = date);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'End Date *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.calendar_today),
                errorText: _endDate == null && _formKey.currentState?.validate() == false
                    ? 'Required'
                    : null,
              ),
              child: Text(
                _endDate != null
                    ? DateFormat('dd MMM yyyy').format(_endDate!)
                    : 'Select date',
                style: TextStyle(
                  color: _endDate != null ? null : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHalfDaySwitch() {
    return SwitchListTile(
      title: const Text('Half Day Leave'),
      subtitle: const Text('Check this if applying for half day'),
      value: _isHalfDay,
      onChanged: (value) {
        setState(() {
          _isHalfDay = value;
          if (value) {
            // Set end date same as start date for half day
            _endDate = _startDate;
          }
        });
      },
    );
  }

  Widget _buildHalfDayPeriodDropdown() {
    return DropdownButtonFormField<HalfDayPeriod>(
      value: _halfDayPeriod,
      decoration: InputDecoration(
        labelText: 'Half Day Period *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.access_time),
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

  Widget _buildContactNumberField() {
    return TextFormField(
      controller: _contactController,
      decoration: InputDecoration(
        labelText: 'Contact Number During Leave *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.phone),
        hintText: 'Enter contact number',
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

  Widget _buildHandoverEmployeesDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hand Over Responsibility To',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: const Icon(Icons.people),
            title: Text(
              _selectedEmployeeIds.isEmpty
                  ? 'Select employees'
                  : '${_selectedEmployeeIds.length} employee(s) selected',
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => _showEmployeeSelectionDialog(),
          ),
        ),
      ],
    );
  }

  void _showEmployeeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<int> tempSelected = List.from(_selectedEmployeeIds);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Employees'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final employee = _employees[index];
                    final isSelected = tempSelected.contains(employee.id);
                    return CheckboxListTile(
                      title: Text(employee.fullName),
                      subtitle: Text(
                        '${employee.employeeId} - ${employee.designation ?? "N/A"}',
                      ),
                      value: isSelected,
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
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      decoration: InputDecoration(
        labelText: 'Reason for Leave *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.description),
        hintText: 'Enter reason',
        alignLabelWithHint: true,
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

  Widget _buildMedicalCertificateUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Certificate *',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickMedicalCertificate,
          icon: const Icon(Icons.upload_file),
          label: Text(
            _medicalCertificateUrl != null
                ? 'Certificate Uploaded'
                : 'Upload Certificate',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _medicalCertificateUrl != null
                ? Colors.green
                : null,
          ),
        ),
        if (_medicalCertificateUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                const Text('Certificate uploaded successfully'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitLeave,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator()
            : Text(
                widget.existingLeave != null ? 'UPDATE LEAVE' : 'SUBMIT LEAVE',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}

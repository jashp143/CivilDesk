import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employee.dart';
import '../../core/utils/validators.dart';

class EmployeeRegistrationDialog extends StatefulWidget {
  const EmployeeRegistrationDialog({super.key});

  @override
  State<EmployeeRegistrationDialog> createState() => _EmployeeRegistrationDialogState();
}

class _EmployeeRegistrationDialogState extends State<EmployeeRegistrationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<GlobalKey<FormState>> _formKeys = List.generate(10, (_) => GlobalKey<FormState>());

  // Step 1: Personal Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  DateTime? _dateOfBirth;
  Gender? _gender;
  MaritalStatus? _maritalStatus;
  final _bloodGroupController = TextEditingController();

  // Step 2: Contact Information
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Step 3: Identification
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _uanController = TextEditingController();
  final _esicNumberController = TextEditingController();

  // Step 4: Work Information
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  DateTime? _joiningDate;
  EmploymentType? _employmentType;
  final _workLocationController = TextEditingController();
  AttendanceMethod _attendanceMethod = AttendanceMethod.faceRecognition;

  // Step 5: Salary Structure Information
  final _basicSalaryController = TextEditingController();
  final _hraController = TextEditingController();
  final _conveyanceController = TextEditingController();
  final _uniformAndSafetyController = TextEditingController();
  final _bonusController = TextEditingController();
  final _foodAllowanceController = TextEditingController();
  final _otherAllowanceController = TextEditingController();
  final _overtimeRateController = TextEditingController();
  final _epfEmployeeController = TextEditingController();
  final _epfEmployerController = TextEditingController();

  // Step 6: Deduction Structure Information
  final _esicPercentController = TextEditingController();
  final _professionalTaxController = TextEditingController();

  // Step 7: Bank Information
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankBranchController = TextEditingController();

  // Step 8: Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _bloodGroupController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _uanController.dispose();
    _esicNumberController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _workLocationController.dispose();
    _basicSalaryController.dispose();
    _hraController.dispose();
    _conveyanceController.dispose();
    _uniformAndSafetyController.dispose();
    _bonusController.dispose();
    _foodAllowanceController.dispose();
    _otherAllowanceController.dispose();
    _overtimeRateController.dispose();
    _epfEmployeeController.dispose();
    _epfEmployerController.dispose();
    _esicPercentController.dispose();
    _professionalTaxController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankBranchController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  bool _validateCurrentTab() {
    final formKey = _formKeys[_tabController.index];
    if (!formKey.currentState!.validate()) {
      return false;
    }
    
    switch (_tabController.index) {
      case 0:
        return _dateOfBirth != null && _gender != null && _maritalStatus != null;
      case 2:
        // Identification - UAN and ESIC are conditional
        return true;
      case 3:
        return _joiningDate != null && _employmentType != null;
      case 8:
      case 9:
        // Face registration and credentials are optional/separate flows
        return true;
      default:
        return true;
    }
  }

  void _nextTab() {
    if (_validateCurrentTab()) {
      if (_tabController.index < _tabController.length - 1) {
        _tabController.animateTo(_tabController.index + 1);
      } else {
        _submitForm();
      }
    }
  }

  void _previousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentTab()) return;

    final employee = Employee(
      employeeId: '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      maritalStatus: _maritalStatus,
      bloodGroup: _bloodGroupController.text.trim().isEmpty
          ? null
          : _bloodGroupController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      alternatePhoneNumber: _alternatePhoneController.text.trim().isEmpty
          ? null
          : _alternatePhoneController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim().isEmpty
          ? null
          : _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      pincode: _pincodeController.text.trim().isEmpty
          ? null
          : _pincodeController.text.trim(),
      country: 'India',
      aadharNumber: _aadharController.text.trim().replaceAll(RegExp(r'[\s-]'), ''),
      panNumber: _panController.text.trim().toUpperCase(),
      uanNumber: _uanController.text.trim().isEmpty ? null : _uanController.text.trim(),
      esicNumber: _esicNumberController.text.trim().isEmpty ? null : _esicNumberController.text.trim(),
      department: _departmentController.text.trim().isEmpty
          ? null
          : _departmentController.text.trim(),
      designation: _designationController.text.trim().isEmpty
          ? null
          : _designationController.text.trim(),
      joiningDate: _joiningDate,
      employmentType: _employmentType,
      workLocation: _workLocationController.text.trim().isEmpty
          ? null
          : _workLocationController.text.trim(),
      basicSalary: _basicSalaryController.text.trim().isEmpty
          ? null
          : double.tryParse(_basicSalaryController.text.trim()),
      houseRentAllowance: _hraController.text.trim().isEmpty
          ? null
          : double.tryParse(_hraController.text.trim()),
      conveyance: _conveyanceController.text.trim().isEmpty
          ? null
          : double.tryParse(_conveyanceController.text.trim()),
      uniformAndSafety: _uniformAndSafetyController.text.trim().isEmpty
          ? null
          : double.tryParse(_uniformAndSafetyController.text.trim()),
      bonus: _bonusController.text.trim().isEmpty
          ? null
          : double.tryParse(_bonusController.text.trim()),
      foodAllowance: _foodAllowanceController.text.trim().isEmpty
          ? null
          : double.tryParse(_foodAllowanceController.text.trim()),
      otherAllowance: _otherAllowanceController.text.trim().isEmpty
          ? null
          : double.tryParse(_otherAllowanceController.text.trim()),
      overtimeRate: _overtimeRateController.text.trim().isEmpty
          ? null
          : double.tryParse(_overtimeRateController.text.trim()),
      epfEmployee: _epfEmployeeController.text.trim().isEmpty
          ? null
          : double.tryParse(_epfEmployeeController.text.trim()),
      epfEmployer: _epfEmployerController.text.trim().isEmpty
          ? null
          : double.tryParse(_epfEmployerController.text.trim()),
      esic: _esicPercentController.text.trim().isEmpty
          ? null
          : double.tryParse(_esicPercentController.text.trim()),
      professionalTax: _professionalTaxController.text.trim().isEmpty
          ? null
          : double.tryParse(_professionalTaxController.text.trim()),
      bankName: _bankNameController.text.trim().isEmpty
          ? null
          : _bankNameController.text.trim(),
      bankAccountNumber: _accountNumberController.text.trim().isEmpty
          ? null
          : _accountNumberController.text.trim(),
      ifscCode: _ifscController.text.trim().isEmpty
          ? null
          : _ifscController.text.trim().toUpperCase(),
      bankBranch: _bankBranchController.text.trim().isEmpty
          ? null
          : _bankBranchController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim().isEmpty
          ? null
          : _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
          ? null
          : _emergencyPhoneController.text.trim(),
      emergencyContactRelation: _emergencyRelationController.text.trim().isEmpty
          ? null
          : _emergencyRelationController.text.trim(),
      employmentStatus: EmploymentStatus.active,
      isActive: true,
      attendanceMethod: _attendanceMethod,
    );

    final provider = context.read<EmployeeProvider>();
    final success = await provider.createEmployee(employee);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee created successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.error ?? "Failed to create employee"}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Employee Registration',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'Contact'),
                Tab(text: 'Identification'),
                Tab(text: 'Work'),
                Tab(text: 'Salary'),
                Tab(text: 'Deduction'),
                Tab(text: 'Bank'),
                Tab(text: 'Emergency'),
                Tab(text: 'Face'),
                Tab(text: 'Credentials'),
              ],
            ),
            // Tab Content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalTab(),
                  _buildContactTab(),
                  _buildIdentificationTab(),
                  _buildWorkTab(),
                  _buildSalaryTab(),
                  _buildDeductionTab(),
                  _buildBankTab(),
                  _buildEmergencyTab(),
                  _buildFaceTab(),
                  _buildCredentialsTab(),
                ],
              ),
            ),
            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_tabController.index > 0)
                    OutlinedButton(
                      onPressed: _previousTab,
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _nextTab,
                    child: Text(_tabController.index == _tabController.length - 1 ? 'Submit' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name *'),
              validator: (value) => Validators.validateName(value, fieldName: 'First name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(labelText: 'Middle Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name *'),
              validator: (value) => Validators.validateName(value, fieldName: 'Last name'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_dateOfBirth == null
                  ? 'Date of Birth *'
                  : DateFormat('yyyy-MM-dd').format(_dateOfBirth!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _dateOfBirth = date);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Gender>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender *'),
              items: Gender.values.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text(g.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MaritalStatus>(
              value: _maritalStatus,
              decoration: const InputDecoration(labelText: 'Marital Status *'),
              items: MaritalStatus.values.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _maritalStatus = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bloodGroupController,
              decoration: const InputDecoration(labelText: 'Blood Group'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alternatePhoneController,
              decoration: const InputDecoration(labelText: 'Alternate Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(labelText: 'Address Line 1'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(labelText: 'Address Line 2'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(labelText: 'State'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pincodeController,
              decoration: const InputDecoration(labelText: 'Pincode'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _aadharController,
              decoration: const InputDecoration(labelText: 'Aadhar Number *'),
              keyboardType: TextInputType.number,
              validator: Validators.validateAadhar,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _panController,
              decoration: const InputDecoration(labelText: 'PAN Number *'),
              textCapitalization: TextCapitalization.characters,
              validator: Validators.validatePAN,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _uanController,
              decoration: const InputDecoration(labelText: 'UAN Number * (Required if EPF is applicable)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _esicNumberController,
              decoration: const InputDecoration(labelText: 'ESIC Number * (Required if ESIC is applicable)'),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _designationController,
              decoration: const InputDecoration(labelText: 'Designation'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_joiningDate == null
                  ? 'Joining Date *'
                  : DateFormat('yyyy-MM-dd').format(_joiningDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _joiningDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EmploymentType>(
              value: _employmentType,
              decoration: const InputDecoration(labelText: 'Employment Type *'),
              items: EmploymentType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _employmentType = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _workLocationController,
              decoration: const InputDecoration(labelText: 'Work Location'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Attendance Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how this employee will mark their attendance. Only one method can be active at a time.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildAttendanceMethodSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMethodSelector() {
    return Column(
      children: [
        RadioListTile<AttendanceMethod>(
          value: AttendanceMethod.faceRecognition,
          groupValue: _attendanceMethod,
          onChanged: (value) => setState(() => _attendanceMethod = value!),
          title: const Text('Face Recognition'),
          subtitle: const Text('Employee marks attendance via face recognition at office/site terminal'),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.statBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.face, color: AppTheme.statBlue),
          ),
        ),
        const SizedBox(height: 8),
        RadioListTile<AttendanceMethod>(
          value: AttendanceMethod.gpsBased,
          groupValue: _attendanceMethod,
          onChanged: (value) => setState(() => _attendanceMethod = value!),
          title: const Text('GPS Based (Field Employee)'),
          subtitle: const Text('Employee marks attendance from mobile app with GPS location verification'),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.statusApproved.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: AppTheme.statusApproved),
          ),
        ),
        if (_attendanceMethod == AttendanceMethod.gpsBased) ...[
          const SizedBox(height: 16),
          Card(
            color: AppTheme.statusPending.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.statusPending),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'After registration, assign construction sites to this employee for GPS-based attendance validation.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSalaryTab() {
    final hasUan = _uanController.text.trim().isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[4],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _basicSalaryController,
              decoration: const InputDecoration(labelText: 'Basic Salary (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hraController,
              decoration: const InputDecoration(labelText: 'House Rent Allowance (HRA) (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conveyanceController,
              decoration: const InputDecoration(labelText: 'Conveyance (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _uniformAndSafetyController,
              decoration: const InputDecoration(labelText: 'Uniform and Safety (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bonusController,
              decoration: const InputDecoration(labelText: 'Bonus (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _foodAllowanceController,
              decoration: const InputDecoration(labelText: 'Food Allowance (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otherAllowanceController,
              decoration: const InputDecoration(labelText: 'Other Allowance (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _overtimeRateController,
              decoration: const InputDecoration(labelText: 'Overtime Rate (per hour) (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _epfEmployeeController,
              decoration: InputDecoration(
                labelText: 'EPF for Employee (%)',
                helperText: hasUan ? null : 'Enter UAN number in Identification tab to enable EPF',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: hasUan,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _epfEmployerController,
              decoration: InputDecoration(
                labelText: 'EPF for Employer (%)',
                helperText: hasUan ? null : 'Enter UAN number in Identification tab to enable EPF',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: hasUan,
            ),
            const SizedBox(height: 24),
            _buildSalarySummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalarySummary() {
    final basic = double.tryParse(_basicSalaryController.text.trim()) ?? 0.0;
    final hra = double.tryParse(_hraController.text.trim()) ?? 0.0;
    final conveyance = double.tryParse(_conveyanceController.text.trim()) ?? 0.0;
    final uniform = double.tryParse(_uniformAndSafetyController.text.trim()) ?? 0.0;
    final bonus = double.tryParse(_bonusController.text.trim()) ?? 0.0;
    final food = double.tryParse(_foodAllowanceController.text.trim()) ?? 0.0;
    final other = double.tryParse(_otherAllowanceController.text.trim()) ?? 0.0;
    
    final grossSalary = basic + hra + conveyance + uniform + bonus + food + other;
    
    final epfEmployeePercent = double.tryParse(_epfEmployeeController.text.trim()) ?? 0.0;
    final esicPercent = double.tryParse(_esicPercentController.text.trim()) ?? 0.0;
    final professionalTax = double.tryParse(_professionalTaxController.text.trim()) ?? 0.0;
    
    final epfEmployeeAmount = (basic * epfEmployeePercent / 100);
    final esicAmount = (grossSalary * esicPercent / 100);
    final totalDeductions = epfEmployeeAmount + esicAmount + professionalTax;
    
    final netSalary = grossSalary - totalDeductions;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Salary Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Gross Salary', '₹${grossSalary.toStringAsFixed(2)}'),
            const Divider(),
            const Text(
              'Deductions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (epfEmployeeAmount > 0)
              _buildSummaryRow('EPF (Employee)', '₹${epfEmployeeAmount.toStringAsFixed(2)}'),
            if (esicAmount > 0)
              _buildSummaryRow('ESIC', '₹${esicAmount.toStringAsFixed(2)}'),
            if (professionalTax > 0)
              _buildSummaryRow('Professional Tax', '₹${professionalTax.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow('Total Deductions', '₹${totalDeductions.toStringAsFixed(2)}', isBold: true),
            const SizedBox(height: 8),
            _buildSummaryRow('Net Salary', '₹${netSalary.toStringAsFixed(2)}', isBold: true, isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionTab() {
    final hasEsic = _esicNumberController.text.trim().isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[5],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _esicPercentController,
              decoration: InputDecoration(
                labelText: 'ESIC (%)',
                helperText: hasEsic ? null : 'Enter ESIC number in Identification tab to enable ESIC',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: hasEsic,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _professionalTaxController,
              decoration: const InputDecoration(labelText: 'Professional Tax (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[5],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(labelText: 'Account Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ifscController,
              decoration: const InputDecoration(labelText: 'IFSC Code'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankBranchController,
              decoration: const InputDecoration(labelText: 'Branch'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[6],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emergencyNameController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(labelText: 'Contact Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyRelationController,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[8],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Face Registration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Face registration will be available after employee creation. You can register the employee\'s face from the employee details page.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.face, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Face registration feature will be enabled after employee is created.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[9],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Employee App Credentials',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Employee login credentials will be automatically generated and sent to the employee\'s email address after registration.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.email, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    const Text(
                      'Credentials will be sent to:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _emailController.text.trim().isEmpty 
                          ? 'Email address' 
                          : _emailController.text.trim(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The employee will receive their login credentials via email after successful registration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


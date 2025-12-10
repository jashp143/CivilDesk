import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/services/face_recognition_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employee.dart';
import '../attendance/face_registration_screen.dart';
import 'employee_edit_dialog.dart';

class EmployeeDetailDialog extends StatefulWidget {
  final int employeeId;

  const EmployeeDetailDialog({
    super.key,
    required this.employeeId,
  });

  @override
  State<EmployeeDetailDialog> createState() => _EmployeeDetailDialogState();
}

class _EmployeeDetailDialogState extends State<EmployeeDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployeeById(widget.employeeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(BuildContext context, Employee employee, EmployeeProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete ${employee.fullName}?\n\nThis will also delete their face recognition data.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Delete face embeddings if they exist
        final faceService = FaceRecognitionService();
        await faceService.deleteFaceEmbeddings(employee.employeeId);

        // Delete employee
        final success = await provider.deleteEmployee(employee.id!);

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          if (success) {
            Navigator.of(context).pop(); // Close detail dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Employee deleted successfully'),
                backgroundColor: AppTheme.statusApproved,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to delete employee: ${provider.error ?? "Unknown error"}',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting employee: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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
            Consumer<EmployeeProvider>(
              builder: (context, provider, child) {
                final employee = provider.selectedEmployee;
                return Container(
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
                          employee?.fullName ?? 'Employee Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (employee != null) ...[
                        IconButton(
                          icon: Icon(Icons.edit, color: colorScheme.onSurface),
                          tooltip: 'Edit Employee',
                          onPressed: () {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => EmployeeEditDialog(employee: employee),
                            ).then((result) {
                              if (result == true && mounted) {
                                provider.loadEmployeeById(widget.employeeId);
                                provider.loadEmployees(refresh: true);
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.face, color: colorScheme.onSurface),
                          tooltip: 'Register Face',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FaceRegistrationScreen(
                                  employeeId: employee.employeeId,
                                ),
                              ),
                            ).then((success) {
                            if (success == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Face registered successfully!'),
                                  backgroundColor: AppTheme.statusApproved,
                                ),
                              );
                            }
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: colorScheme.onSurface),
                          tooltip: 'Delete Employee',
                          onPressed: () => _handleDelete(context, employee, provider),
                        ),
                      ],
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              },
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
              child: Consumer<EmployeeProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.selectedEmployee == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && provider.selectedEmployee == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${provider.error}',
                            style: TextStyle(color: colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.loadEmployeeById(widget.employeeId),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final employee = provider.selectedEmployee;
                  if (employee == null) {
                    return const Center(child: Text('Employee not found'));
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPersonalTab(employee),
                      _buildContactTab(employee),
                      _buildIdentificationTab(employee),
                      _buildWorkTab(employee),
                      _buildSalaryTab(employee),
                      _buildDeductionTab(employee),
                      _buildBankTab(employee),
                      _buildEmergencyTab(employee),
                      _buildFaceTab(employee),
                      _buildCredentialsTab(employee),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                employee.firstName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 40,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FaceRegistrationScreen(
                      employeeId: employee.employeeId,
                    ),
                  ),
                ).then((success) {
                if (success == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Face registered successfully!'),
                      backgroundColor: AppTheme.statusApproved,
                    ),
                  );
                }
                });
              },
              icon: const Icon(Icons.face),
              label: const Text('Register Face'),
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailCard([
            _buildDetailRow('Employee ID', employee.employeeId),
            _buildDetailRow('Full Name', employee.fullName),
            if (employee.dateOfBirth != null)
              _buildDetailRow(
                'Date of Birth',
                DateFormat('yyyy-MM-dd').format(employee.dateOfBirth!),
              ),
            if (employee.gender != null)
              _buildDetailRow('Gender', employee.gender!.name.toUpperCase()),
            if (employee.maritalStatus != null)
              _buildDetailRow(
                'Marital Status',
                employee.maritalStatus!.name.toUpperCase(),
              ),
            if (employee.bloodGroup != null)
              _buildDetailRow('Blood Group', employee.bloodGroup!),
          ]),
        ],
      ),
    );
  }

  Widget _buildContactTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard([
            _buildDetailRow('Email', employee.email),
            _buildDetailRow('Phone', employee.phoneNumber),
            if (employee.alternatePhoneNumber != null)
              _buildDetailRow('Alternate Phone', employee.alternatePhoneNumber!),
            if (employee.addressLine1 != null)
              _buildDetailRow('Address Line 1', employee.addressLine1!),
            if (employee.addressLine2 != null)
              _buildDetailRow('Address Line 2', employee.addressLine2!),
            if (employee.city != null) _buildDetailRow('City', employee.city!),
            if (employee.state != null) _buildDetailRow('State', employee.state!),
            if (employee.pincode != null)
              _buildDetailRow('Pincode', employee.pincode!),
            if (employee.country != null)
              _buildDetailRow('Country', employee.country!),
          ]),
        ],
      ),
    );
  }

  Widget _buildIdentificationTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard([
            _buildDetailRow('Aadhar Number', employee.aadharNumber),
            _buildDetailRow('PAN Number', employee.panNumber),
            if (employee.uanNumber != null)
              _buildDetailRow('UAN Number', employee.uanNumber!),
            if (employee.esicNumber != null)
              _buildDetailRow('ESIC Number', employee.esicNumber!),
          ]),
        ],
      ),
    );
  }

  Widget _buildWorkTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard([
            if (employee.department != null)
              _buildDetailRow('Department', employee.department!),
            if (employee.designation != null)
              _buildDetailRow('Designation', employee.designation!),
            if (employee.joiningDate != null)
              _buildDetailRow(
                'Joining Date',
                DateFormat('yyyy-MM-dd').format(employee.joiningDate!),
              ),
            if (employee.employmentType != null)
              _buildDetailRow(
                'Employment Type',
                employee.employmentType!.name
                    .replaceAll('_', ' ')
                    .toUpperCase(),
              ),
            if (employee.employmentStatus != null)
              _buildDetailRow(
                'Employment Status',
                employee.employmentStatus!.name
                    .replaceAll('_', ' ')
                    .toUpperCase(),
              ),
            if (employee.workLocation != null)
              _buildDetailRow('Work Location', employee.workLocation!),
            if (employee.reportingManagerName != null)
              _buildDetailRow(
                'Reporting Manager',
                employee.reportingManagerName!,
              ),
          ]),
          const SizedBox(height: 16),
          // Attendance Method Card
          if (employee.attendanceMethod != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: employee.attendanceMethod == AttendanceMethod.gpsBased
                                ? AppTheme.statusApproved.withOpacity(0.1)
                                : AppTheme.statBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            employee.attendanceMethod == AttendanceMethod.gpsBased
                                ? Icons.location_on
                                : Icons.face,
                            color: employee.attendanceMethod == AttendanceMethod.gpsBased
                                ? AppTheme.statusApproved
                                : AppTheme.statBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Method',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                employee.attendanceMethod == AttendanceMethod.gpsBased
                                    ? 'GPS Based (Field Employee)'
                                    : 'Face Recognition',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: employee.attendanceMethod == AttendanceMethod.gpsBased
                                      ? AppTheme.statusApproved
                                      : AppTheme.statBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            employee.attendanceMethod == AttendanceMethod.gpsBased
                                ? 'GPS'
                                : 'Face',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: employee.attendanceMethod == AttendanceMethod.gpsBased
                              ? AppTheme.statusApproved.withOpacity(0.1)
                              : AppTheme.statBlue.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: employee.attendanceMethod == AttendanceMethod.gpsBased
                                ? AppTheme.statusApproved
                                : AppTheme.statBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      employee.attendanceMethod == AttendanceMethod.gpsBased
                          ? 'Employee marks attendance from mobile app with GPS location verification. Make sure the employee is assigned to construction sites for geofence validation.'
                          : 'Employee marks attendance via face recognition at office/site terminal.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSalaryTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard([
            if (employee.basicSalary != null)
              _buildDetailRow(
                'Basic Salary',
                '₹${employee.basicSalary!.toStringAsFixed(2)}',
              ),
            if (employee.houseRentAllowance != null)
              _buildDetailRow(
                'HRA',
                '₹${employee.houseRentAllowance!.toStringAsFixed(2)}',
              ),
            if (employee.conveyance != null)
              _buildDetailRow(
                'Conveyance',
                '₹${employee.conveyance!.toStringAsFixed(2)}',
              ),
            if (employee.uniformAndSafety != null)
              _buildDetailRow(
                'Uniform and Safety',
                '₹${employee.uniformAndSafety!.toStringAsFixed(2)}',
              ),
            if (employee.bonus != null)
              _buildDetailRow(
                'Bonus',
                '₹${employee.bonus!.toStringAsFixed(2)}',
              ),
            if (employee.foodAllowance != null)
              _buildDetailRow(
                'Food Allowance',
                '₹${employee.foodAllowance!.toStringAsFixed(2)}',
              ),
            if (employee.otherAllowance != null)
              _buildDetailRow(
                'Other Allowance',
                '₹${employee.otherAllowance!.toStringAsFixed(2)}',
              ),
            if (employee.overtimeRate != null)
              _buildDetailRow(
                'Overtime Rate (per hour)',
                '₹${employee.overtimeRate!.toStringAsFixed(2)}',
              ),
            if (employee.epfEmployee != null)
              _buildDetailRow(
                'EPF (Employee)',
                '${employee.epfEmployee!.toStringAsFixed(2)}%',
              ),
            if (employee.epfEmployer != null)
              _buildDetailRow(
                'EPF (Employer)',
                '${employee.epfEmployer!.toStringAsFixed(2)}%',
              ),
          ]),
          const SizedBox(height: 16),
          _buildSalarySummaryCard(employee),
        ],
      ),
    );
  }

  Widget _buildSalarySummaryCard(Employee employee) {
    final basic = employee.basicSalary ?? 0.0;
    final hra = employee.houseRentAllowance ?? 0.0;
    final conveyance = employee.conveyance ?? 0.0;
    final uniform = employee.uniformAndSafety ?? 0.0;
    final bonus = employee.bonus ?? 0.0;
    final food = employee.foodAllowance ?? 0.0;
    final other = employee.otherAllowance ?? 0.0;
    
    final grossSalary = basic + hra + conveyance + uniform + bonus + food + other;
    
    final epfEmployeePercent = employee.epfEmployee ?? 0.0;
    final esicPercent = employee.esic ?? 0.0;
    final professionalTax = employee.professionalTax ?? 0.0;
    
    final epfEmployeeAmount = (basic * epfEmployeePercent / 100);
    final esicAmount = (grossSalary * esicPercent / 100);
    final totalDeductions = epfEmployeeAmount + esicAmount + professionalTax;
    
    final netSalary = grossSalary - totalDeductions;
    
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surfaceVariant,
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

  Widget _buildDeductionTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard([
            if (employee.esic != null)
              _buildDetailRow(
                'ESIC (%)',
                '${employee.esic!.toStringAsFixed(2)}%',
              ),
            if (employee.professionalTax != null)
              _buildDetailRow(
                'Professional Tax',
                '₹${employee.professionalTax!.toStringAsFixed(2)}',
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBankTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard([
            if (employee.bankName != null)
              _buildDetailRow('Bank Name', employee.bankName!),
            if (employee.bankAccountNumber != null)
              _buildDetailRow('Account Number', employee.bankAccountNumber!),
            if (employee.ifscCode != null)
              _buildDetailRow('IFSC Code', employee.ifscCode!),
            if (employee.bankBranch != null)
              _buildDetailRow('Branch', employee.bankBranch!),
          ]),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard([
            if (employee.emergencyContactName != null)
              _buildDetailRow(
                'Contact Name',
                employee.emergencyContactName!,
              ),
            if (employee.emergencyContactPhone != null)
              _buildDetailRow(
                'Contact Phone',
                employee.emergencyContactPhone!,
              ),
            if (employee.emergencyContactRelation != null)
              _buildDetailRow(
                'Relation',
                employee.emergencyContactRelation!,
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildFaceTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.face, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text(
            'Face Registration',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceRegistrationScreen(
                    employeeId: employee.employeeId,
                  ),
                ),
              ).then((success) {
                if (success == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Face registered successfully!'),
                      backgroundColor: AppTheme.statusApproved,
                    ),
                  );
                }
              });
            },
            icon: const Icon(Icons.face),
            label: const Text('Register/Update Face'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Face Recognition',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Register the employee\'s face for attendance tracking using face recognition technology.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.lock_outline, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text(
            'Employee App Credentials',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Email', employee.email),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Login Credentials',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                    Text(
                      'Generate employee app credentials to allow the employee to login to the employee app. Credentials will be sent to the employee\'s email address.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 24),
                  Consumer<EmployeeProvider>(
                    builder: (context, provider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading
                              ? null
                              : () => _handleGenerateCredentials(context, employee, provider),
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.vpn_key),
                          label: Text(provider.isLoading
                              ? 'Generating...'
                              : 'Generate Employee App Credentials'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Note: The employee can use these credentials to login to the employee app using the common login screen.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGenerateCredentials(
    BuildContext context,
    Employee employee,
    EmployeeProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Employee Credentials'),
        content: Text(
          'Are you sure you want to generate credentials for ${employee.fullName}?\n\n'
          'A new password will be generated and sent to ${employee.email}.\n\n'
          'If credentials already exist, they will be reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await provider.generateEmployeeCredentials(employee.id!);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Credentials generated successfully! An email has been sent to ${employee.email}'
                  : 'Failed to generate credentials: ${provider.error ?? "Unknown error"}',
            ),
            backgroundColor: success ? AppTheme.statusApproved : Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildDocumentsTab(Employee employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentItem(
            'Aadhar Document',
            employee.aadharDocumentUrl,
          ),
          _buildDocumentItem(
            'PAN Document',
            employee.panDocumentUrl,
          ),
          _buildDocumentItem(
            'Resume',
            employee.resumeUrl,
          ),
          _buildDocumentItem(
            'Offer Letter',
            employee.offerLetterUrl,
          ),
          _buildDocumentItem(
            'Appointment Letter',
            employee.appointmentLetterUrl,
          ),
          _buildDocumentItem(
            'Other Documents',
            employee.otherDocumentsUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String label, String? url) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: url != null
            ? Icon(Icons.check_circle, color: AppTheme.statusApproved)
            : Icon(Icons.cancel, color: colorScheme.onSurfaceVariant),
        onTap: url != null
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening $label...')),
                );
              }
            : null,
      ),
    );
  }
}



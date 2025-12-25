import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employee.dart';
import '../../widgets/admin_layout.dart';
import '../../widgets/cached_profile_image.dart';
import '../../widgets/toast.dart';
import '../attendance/face_registration_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployeeById(widget.employeeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.adminEmployeeList,
      title: Consumer<EmployeeProvider>(
        builder: (context, provider, child) {
          final employee = provider.selectedEmployee;
          return Text(employee?.fullName ?? 'Employee Details');
        },
      ),
      actions: [
        Consumer<EmployeeProvider>(
          builder: (context, provider, child) {
            final employee = provider.selectedEmployee;
            if (employee == null) return const SizedBox.shrink();
            
            return IconButton(
              icon: const Icon(Icons.face),
              tooltip: 'Register Face',
              onPressed: () {
                final navigatorContext = context;
                Navigator.push(
                  navigatorContext,
                  MaterialPageRoute(
                    builder: (context) => FaceRegistrationScreen(
                      employeeId: employee.employeeId,
                    ),
                  ),
                ).then((success) {
                  if (success == true && navigatorContext.mounted) {
                    Toast.success(navigatorContext, 'Face registered successfully!');
                  }
                });
              },
            );
          },
        ),
      ],
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Personal'),
              Tab(text: 'Contact'),
              Tab(text: 'Work'),
              Tab(text: 'Salary'),
              Tab(text: 'Documents'),
            ],
          ),
          Expanded(
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
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
              _buildWorkTab(employee),
              _buildSalaryTab(employee),
              _buildDocumentsTab(employee),
            ],
          );
        },
      ),
          ),
        ],
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
            child: CachedProfileImageLarge(
              imageUrl: employee.profilePhotoUrl,
              fallbackInitials: employee.firstName,
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          // Register Face Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                final navigatorContext = context;
                Navigator.push(
                  navigatorContext,
                  MaterialPageRoute(
                    builder: (context) => FaceRegistrationScreen(
                      employeeId: employee.employeeId,
                    ),
                  ),
                ).then((success) {
                  if (success == true && navigatorContext.mounted) {
                    Toast.success(navigatorContext, 'Face registered successfully!');
                  }
                });
              },
              icon: const Icon(Icons.face),
              label: const Text('Register Face'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
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
            _buildDetailRow('Aadhar Number', employee.aadharNumber),
            _buildDetailRow('PAN Number', employee.panNumber),
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
          const SizedBox(height: 16),
          _buildDetailCard([
            if (employee.emergencyContactName != null)
              _buildDetailRow(
                'Emergency Contact Name',
                employee.emergencyContactName!,
              ),
            if (employee.emergencyContactPhone != null)
              _buildDetailRow(
                'Emergency Contact Phone',
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
            if (employee.totalSalary != null)
              _buildDetailRow(
                'Total Salary',
                '₹${employee.totalSalary!.toStringAsFixed(2)}',
                isTotal: true,
              ),
          ]),
          const SizedBox(height: 16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: url != null
            ? Icon(Icons.check_circle, color: AppTheme.statusApproved)
            : Icon(Icons.cancel, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: url != null
            ? () {
                // TODO: Open document viewer
                Toast.info(context, 'Opening $label...');
              }
            : null,
      ),
    );
  }
}


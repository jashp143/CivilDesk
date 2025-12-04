import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/salary_slip_provider.dart';
import '../../models/salary_slip.dart';
import '../../widgets/employee_layout.dart';

class MySalarySlipsScreen extends StatefulWidget {
  const MySalarySlipsScreen({super.key});

  @override
  State<MySalarySlipsScreen> createState() => _MySalarySlipsScreenState();
}

class _MySalarySlipsScreenState extends State<MySalarySlipsScreen> {
  int? _selectedYear;
  int? _selectedMonth;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Default to current year
    _selectedYear = DateTime.now().year;
    _selectedStatus = 'All';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSalarySlips();
    });
  }

  Future<void> _loadSalarySlips() async {
    final provider = Provider.of<SalarySlipProvider>(context, listen: false);
    await provider.fetchMySalarySlips(
      year: _selectedYear,
      month: _selectedMonth,
      status: _selectedStatus == 'All' ? null : _selectedStatus,
    );
  }

  List<String> _getMonthNames() {
    return [
      'All',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
  }

  List<int> _getYearList() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalarySlipProvider>(context);

    return EmployeeLayout(
      currentRoute: AppRoutes.mySalarySlips,
      title: const Text('My Salary Slips'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(),
          tooltip: 'Filter',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadSalarySlips,
          tooltip: 'Refresh',
        ),
      ],
      child: Column(
        children: [
          // Filter Summary
          if (_selectedYear != null || _selectedMonth != null || _selectedStatus != 'All')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_selectedYear != null)
                          Chip(
                            label: Text('Year: $_selectedYear'),
                            onDeleted: () {
                              setState(() {
                                _selectedYear = null;
                              });
                              _loadSalarySlips();
                            },
                          ),
                        if (_selectedMonth != null)
                          Chip(
                            label: Text('Month: ${_getMonthNames()[_selectedMonth!]}'),
                            onDeleted: () {
                              setState(() {
                                _selectedMonth = null;
                              });
                              _loadSalarySlips();
                            },
                          ),
                        if (_selectedStatus != 'All')
                          Chip(
                            label: Text('Status: $_selectedStatus'),
                            onDeleted: () {
                              setState(() {
                                _selectedStatus = 'All';
                              });
                              _loadSalarySlips();
                            },
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedYear = DateTime.now().year;
                        _selectedMonth = null;
                        _selectedStatus = 'All';
                      });
                      _loadSalarySlips();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Salary Slips List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.salarySlips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No salary slips found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Salary slips will appear here once they are finalized by admin/HR',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSalarySlips,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.salarySlips.length,
                          itemBuilder: (context, index) {
                            final slip = provider.salarySlips[index];
                            return _buildSalarySlipCard(slip);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySlipCard(SalarySlip slip) {
    final statusColor = _getStatusColor(slip.status);
    final statusLabel = _getStatusLabel(slip.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showSalarySlipDetails(slip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slip.periodString,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getMonthName(slip.month)} ${slip.year}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      statusLabel,
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
                    child: _buildInfoItem(
                      'Net Salary',
                      _formatCurrency(slip.netSalary ?? 0),
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Total Earnings',
                      _formatCurrency(slip.totalEarnings ?? 0),
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Total Deductions',
                      _formatCurrency(slip.totalDeductions ?? 0),
                      Icons.trending_down,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Present Days',
                      '${slip.presentDays ?? 0}',
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'FINALIZED':
        return Colors.green;
      case 'PAID':
        return Colors.blue;
      case 'DRAFT':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'FINALIZED':
        return 'Finalized';
      case 'PAID':
        return 'Paid';
      case 'DRAFT':
        return 'Draft';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getMonthName(int month) {
    return _getMonthNames()[month];
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Salary Slips'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year Filter
              ListTile(
                title: const Text('Year'),
                subtitle: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  items: _getYearList().map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
              ),
              // Month Filter
              ListTile(
                title: const Text('Month'),
                subtitle: DropdownButton<int>(
                  value: _selectedMonth,
                  isExpanded: true,
                  hint: const Text('All Months'),
                  items: List.generate(12, (index) => index + 1).map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(_getMonthNames()[month]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
              ),
              // Status Filter
              ListTile(
                title: const Text('Status'),
                subtitle: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: ['All', 'FINALIZED', 'PAID'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status == 'All' ? 'All' : _getStatusLabel(status)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadSalarySlips();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSalarySlipDetails(SalarySlip slip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Salary Slip Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(slip.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(slip.status),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _getStatusLabel(slip.status),
                        style: TextStyle(
                          color: _getStatusColor(slip.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Period Info
                _buildDetailSection('Period Information', [
                  _buildDetailRow('Period', slip.periodString),
                  _buildDetailRow('Month', '${_getMonthName(slip.month)} ${slip.year}'),
                  _buildDetailRow('Working Days', '${slip.workingDays ?? 0}'),
                  _buildDetailRow('Present Days', '${slip.presentDays ?? 0}'),
                  _buildDetailRow('Absent Days', '${slip.absentDays ?? 0}'),
                ]),
                
                const SizedBox(height: 24),
                
                // Earnings
                _buildDetailSection('Earnings', [
                  _buildDetailRow('Basic Pay', _formatCurrency(slip.basicPay ?? 0)),
                  _buildDetailRow('HRA', _formatCurrency(slip.hraAmount ?? 0)),
                  _buildDetailRow('Medical Allowance', _formatCurrency(slip.medicalAllowance ?? 0)),
                  _buildDetailRow('Conveyance Allowance', _formatCurrency(slip.conveyanceAllowance ?? 0)),
                  _buildDetailRow('Uniform & Safety', _formatCurrency(slip.uniformAndSafetyAllowance ?? 0)),
                  _buildDetailRow('Food Allowance', _formatCurrency(slip.foodAllowance ?? 0)),
                  _buildDetailRow('Special Allowance', _formatCurrency(slip.specialAllowance ?? 0)),
                  _buildDetailRow('Overtime Pay', _formatCurrency(slip.overtimePay ?? 0)),
                  _buildDetailRow('Bonus', _formatCurrency(slip.bonus ?? 0)),
                  _buildDetailRow('Other Incentive', _formatCurrency(slip.otherIncentive ?? 0)),
                  const Divider(),
                  _buildDetailRow('Total Earnings', _formatCurrency(slip.totalEarnings ?? 0),
                      isBold: true, color: Colors.green),
                ]),
                
                const SizedBox(height: 24),
                
                // Deductions
                _buildDetailSection('Deductions', [
                  _buildDetailRow('EPF Employee', _formatCurrency(slip.epfEmployeeDeduction ?? 0)),
                  _buildDetailRow('ESIC', _formatCurrency(slip.esicDeduction ?? 0)),
                  _buildDetailRow('Professional Tax', _formatCurrency(slip.professionalTax ?? 0)),
                  _buildDetailRow('TDS', _formatCurrency(slip.tds ?? 0)),
                  _buildDetailRow('Advance Recovery', _formatCurrency(slip.advanceSalaryRecovery ?? 0)),
                  _buildDetailRow('Loan Recovery', _formatCurrency(slip.loanRecovery ?? 0)),
                  _buildDetailRow('Fuel Advance', _formatCurrency(slip.fuelAdvanceRecovery ?? 0)),
                  _buildDetailRow('Other Deductions', _formatCurrency(slip.otherDeductions ?? 0)),
                  const Divider(),
                  _buildDetailRow('Total Deductions', _formatCurrency(slip.totalDeductions ?? 0),
                      isBold: true, color: Colors.red),
                ]),
                
                const SizedBox(height: 24),
                
                // Net Salary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Salary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _formatCurrency(slip.netSalary ?? 0),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                
                if (slip.notes != null && slip.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildDetailSection('Notes', [
                    Text(
                      slip.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? Colors.black87,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EmployeeLayout(
      currentRoute: AppRoutes.mySalarySlips,
      title: const Text('My Salary Slips'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(),
          tooltip: 'Filter',
        ),
      ],
      child: Column(
        children: [
          // Compact Filter Bar
          if (_selectedYear != null ||
              _selectedMonth != null ||
              _selectedStatus != 'All')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (_selectedYear != null)
                          _buildFilterChip(
                            'Year: $_selectedYear',
                            colorScheme,
                            () {
                              setState(() {
                                _selectedYear = null;
                              });
                              _loadSalarySlips();
                            },
                          ),
                        if (_selectedMonth != null)
                          _buildFilterChip(
                            'Month: ${_getMonthNames()[_selectedMonth!]}',
                            colorScheme,
                            () {
                              setState(() {
                                _selectedMonth = null;
                              });
                              _loadSalarySlips();
                            },
                          ),
                        if (_selectedStatus != 'All')
                          _buildFilterChip(
                            'Status: $_selectedStatus',
                            colorScheme,
                            () {
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Salary Slips List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSalarySlips,
              color: colorScheme.primary,
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.salarySlips.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha:
                                    0.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _selectedYear != null
                                    ? 'No salary slips found for $_selectedYear'
                                    : 'No salary slips found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                ),
                                child: Text(
                                  'Salary slips will appear here once they are finalized by admin/HR',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(6, 6, 6, 6),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(slip.status, colorScheme);
    final statusLabel = _getStatusLabel(slip.status);
    final successColor = _getSuccessColor(colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Month + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${_getMonthName(slip.month)} ${slip.year}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Net Salary Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NET SALARY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(slip.netSalary ?? 0),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics - Clean List Style
            _buildMetricRow(
              'Total Earnings',
              _formatCurrency(slip.totalEarnings ?? 0),
              colorScheme,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Total Deductions',
              _formatCurrency(slip.totalDeductions ?? 0),
              colorScheme,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Present Days',
              '${slip.presentDays ?? 0}',
              colorScheme,
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSalarySlipDetails(slip),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View Slip'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadSalarySlip(slip),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ColorScheme colorScheme,
    VoidCallback onDeleted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              Icons.close,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    switch (status.toUpperCase()) {
      case 'FINALIZED':
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case 'PAID':
        return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
      case 'DRAFT':
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      case 'CANCELLED':
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _getSuccessColor(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
  }

  Color _getErrorColor(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? const Color(0xFFE57373)
        : const Color(0xFFC62828);
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

  void _downloadSalarySlip(SalarySlip slip) {
    // TODO: Implement PDF download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download functionality will be implemented soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilterDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.filter_list_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Filter Salary Slips'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year Filter
              Text(
                'Year',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              const SizedBox(height: 16),
              // Month Filter
              Text(
                'Month',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedMonth,
                isExpanded: true,
                hint: const Text('All Months'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              const SizedBox(height: 16),
              // Status Filter
              Text(
                'Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['All', 'FINALIZED', 'PAID'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status == 'All' ? 'All' : _getStatusLabel(status),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(slip.status, colorScheme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _getStatusLabel(slip.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Period Info
                _buildDetailSection('Period Information', [
                  _buildDetailRow('Period', slip.periodString),
                  _buildDetailRow(
                    'Month',
                    '${_getMonthName(slip.month)} ${slip.year}',
                  ),
                  _buildDetailRow('Working Days', '${slip.workingDays ?? 0}'),
                  _buildDetailRow('Present Days', '${slip.presentDays ?? 0}'),
                  _buildDetailRow('Absent Days', '${slip.absentDays ?? 0}'),
                ]),

                const SizedBox(height: 24),

                // Earnings
                _buildDetailSection('Earnings', [
                  _buildDetailRow(
                    'Basic Pay',
                    _formatCurrency(slip.basicPay ?? 0),
                  ),
                  _buildDetailRow('HRA', _formatCurrency(slip.hraAmount ?? 0)),
                  _buildDetailRow(
                    'Medical Allowance',
                    _formatCurrency(slip.medicalAllowance ?? 0),
                  ),
                  _buildDetailRow(
                    'Conveyance Allowance',
                    _formatCurrency(slip.conveyanceAllowance ?? 0),
                  ),
                  _buildDetailRow(
                    'Uniform & Safety',
                    _formatCurrency(slip.uniformAndSafetyAllowance ?? 0),
                  ),
                  _buildDetailRow(
                    'Food Allowance',
                    _formatCurrency(slip.foodAllowance ?? 0),
                  ),
                  _buildDetailRow(
                    'Special Allowance',
                    _formatCurrency(slip.specialAllowance ?? 0),
                  ),
                  _buildDetailRow(
                    'Overtime Pay',
                    _formatCurrency(slip.overtimePay ?? 0),
                  ),
                  _buildDetailRow('Bonus', _formatCurrency(slip.bonus ?? 0)),
                  _buildDetailRow(
                    'Other Incentive',
                    _formatCurrency(slip.otherIncentive ?? 0),
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Total Earnings',
                    _formatCurrency(slip.totalEarnings ?? 0),
                    isBold: true,
                    color: _getSuccessColor(Theme.of(context).colorScheme),
                  ),
                ]),

                const SizedBox(height: 24),

                // Deductions
                _buildDetailSection('Deductions', [
                  _buildDetailRow(
                    'EPF Employee',
                    _formatCurrency(slip.epfEmployeeDeduction ?? 0),
                  ),
                  _buildDetailRow(
                    'ESIC',
                    _formatCurrency(slip.esicDeduction ?? 0),
                  ),
                  _buildDetailRow(
                    'Professional Tax',
                    _formatCurrency(slip.professionalTax ?? 0),
                  ),
                  _buildDetailRow('TDS', _formatCurrency(slip.tds ?? 0)),
                  _buildDetailRow(
                    'Advance Recovery',
                    _formatCurrency(slip.advanceSalaryRecovery ?? 0),
                  ),
                  _buildDetailRow(
                    'Loan Recovery',
                    _formatCurrency(slip.loanRecovery ?? 0),
                  ),
                  _buildDetailRow(
                    'Fuel Advance',
                    _formatCurrency(slip.fuelAdvanceRecovery ?? 0),
                  ),
                  _buildDetailRow(
                    'Other Deductions',
                    _formatCurrency(slip.otherDeductions ?? 0),
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Total Deductions',
                    _formatCurrency(slip.totalDeductions ?? 0),
                    isBold: true,
                    color: _getErrorColor(Theme.of(context).colorScheme),
                  ),
                ]),

                const SizedBox(height: 24),

                // Net Salary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getSuccessColor(colorScheme).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getSuccessColor(colorScheme).withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Salary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatCurrency(slip.netSalary ?? 0),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: _getSuccessColor(colorScheme),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? colorScheme.onSurface,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/salary_slip.dart';
import '../../core/services/salary_service.dart';
import '../../widgets/admin_layout.dart';

class SalarySlipDetailScreen extends StatelessWidget {
  final SalarySlip salarySlip;
  final SalaryService _salaryService = SalaryService();

  SalarySlipDetailScreen({super.key, required this.salarySlip});

  Future<void> _finalizeSlip(BuildContext context) async {
    if (salarySlip.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Salary Slip'),
        content: const Text(
          'Are you sure you want to finalize this salary slip? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _salaryService.finalizeSalarySlip(salarySlip.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salary slip finalized successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to finalize: ${e.toString()}'),
              backgroundColor: Colors.red,
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
    final currencyFormat = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: Text('Salary Slip - ${salarySlip.periodString}'),
        actions: [
          if (salarySlip.status == 'DRAFT')
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Finalize',
              onPressed: () => _finalizeSlip(context),
            ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: () {
              // TODO: Implement print functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                                salarySlip.employeeName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${salarySlip.employeeId}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (salarySlip.department != null)
                                Text(
                                  '${salarySlip.department}${salarySlip.designation != null ? " - ${salarySlip.designation}" : ""}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(salarySlip.status),
                          backgroundColor: salarySlip.status == 'FINALIZED'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      'Period: ${salarySlip.periodString}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Calendar & Attendance Summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendar & Attendance Summary',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Working Days',
                            value: '${salarySlip.workingDays ?? 0}',
                            icon: Icons.calendar_today,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Present Days',
                            value: '${salarySlip.presentDays ?? 0}',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Absent Days',
                            value: '${salarySlip.absentDays ?? 0}',
                            icon: Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Working Hours',
                            value: '${(salarySlip.totalEffectiveWorkingHours ?? 0).toStringAsFixed(1)}h',
                            icon: Icons.access_time,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Overtime Hours',
                            value: '${(salarySlip.totalOvertimeHours ?? 0).toStringAsFixed(1)}h',
                            icon: Icons.schedule,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Proration Factor',
                            value: '${((salarySlip.prorationFactor ?? 0) * 100).toStringAsFixed(1)}%',
                            icon: Icons.percent,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Earnings Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Earnings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _EarningRow('Basic Pay', salarySlip.basicPay, currencyFormat),
                    _EarningRow('HRA', salarySlip.hraAmount, currencyFormat),
                    _EarningRow('Medical Allowance', salarySlip.medicalAllowance, currencyFormat),
                    _EarningRow('Conveyance Allowance', salarySlip.conveyanceAllowance, currencyFormat),
                    _EarningRow('Uniform & Safety', salarySlip.uniformAndSafetyAllowance, currencyFormat),
                    _EarningRow('Bonus', salarySlip.bonus, currencyFormat),
                    _EarningRow('Food Allowance', salarySlip.foodAllowance, currencyFormat),
                    _EarningRow('Special Allowance', salarySlip.specialAllowance, currencyFormat),
                    _EarningRow('Overtime Pay', salarySlip.overtimePay, currencyFormat),
                    _EarningRow('Other Incentive', salarySlip.otherIncentive, currencyFormat),
                    _EarningRow('EPF Employer', salarySlip.epfEmployerEarnings, currencyFormat),
                    const Divider(height: 32),
                    _TotalRow('Total Earnings', salarySlip.totalEarnings, currencyFormat, Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Deductions Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_down, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Deductions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Statutory Deductions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DeductionRow('EPF Employee', salarySlip.epfEmployeeDeduction, currencyFormat),
                    _DeductionRow('EPF Employer', salarySlip.epfEmployerDeduction, currencyFormat),
                    _DeductionRow('ESIC', salarySlip.esicDeduction, currencyFormat),
                    _DeductionRow('Professional Tax', salarySlip.professionalTax, currencyFormat),
                    const SizedBox(height: 16),
                    Text(
                      'Other Deductions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DeductionRow('TDS', salarySlip.tds, currencyFormat),
                    _DeductionRow('Advance Salary Recovery', salarySlip.advanceSalaryRecovery, currencyFormat),
                    _DeductionRow('Loan Recovery', salarySlip.loanRecovery, currencyFormat),
                    _DeductionRow('Fuel Advance Recovery', salarySlip.fuelAdvanceRecovery, currencyFormat),
                    _DeductionRow('Other Deductions', salarySlip.otherDeductions, currencyFormat),
                    const Divider(height: 32),
                    _TotalRow('Total Deductions', salarySlip.totalDeductions, currencyFormat, Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Net Salary Card
            Card(
              elevation: 4,
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Salary',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${currencyFormat.format(salarySlip.netSalary ?? 0)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rates Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rates',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow('Daily Rate', '₹${currencyFormat.format(salarySlip.dailyRate ?? 0)}'),
                    _InfoRow('Hourly Rate', '₹${currencyFormat.format(salarySlip.hourlyRate ?? 0)}'),
                    _InfoRow('Overtime Rate', '₹${currencyFormat.format(salarySlip.overtimeRate ?? 0)}'),
                  ],
                ),
              ),
            ),

            if (salarySlip.notes != null && salarySlip.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(salarySlip.notes!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  final String label;
  final double? amount;
  final NumberFormat format;

  const _EarningRow(this.label, this.amount, this.format);

  @override
  Widget build(BuildContext context) {
    if (amount == null || amount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '₹${format.format(amount!)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _DeductionRow extends StatelessWidget {
  final String label;
  final double? amount;
  final NumberFormat format;

  const _DeductionRow(this.label, this.amount, this.format);

  @override
  Widget build(BuildContext context) {
    if (amount == null || amount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '₹${format.format(amount!)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double? amount;
  final NumberFormat format;
  final Color color;

  const _TotalRow(this.label, this.amount, this.format, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '₹${format.format(amount ?? 0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}


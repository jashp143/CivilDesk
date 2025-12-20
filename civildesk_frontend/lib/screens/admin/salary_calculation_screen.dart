import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/services/salary_service.dart';
import '../../models/employee.dart';
import '../../models/salary_slip.dart';
import '../../widgets/admin_layout.dart';
import 'salary_slip_detail_screen.dart';

class SalaryCalculationScreen extends StatefulWidget {
  const SalaryCalculationScreen({super.key});

  @override
  State<SalaryCalculationScreen> createState() =>
      _SalaryCalculationScreenState();
}

class _SalaryCalculationScreenState extends State<SalaryCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  final SalaryService _salaryService = SalaryService();

  Employee? _selectedEmployee;
  DateTime _selectedDate = DateTime.now();
  bool _isCalculating = false;
  String? _errorMessage;

  // Optional deduction fields
  final TextEditingController _tdsController = TextEditingController();
  final TextEditingController _advanceSalaryController =
      TextEditingController();
  final TextEditingController _loanRecoveryController = TextEditingController();
  final TextEditingController _fuelAdvanceController = TextEditingController();
  final TextEditingController _otherDeductionsController =
      TextEditingController();
  final TextEditingController _otherIncentiveController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _tdsController.dispose();
    _advanceSalaryController.dispose();
    _loanRecoveryController.dispose();
    _fuelAdvanceController.dispose();
    _otherDeductionsController.dispose();
    _otherIncentiveController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _calculateSalary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
    });

    try {
      final request = SalaryCalculationRequest(
        employeeId: _selectedEmployee!.employeeId,
        year: _selectedDate.year,
        month: _selectedDate.month,
        tds: _tdsController.text.isNotEmpty
            ? double.tryParse(_tdsController.text)
            : null,
        advanceSalaryRecovery: _advanceSalaryController.text.isNotEmpty
            ? double.tryParse(_advanceSalaryController.text)
            : null,
        loanRecovery: _loanRecoveryController.text.isNotEmpty
            ? double.tryParse(_loanRecoveryController.text)
            : null,
        fuelAdvanceRecovery: _fuelAdvanceController.text.isNotEmpty
            ? double.tryParse(_fuelAdvanceController.text)
            : null,
        otherDeductions: _otherDeductionsController.text.isNotEmpty
            ? double.tryParse(_otherDeductionsController.text)
            : null,
        otherIncentive: _otherIncentiveController.text.isNotEmpty
            ? double.tryParse(_otherIncentiveController.text)
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final salarySlip = await _salaryService.calculateAndGenerateSlip(request);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SalarySlipDetailScreen(salarySlip: salarySlip),
          ),
        ).then((_) {
          // Clear form after successful calculation
          _clearForm();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Failed to calculate salary'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }

  void _clearForm() {
    _tdsController.clear();
    _advanceSalaryController.clear();
    _loanRecoveryController.clear();
    _fuelAdvanceController.clear();
    _otherDeductionsController.clear();
    _otherIncentiveController.clear();
    _notesController.clear();
    setState(() {
      _selectedEmployee = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminLayout(
      currentRoute: AppRoutes.adminSalaryCalculation,
      title: const Text('Salary Calculation'),
      child: RefreshIndicator(
        onRefresh: () async {
          final provider = Provider.of<EmployeeProvider>(
            context,
            listen: false,
          );
          await provider.loadEmployees(refresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Employee Selection Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employee Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer<EmployeeProvider>(
                          builder: (context, provider, _) {
                            return DropdownButtonFormField<Employee>(
                              initialValue: _selectedEmployee,
                              decoration: const InputDecoration(
                                labelText: 'Select Employee *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: provider.employees.map((employee) {
                                return DropdownMenuItem<Employee>(
                                  value: employee,
                                  child: Text(
                                    '${employee.firstName} ${employee.lastName} (${employee.employeeId})',
                                  ),
                                );
                              }).toList(),
                              onChanged: (employee) {
                                setState(() {
                                  _selectedEmployee = employee;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select an employee';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        if (_selectedEmployee != null) ...[
                          const SizedBox(height: 16),
                          _InfoRow(
                            label: 'Department',
                            value: _selectedEmployee!.department ?? 'N/A',
                          ),
                          _InfoRow(
                            label: 'Designation',
                            value: _selectedEmployee!.designation ?? 'N/A',
                          ),
                          _InfoRow(
                            label: 'Basic Salary',
                            value:
                                '₹${NumberFormat('#,##0.00').format(_selectedEmployee!.basicSalary ?? 0)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Period Selection Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salary Period',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Select Month & Year *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              DateFormat('MMMM yyyy').format(_selectedDate),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Optional Deductions Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Optional Deductions & Incentives',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Leave blank if not applicable. These fields are optional.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tdsController,
                                decoration: const InputDecoration(
                                  labelText: 'TDS',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.account_balance),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount < 0) {
                                      return 'Enter a valid amount';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _otherIncentiveController,
                                decoration: const InputDecoration(
                                  labelText: 'Other Incentive',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.card_giftcard),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount < 0) {
                                      return 'Enter a valid amount';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _advanceSalaryController,
                          decoration: const InputDecoration(
                            labelText: 'Advance Salary Recovery',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.money_off),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null || amount < 0) {
                                return 'Enter a valid amount';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _loanRecoveryController,
                          decoration: const InputDecoration(
                            labelText: 'Loan Recovery',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null || amount < 0) {
                                return 'Enter a valid amount';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _fuelAdvanceController,
                                decoration: const InputDecoration(
                                  labelText: 'Fuel Advance Recovery',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.local_gas_station),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount < 0) {
                                      return 'Enter a valid amount';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _otherDeductionsController,
                                decoration: const InputDecoration(
                                  labelText: 'Other Deductions',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.remove_circle_outline),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount < 0) {
                                      return 'Enter a valid amount';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Calculate Button
                ElevatedButton.icon(
                  onPressed: _isCalculating ? null : _calculateSalary,
                  icon: _isCalculating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate),
                  label: Text(
                    _isCalculating ? 'Calculating...' : 'Calculate Salary',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

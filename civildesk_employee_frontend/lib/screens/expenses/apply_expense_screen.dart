import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../core/providers/expense_provider.dart';

class ApplyExpenseScreen extends StatefulWidget {
  final Expense? existingExpense; // For editing existing expense

  const ApplyExpenseScreen({Key? key, this.existingExpense}) : super(key: key);

  @override
  State<ApplyExpenseScreen> createState() => _ApplyExpenseScreenState();
}

class _ApplyExpenseScreenState extends State<ApplyExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  // Form fields
  DateTime? _expenseDate;
  ExpenseCategory? _selectedCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<String> _receiptUrls = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // If editing, populate fields
    if (widget.existingExpense != null) {
      _populateFields();
    } else {
      _expenseDate = DateTime.now();
    }
  }

  void _populateFields() {
    final expense = widget.existingExpense!;
    setState(() {
      _expenseDate = expense.expenseDate;
      _selectedCategory = expense.category;
      _amountController.text = expense.amount.toString();
      _descriptionController.text = expense.description;
      _receiptUrls = expense.receiptUrls ?? [];
    });
  }

  Future<void> _pickReceipts() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        final List<String> uploadedUrls = [];
        
        for (var file in result.files) {
          if (file.path != null) {
            final url = await expenseProvider.uploadReceipt(file.path!);
            if (url != null) {
              uploadedUrls.add(url);
            }
          }
        }
        
        if (uploadedUrls.isNotEmpty) {
          setState(() {
            _receiptUrls.addAll(uploadedUrls);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${uploadedUrls.length} receipt(s) uploaded successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload receipt: $e')),
        );
      }
    }
  }

  void _removeReceipt(int index) {
    setState(() {
      _receiptUrls.removeAt(index);
    });
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expenseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expense date')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expense category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final request = ExpenseRequest(
      expenseDate: _expenseDate!,
      category: _selectedCategory!,
      amount: double.parse(_amountController.text.trim()),
      description: _descriptionController.text.trim(),
      receiptUrls: _receiptUrls.isEmpty ? null : _receiptUrls,
    );

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    bool success;

    if (widget.existingExpense != null) {
      success = await expenseProvider.updateExpense(widget.existingExpense!.id, request);
    } else {
      success = await expenseProvider.applyExpense(request);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingExpense != null 
              ? 'Expense updated successfully' 
              : 'Expense application submitted successfully'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(expenseProvider.error ?? 'Failed to submit expense')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingExpense != null ? 'Edit Expense' : 'Apply for Expense'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpenseDateField(),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildReceiptsSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseDateField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _expenseDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _expenseDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Expense Date *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: const Icon(Icons.calendar_today),
          errorText: _expenseDate == null && _formKey.currentState?.validate() == false
              ? 'Required'
              : null,
        ),
        child: Text(
          _expenseDate != null
              ? DateFormat('dd MMM yyyy').format(_expenseDate!)
              : 'Select date',
          style: TextStyle(
            color: _expenseDate != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ExpenseCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.category),
      ),
      items: ExpenseCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCategory = value);
      },
      validator: (value) => value == null ? 'Please select category' : null,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.currency_rupee),
        hintText: '0.00',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Amount is required';
        }
        final amount = double.tryParse(value.trim());
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.description),
        hintText: 'Enter expense description',
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        return null;
      },
    );
  }

  Widget _buildReceiptsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickReceipts,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Receipts'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (_receiptUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...List.generate(_receiptUrls.length, (index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.receipt),
                title: Text('Receipt ${index + 1}'),
                subtitle: Text(_receiptUrls[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeReceipt(index),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitExpense,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                widget.existingExpense != null ? 'Update Expense' : 'Submit Expense',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

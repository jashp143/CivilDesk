import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _selectedStatus;
  String? _selectedCategory;
  String? _selectedDepartment;
  List<String> _departments = [];

  List<Expense> get expenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedStatus => _selectedStatus;
  String? get selectedCategory => _selectedCategory;
  String? get selectedDepartment => _selectedDepartment;
  List<String> get departments => _departments;

  // Fetch all expenses
  Future<void> fetchAllExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _expenseService.getAllExpenses(
        status: _selectedStatus,
        category: _selectedCategory,
        department: _selectedDepartment,
      );
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Apply filters
  void _applyFilters() {
    _filteredExpenses = List.from(_expenses);

    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      final status = ExpenseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedStatus,
      );
      _filteredExpenses = _filteredExpenses.where((expense) => expense.status == status).toList();
    }

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      final category = ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedCategory,
      );
      _filteredExpenses = _filteredExpenses.where((expense) => expense.category == category).toList();
    }

    if (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) {
      _filteredExpenses = _filteredExpenses
          .where((expense) => expense.department == _selectedDepartment)
          .toList();
    }

    // Extract unique departments for filter dropdown
    _departments = _expenses
        .where((expense) => expense.department != null && expense.department!.isNotEmpty)
        .map((expense) => expense.department!)
        .toSet()
        .toList();
    _departments.sort();
  }

  // Set status filter
  void setStatusFilter(String? status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  // Set category filter
  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Set department filter
  void setDepartmentFilter(String? department) {
    _selectedDepartment = department;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _selectedStatus = null;
    _selectedCategory = null;
    _selectedDepartment = null;
    _applyFilters();
    notifyListeners();
  }

  // Review expense
  Future<bool> reviewExpense(int expenseId, ExpenseStatus status, String? note) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = ExpenseReviewRequest(status: status, reviewNote: note);
      await _expenseService.reviewExpense(expenseId, request);
      await fetchAllExpenses(); // Refresh expenses list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

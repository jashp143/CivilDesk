import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Apply for expense
  Future<bool> applyExpense(ExpenseRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _expenseService.applyExpense(request);
      await fetchMyExpenses(); // Refresh expenses list
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

  // Update expense
  Future<bool> updateExpense(int expenseId, ExpenseRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _expenseService.updateExpense(expenseId, request);
      await fetchMyExpenses(); // Refresh expenses list
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

  // Delete expense
  Future<bool> deleteExpense(int expenseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _expenseService.deleteExpense(expenseId);
      await fetchMyExpenses(); // Refresh expenses list
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

  // Fetch my expenses
  Future<void> fetchMyExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _expenseService.getMyExpenses();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload receipt
  Future<String?> uploadReceipt(String filePath) async {
    try {
      return await _expenseService.uploadReceipt(filePath);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

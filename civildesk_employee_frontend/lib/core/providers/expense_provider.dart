import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  final int _pageSize = 20;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;

  // Apply for expense
  Future<bool> applyExpense(ExpenseRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _expenseService.applyExpense(request);
      await refreshExpenses(); // Refresh expenses list
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
      await refreshExpenses(); // Refresh expenses list
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
      _expenses.removeWhere((expense) => expense.id == expenseId);
      _totalElements--;
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

  // Fetch my expenses (with pagination support)
  Future<void> fetchMyExpenses({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _expenses.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageResponse = await _expenseService.getMyExpensesPaginated(
        page: _currentPage,
        size: _pageSize,
      );

      if (refresh || _currentPage == 0) {
        _expenses = pageResponse.content;
      } else {
        _expenses.addAll(pageResponse.content);
      }

      _currentPage = pageResponse.number;
      _totalPages = pageResponse.totalPages;
      _totalElements = pageResponse.totalElements;
      _hasMore = pageResponse.hasMore;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more expenses (next page)
  Future<void> loadMoreExpenses() async {
    if (!_hasMore || _isLoading) return;
    await fetchMyExpenses(refresh: false);
  }

  // Refresh expenses (reload from beginning)
  Future<void> refreshExpenses() async {
    await fetchMyExpenses(refresh: true);
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

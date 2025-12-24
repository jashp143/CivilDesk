import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  bool _isInitialLoad = true; // Track if this is the first load

  // Filters
  String? _selectedStatus;
  String? _selectedCategory;
  String? _selectedDepartment;
  List<String> _departments = [];

  List<Expense> get expenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;
  String? get selectedStatus => _selectedStatus;
  String? get selectedCategory => _selectedCategory;
  String? get selectedDepartment => _selectedDepartment;
  List<String> get departments => _departments;

  // Use consistent page size of 15
  int _getPageSize() {
    return 15;
  }

  // Fetch all expenses (with pagination support)
  Future<void> fetchAllExpenses({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _expenses.clear();
      _hasMore = true;
      _isInitialLoad = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageSize = _getPageSize();
      // Use next page number when loading more
      final pageToLoad = refresh ? 0 : _currentPage + 1;
      final pageResponse = await _expenseService.getAllExpensesPaginated(
        status: _selectedStatus,
        category: _selectedCategory,
        department: _selectedDepartment,
        page: pageToLoad,
        size: pageSize,
      );

      if (refresh || pageToLoad == 0) {
        _expenses = pageResponse.content;
      } else {
        _expenses.addAll(pageResponse.content);
      }

      _currentPage = pageResponse.number;
      _totalPages = pageResponse.totalPages;
      _totalElements = pageResponse.totalElements;
      _hasMore = pageResponse.hasMore;
      _isInitialLoad = false;

      _applyFilters();
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
    await fetchAllExpenses(refresh: false);
  }

  // Refresh expenses (reload from beginning)
  Future<void> refreshExpenses() async {
    await fetchAllExpenses(refresh: true);
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
    refreshExpenses(); // Reload with new filter
  }

  // Set category filter
  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    refreshExpenses(); // Reload with new filter
  }

  // Set department filter
  void setDepartmentFilter(String? department) {
    _selectedDepartment = department;
    refreshExpenses(); // Reload with new filter
  }

  // Clear all filters
  void clearFilters() {
    _selectedStatus = null;
    _selectedCategory = null;
    _selectedDepartment = null;
    refreshExpenses(); // Reload without filters
  }

  // Review expense
  Future<bool> reviewExpense(int expenseId, ExpenseStatus status, String? note) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = ExpenseReviewRequest(status: status, reviewNote: note);
      await _expenseService.reviewExpense(expenseId, request);
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

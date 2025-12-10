import 'package:dio/dio.dart';
import '../../models/expense.dart';
import 'api_service.dart';

class ExpenseService {
  final ApiService _apiService = ApiService();

  // Get all expenses
  Future<List<Expense>> getAllExpenses({
    String? status,
    String? category,
    String? department,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }

      final response = await _apiService.get(
        '/expenses',
        queryParameters: queryParams,
      );

      if (response.data['success']) {
        final List<dynamic> expensesJson = response.data['data'];
        return expensesJson.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch expenses');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch expenses');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get expense by ID
  Future<Expense> getExpenseById(int expenseId) async {
    try {
      final response = await _apiService.get('/expenses/$expenseId');

      if (response.data['success']) {
        return Expense.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch expense details');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch expense details');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Review expense (Approve/Reject)
  Future<Expense> reviewExpense(int expenseId, ExpenseReviewRequest request) async {
    try {
      final response = await _apiService.put(
        '/expenses/$expenseId/review',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Expense.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to review expense');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to review expense');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get unique departments from expenses
  Future<List<String>> getDepartments() async {
    try {
      final expenses = await getAllExpenses();
      final departments = expenses
          .where((expense) => expense.department != null && expense.department!.isNotEmpty)
          .map((expense) => expense.department!)
          .toSet()
          .toList();
      departments.sort();
      return departments;
    } catch (e) {
      return [];
    }
  }
}

class ExpenseReviewRequest {
  final ExpenseStatus status;
  final String? reviewNote;

  ExpenseReviewRequest({
    required this.status,
    this.reviewNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.toString().split('.').last,
      'reviewNote': reviewNote,
    };
  }
}

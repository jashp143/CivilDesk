import 'package:dio/dio.dart';
import '../../models/expense.dart';
import '../../models/page_response.dart';
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

  // Get all expenses with pagination
  Future<PageResponse<Expense>> getAllExpensesPaginated({
    String? status,
    String? category,
    String? department,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'DESC',
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };
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
        final data = response.data['data'];
        // Check if response is paginated (has 'content' field) or a list
        if (data is Map && data.containsKey('content')) {
          return PageResponse.fromJson(
            data as Map<String, dynamic>,
            (json) => Expense.fromJson(json),
          );
        } else {
          // Fallback for non-paginated response
          final List<dynamic> expensesJson = data as List<dynamic>;
          final expenses = expensesJson.map((json) => Expense.fromJson(json)).toList();
          return PageResponse<Expense>(
            content: expenses,
            totalElements: expenses.length,
            totalPages: 1,
            size: expenses.length,
            number: 0,
            first: true,
            last: true,
          );
        }
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

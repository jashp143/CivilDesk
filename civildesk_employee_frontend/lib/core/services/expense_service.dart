import 'package:dio/dio.dart';
import '../../models/expense.dart';
import '../../models/page_response.dart';
import 'api_service.dart';

class ExpenseService {
  final ApiService _apiService = ApiService();

  // Apply for expense
  Future<Expense> applyExpense(ExpenseRequest request) async {
    try {
      final response = await _apiService.post(
        '/expenses',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Expense.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to apply for expense');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to apply for expense');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Update expense
  Future<Expense> updateExpense(int expenseId, ExpenseRequest request) async {
    try {
      final response = await _apiService.put(
        '/expenses/$expenseId',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return Expense.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update expense');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update expense');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Delete expense
  Future<void> deleteExpense(int expenseId) async {
    try {
      final response = await _apiService.delete('/expenses/$expenseId');

      if (!response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to delete expense');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete expense');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get my expenses
  Future<List<Expense>> getMyExpenses() async {
    try {
      final response = await _apiService.get('/expenses/my-expenses');

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

  // Get my expenses with pagination
  Future<PageResponse<Expense>> getMyExpensesPaginated({
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'DESC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };

      final response = await _apiService.get(
        '/expenses/my-expenses',
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

  // Upload receipt
  Future<String> uploadReceipt(String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.post(
        '/api/upload/receipt',
        data: formData,
      );

      if (response.data['success']) {
        return response.data['data']['url'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload receipt');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to upload receipt');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get expense categories
  Future<List<String>> getExpenseCategories() async {
    try {
      final response = await _apiService.get('/expenses/categories');

      if (response.data['success']) {
        final List<dynamic> categoriesJson = response.data['data'];
        return categoriesJson.map((e) => e.toString()).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch categories');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch categories');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

import 'package:dio/dio.dart';
import '../../models/expense.dart';
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

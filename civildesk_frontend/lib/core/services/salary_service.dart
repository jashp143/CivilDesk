import 'package:dio/dio.dart';
import '../../models/salary_slip.dart';
import 'api_service.dart';

class SalaryService {
  final ApiService _apiService = ApiService();
  static const String _basePath = '/salary';

  Future<SalarySlip> calculateAndGenerateSlip(SalaryCalculationRequest request) async {
    try {
      final response = await _apiService.post(
        '$_basePath/calculate',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          if (data['salarySlip'] != null) {
            return SalarySlip.fromJson(data['salarySlip'] as Map<String, dynamic>);
          }
        }
      }
      throw Exception('Failed to calculate salary');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<SalarySlip> getSalarySlipById(int id) async {
    try {
      final response = await _apiService.get('$_basePath/slip/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return SalarySlip.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch salary slip');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<List<SalarySlip>> getEmployeeSalarySlips(String employeeId) async {
    try {
      final response = await _apiService.get('$_basePath/employee/$employeeId');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as List<dynamic>;
          return data.map((json) => SalarySlip.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      throw Exception('Failed to fetch employee salary slips');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<SalarySlip> getSalarySlipByPeriod(String employeeId, int year, int month) async {
    try {
      final response = await _apiService.get(
        '$_basePath/employee/$employeeId/period',
        queryParameters: {'year': year, 'month': month},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return SalarySlip.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch salary slip');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<List<SalarySlip>> getAllSalarySlips({int? year, int? month}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (year != null) queryParams['year'] = year;
      if (month != null) queryParams['month'] = month;

      final response = await _apiService.get(
        '$_basePath/all',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as List<dynamic>;
          return data.map((json) => SalarySlip.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      throw Exception('Failed to fetch salary slips');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<SalarySlip> finalizeSalarySlip(int id) async {
    try {
      final response = await _apiService.put('$_basePath/slip/$id/finalize');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return SalarySlip.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to finalize salary slip');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<bool> deleteSalarySlip(int id) async {
    try {
      final response = await _apiService.delete('$_basePath/slip/$id');

      if (response.statusCode == 200) {
        return true;
      }
      throw Exception('Failed to delete salary slip');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'] as String;
      }
      return 'Error: ${error.response?.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Connection error. Please check your internet connection.';
    }
    return error.message ?? 'An unexpected error occurred';
  }
}


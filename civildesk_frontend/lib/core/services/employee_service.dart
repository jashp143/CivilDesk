import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/employee.dart';
import 'api_service.dart';

class EmployeeService {
  final ApiService _apiService = ApiService();
  static const String _basePath = '/employees';

  Future<Employee> createEmployee(Employee employee) async {
    try {
      final response = await _apiService.post(
        _basePath,
        data: employee.toJson(),
      );

      if (response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return Employee.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to create employee');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<Employee> updateEmployee(int id, Employee employee) async {
    try {
      final response = await _apiService.put(
        '$_basePath/$id',
        data: employee.toJson(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return Employee.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to update employee');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<Employee> getEmployeeById(int id) async {
    try {
      final response = await _apiService.get('$_basePath/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return Employee.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch employee');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<Employee> getEmployeeByEmployeeId(String employeeId) async {
    try {
      final response = await _apiService.get('$_basePath/employee-id/$employeeId');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return Employee.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch employee');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<Employee> getEmployeeByUserId(int userId) async {
    try {
      final response = await _apiService.get('$_basePath/user/$userId');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return Employee.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch employee');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<EmployeeListResponse> getAllEmployees({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
    String sortDir = 'ASC',
  }) async {
    try {
      final response = await _apiService.get(
        _basePath,
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'sortDir': sortDir,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            return EmployeeListResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format: expected Map but got ${data.runtimeType}');
          }
        }
      }
      throw Exception('Failed to fetch employees');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<EmployeeListResponse> searchEmployees({
    String? search,
    String? department,
    String? designation,
    EmploymentStatus? status,
    EmploymentType? type,
    int page = 0,
    int size = 10,
    String sortBy = 'id',
    String sortDir = 'ASC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }
      if (designation != null && designation.isNotEmpty) {
        queryParams['designation'] = designation;
      }
      if (status != null) {
        queryParams['status'] = status.name.toUpperCase().replaceAll('_', '_');
      }
      if (type != null) {
        queryParams['type'] = type.name.toUpperCase().replaceAll('_', '_');
      }

      final response = await _apiService.get(
        '$_basePath/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            return EmployeeListResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format: expected Map but got ${data.runtimeType}');
          }
        }
      }
      throw Exception('Failed to search employees');
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      final response = await _apiService.delete('$_basePath/$id');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete employee');
      }
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  Future<void> generateEmployeeCredentials(int id) async {
    try {
      final response = await _apiService.post(
        '$_basePath/$id/generate-credentials',
        data: {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate employee credentials');
      }
    } catch (e) {
      if (e is DioException) {
        throw _handleError(e);
      }
      rethrow;
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final responseData = error.response!.data;
      if (responseData is Map<String, dynamic>) {
        return responseData['message'] as String? ?? 'An error occurred';
      }
      return 'An error occurred: ${error.response!.statusCode}';
    }
    return 'Network error. Please check your connection.';
  }
}

class EmployeeListResponse {
  final List<Employee> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;

  EmployeeListResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
  });

  factory EmployeeListResponse.fromJson(Map<String, dynamic> json) {
    // Spring Data Page with VIA_DTO mode wraps pagination metadata in a 'page' object
    final pageData = json['page'] as Map<String, dynamic>?;
    
    // Extract pagination data from page object if available, otherwise from top level
    final paginationData = pageData ?? json;
    
    // Calculate first and last if not provided
    final number = paginationData['number'] as int? ?? 0;
    final totalPages = paginationData['totalPages'] as int? ?? 0;
    final first = paginationData['first'] as bool? ?? (number == 0);
    final last = paginationData['last'] as bool? ?? (totalPages > 0 && number >= totalPages - 1);
    
    return EmployeeListResponse(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => Employee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: paginationData['totalElements'] as int? ?? 0,
      totalPages: totalPages,
      size: paginationData['size'] as int? ?? 10,
      number: number,
      first: first,
      last: last,
    );
  }
}


import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/salary_slip.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class SalarySlipProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<SalarySlip> _salarySlips = [];
  SalarySlip? _selectedSalarySlip;
  bool _isLoading = false;
  String? _error;

  List<SalarySlip> get salarySlips => _salarySlips;
  SalarySlip? get selectedSalarySlip => _selectedSalarySlip;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMySalarySlips({
    int? year,
    int? month,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (year != null) queryParams['year'] = year;
      if (month != null) queryParams['month'] = month;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _apiService.get(
        '/salary/my-salary-slips',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          _salarySlips = data
              .map((json) => SalarySlip.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching salary slips: $e');
      if (e is DioException) {
        _error = e.response?.data?['message'] as String? ?? 'Failed to fetch salary slips';
      } else {
        _error = 'Failed to fetch salary slips';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalarySlipById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '/salary/slip/$id',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          _selectedSalarySlip = SalarySlip.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error fetching salary slip: $e');
      if (e is DioException) {
        _error = e.response?.data?['message'] as String? ?? 'Failed to fetch salary slip';
      } else {
        _error = 'Failed to fetch salary slip';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelected() {
    _selectedSalarySlip = null;
    notifyListeners();
  }
}


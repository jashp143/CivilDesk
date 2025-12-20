import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../models/holiday.dart';

class HolidayProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Holiday> _upcomingHolidays = [];
  bool _isLoading = false;
  String? _error;

  List<Holiday> get upcomingHolidays => _upcomingHolidays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUpcomingHolidays() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/holidays/upcoming/public');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        _upcomingHolidays = data.map((json) => Holiday.fromJson(json)).toList();
        _error = null;
      } else {
        _error = response.data['message'] ?? 'Failed to load upcoming holidays';
        _upcomingHolidays = [];
      }
    } catch (e) {
      _error = 'Error loading upcoming holidays: ${e.toString()}';
      _upcomingHolidays = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


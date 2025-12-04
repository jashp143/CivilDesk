import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../models/holiday.dart';

class HolidayProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Holiday> _holidays = [];
  bool _isLoading = false;
  String? _error;

  List<Holiday> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHolidays() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/holidays');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        _holidays = data.map((json) => Holiday.fromJson(json)).toList();
        _error = null;
      } else {
        _error = response.data['message'] ?? 'Failed to load holidays';
        _holidays = [];
      }
    } catch (e) {
      _error = 'Error loading holidays: ${e.toString()}';
      _holidays = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createHoliday(Holiday holiday) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/holidays',
        data: holiday.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadHolidays(); // Reload list
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to create holiday';
        return false;
      }
    } catch (e) {
      _error = 'Error creating holiday: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateHoliday(int id, Holiday holiday) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '/holidays/$id',
        data: holiday.toJson(),
      );

      if (response.statusCode == 200) {
        await loadHolidays(); // Reload list
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to update holiday';
        return false;
      }
    } catch (e) {
      _error = 'Error updating holiday: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteHoliday(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/holidays/$id');

      if (response.statusCode == 200) {
        await loadHolidays(); // Reload list
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to delete holiday';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting holiday: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


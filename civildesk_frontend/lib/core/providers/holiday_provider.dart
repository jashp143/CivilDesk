import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../models/holiday.dart';
import '../../models/page_response.dart';

class HolidayProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Holiday> _holidays = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  bool _isInitialLoad = true; // Track if this is the first load

  List<Holiday> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;

  // Get page size: 25 for first load, 10 for subsequent loads
  int _getPageSize() {
    return _isInitialLoad ? 25 : 10;
  }

  Future<void> loadHolidays({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _holidays.clear();
      _hasMore = true;
      _isInitialLoad = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageSize = _getPageSize();
      final response = await _apiService.get(
        '/holidays',
        queryParameters: {
          'page': _currentPage,
          'size': pageSize,
          'sortBy': 'date',
          'sortDir': 'ASC',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        // Check if response is paginated (has 'content' field) or a list
        if (data is Map && data.containsKey('content')) {
          final pageResponse = PageResponse.fromJson(
            data as Map<String, dynamic>,
            (json) => Holiday.fromJson(json),
          );

          if (refresh || _currentPage == 0) {
            _holidays = pageResponse.content;
          } else {
            _holidays.addAll(pageResponse.content);
          }

          _currentPage = pageResponse.number;
          _totalPages = pageResponse.totalPages;
          _totalElements = pageResponse.totalElements;
          _hasMore = pageResponse.hasMore;
          _isInitialLoad = false;
        } else {
          // Fallback for non-paginated response
          final List<dynamic> holidaysJson = data as List<dynamic>;
          _holidays = holidaysJson.map((json) => Holiday.fromJson(json)).toList();
          _hasMore = false;
          _isInitialLoad = false;
        }
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

  Future<void> loadMoreHolidays() async {
    if (!_hasMore || _isLoading) return;
    await loadHolidays(refresh: false);
  }

  Future<void> refreshHolidays() async {
    await loadHolidays(refresh: true);
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
        await refreshHolidays(); // Reload list
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
        await refreshHolidays(); // Reload list
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
        await refreshHolidays(); // Reload list
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


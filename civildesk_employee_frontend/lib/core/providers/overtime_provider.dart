import 'package:flutter/material.dart';
import '../../models/overtime.dart';
import '../services/overtime_service.dart';

class OvertimeProvider with ChangeNotifier {
  final OvertimeService _overtimeService = OvertimeService();

  List<Overtime> _overtimes = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  final int _pageSize = 20;

  List<Overtime> get overtimes => _overtimes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;

  // Apply for overtime
  Future<bool> applyOvertime(OvertimeRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _overtimeService.applyOvertime(request);
      await refreshOvertimes(); // Refresh overtimes list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update overtime
  Future<bool> updateOvertime(int overtimeId, OvertimeRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _overtimeService.updateOvertime(overtimeId, request);
      await refreshOvertimes(); // Refresh overtimes list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete overtime
  Future<bool> deleteOvertime(int overtimeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _overtimeService.deleteOvertime(overtimeId);
      _overtimes.removeWhere((overtime) => overtime.id == overtimeId);
      _totalElements--;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch my overtimes (with pagination support)
  Future<void> fetchMyOvertimes({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _overtimes.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageResponse = await _overtimeService.getMyOvertimesPaginated(
        page: _currentPage,
        size: _pageSize,
      );

      if (refresh || _currentPage == 0) {
        _overtimes = pageResponse.content;
      } else {
        _overtimes.addAll(pageResponse.content);
      }

      _currentPage = pageResponse.number;
      _totalPages = pageResponse.totalPages;
      _totalElements = pageResponse.totalElements;
      _hasMore = pageResponse.hasMore;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more overtimes (next page)
  Future<void> loadMoreOvertimes() async {
    if (!_hasMore || _isLoading) return;
    await fetchMyOvertimes(refresh: false);
  }

  // Refresh overtimes (reload from beginning)
  Future<void> refreshOvertimes() async {
    await fetchMyOvertimes(refresh: true);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import '../../models/broadcast.dart';
import '../../models/page_response.dart';
import '../services/broadcast_service.dart';

class BroadcastProvider with ChangeNotifier {
  final BroadcastService _broadcastService = BroadcastService();

  List<BroadcastMessage> _broadcasts = [];
  bool _isLoading = false;
  String? _error;

  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  final int _pageSize = 20;

  List<BroadcastMessage> get broadcasts => _broadcasts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;

  // Refresh broadcasts
  Future<void> refreshBroadcasts() async {
    _currentPage = 0;
    _broadcasts = [];
    _hasMore = true;
    await fetchBroadcasts();
  }

  // Fetch broadcasts
  Future<void> fetchBroadcasts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _broadcasts = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _broadcastService.getAllBroadcasts(
        page: _currentPage,
        size: _pageSize,
      );

      if (refresh) {
        _broadcasts = response.content;
      } else {
        _broadcasts.addAll(response.content);
      }

      _currentPage = response.number;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;
      _hasMore = response.hasMore;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more broadcasts
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await fetchBroadcasts();
  }

  // Create broadcast
  Future<bool> createBroadcast({
    required String title,
    required String message,
    required String priority,
    required bool isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _broadcastService.createBroadcast({
        'title': title,
        'message': message,
        'priority': priority,
        'isActive': isActive,
      });

      // Reset loading state before refreshing
      _isLoading = false;
      // Refresh the list to show the new broadcast
      await refreshBroadcasts();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update broadcast
  Future<bool> updateBroadcast({
    required int id,
    required String title,
    required String message,
    required String priority,
    required bool isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _broadcastService.updateBroadcast(id, {
        'title': title,
        'message': message,
        'priority': priority,
        'isActive': isActive,
      });

      // Reset loading state before refreshing
      _isLoading = false;
      // Refresh the list to show the updated broadcast
      await refreshBroadcasts();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete broadcast
  Future<bool> deleteBroadcast(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _broadcastService.deleteBroadcast(id);
      // Reset loading state before refreshing
      _isLoading = false;
      // Refresh the list to remove the deleted broadcast
      await refreshBroadcasts();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}


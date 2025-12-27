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
  bool _hasMore = true;
  final int _pageSize = 20;

  List<BroadcastMessage> get broadcasts => _broadcasts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Refresh broadcasts
  Future<void> refreshBroadcasts() async {
    _currentPage = 0;
    _broadcasts = [];
    _hasMore = true;
    await fetchBroadcasts();
  }

  // Fetch active broadcasts
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
      final response = await _broadcastService.getActiveBroadcasts(
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
}


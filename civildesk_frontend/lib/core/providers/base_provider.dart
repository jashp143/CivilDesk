import 'package:flutter/foundation.dart';
import 'dart:async';

/// Base provider with optimized state management
/// Phase 4 Optimization - State Management
/// 
/// Features:
/// - Debounced state updates
/// - Automatic error handling
/// - Loading state management
/// - Cache invalidation
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Timer? _debounceTimer;
  
  // Cache management
  DateTime? _lastUpdated;
  Duration _cacheDuration = const Duration(minutes: 5);
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isCacheValid {
    if (_lastUpdated == null) return false;
    return DateTime.now().difference(_lastUpdated!) < _cacheDuration;
  }
  
  /// Set loading state
  @protected
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  /// Set error state
  @protected
  void setError(String? errorMessage) {
    if (_error != errorMessage) {
      _error = errorMessage;
      notifyListeners();
    }
  }
  
  /// Clear error
  @protected
  void clearError() {
    setError(null);
  }
  
  /// Update cache timestamp
  @protected
  void updateCache() {
    _lastUpdated = DateTime.now();
  }
  
  /// Invalidate cache
  @protected
  void invalidateCache() {
    _lastUpdated = null;
  }
  
  /// Set cache duration
  @protected
  void setCacheDuration(Duration duration) {
    _cacheDuration = duration;
  }
  
  /// Debounced notify listeners (prevents excessive rebuilds)
  @protected
  void debouncedNotifyListeners({Duration delay = const Duration(milliseconds: 100)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      notifyListeners();
    });
  }
  
  /// Execute async operation with automatic loading/error handling
  @protected
  Future<T?> executeAsync<T>({
    required Future<T> Function() operation,
    bool showLoading = true,
    bool clearErrorOnStart = true,
    Function(dynamic error)? onError,
  }) async {
    if (showLoading) setLoading(true);
    if (clearErrorOnStart) clearError();
    
    try {
      final result = await operation();
      setLoading(false);
      updateCache();
      return result;
    } catch (e) {
      setLoading(false);
      final errorMessage = e.toString();
      setError(errorMessage);
      
      if (onError != null) {
        onError(e);
      }
      
      return null;
    }
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Paginated provider base class
abstract class PaginatedProvider<T> extends BaseProvider {
  List<T> _items = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  final int _pageSize;
  
  PaginatedProvider({int pageSize = 20}) : _pageSize = pageSize;
  
  List<T> get items => _items;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;
  int get pageSize => _pageSize;
  bool get isEmpty => _items.isEmpty && !isLoading;
  
  /// Load items for a specific page
  Future<void> loadPage(int page);
  
  /// Load next page
  Future<void> loadNextPage() {
    if (!hasMore || isLoading) return Future.value();
    return loadPage(_currentPage + 1);
  }
  
  /// Refresh (reload from beginning)
  Future<void> refresh() async {
    _currentPage = 0;
    _items.clear();
    _hasMore = true;
    invalidateCache();
    await loadPage(0);
  }
  
  /// Update pagination state
  @protected
  void updatePaginationState({
    required List<T> newItems,
    required int currentPage,
    required int totalPages,
    required int totalElements,
  }) {
    if (currentPage == 0) {
      _items = newItems;
    } else {
      _items.addAll(newItems);
    }
    
    _currentPage = currentPage;
    _totalPages = totalPages;
    _totalElements = totalElements;
    _hasMore = currentPage < totalPages - 1;
    
    updateCache();
  }
  
  /// Clear all items
  @protected
  void clearItems() {
    _items.clear();
    _currentPage = 0;
    _totalPages = 0;
    _totalElements = 0;
    _hasMore = true;
    invalidateCache();
  }
}

/// Filtered provider base class
abstract class FilteredProvider<T> extends BaseProvider {
  Map<String, dynamic> _filters = {};
  
  Map<String, dynamic> get filters => Map.unmodifiable(_filters);
  
  /// Set filter
  @protected
  void setFilter(String key, dynamic value) {
    if (_filters[key] != value) {
      _filters[key] = value;
      invalidateCache();
      notifyListeners();
    }
  }
  
  /// Remove filter
  @protected
  void removeFilter(String key) {
    if (_filters.containsKey(key)) {
      _filters.remove(key);
      invalidateCache();
      notifyListeners();
    }
  }
  
  /// Clear all filters
  @protected
  void clearFilters() {
    if (_filters.isNotEmpty) {
      _filters.clear();
      invalidateCache();
      notifyListeners();
    }
  }
  
  /// Check if filter is set
  bool hasFilter(String key) => _filters.containsKey(key);
  
  /// Get filter value
  T? getFilterValue<T>(String key) => _filters[key] as T?;
}


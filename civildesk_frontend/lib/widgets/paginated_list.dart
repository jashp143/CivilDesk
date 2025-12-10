import 'package:flutter/material.dart';

/// A reusable paginated list widget with lazy loading
/// Phase 3 Optimization - List Performance & Pagination
/// 
/// Features:
/// - Infinite scroll with automatic page loading
/// - Pull-to-refresh support
/// - Loading indicators
/// - Empty and error states
/// - Customizable item builder
class PaginatedListView<T> extends StatefulWidget {
  /// Function to load items for a given page
  final Future<List<T>> Function(int page, int pageSize) onLoadPage;
  
  /// Builder for each item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  
  /// Number of items per page
  final int pageSize;
  
  /// Builder for empty state
  final Widget Function()? emptyBuilder;
  
  /// Builder for error state
  final Widget Function(String error, VoidCallback retry)? errorBuilder;
  
  /// Whether to show a loading indicator while loading more
  final bool showLoadingIndicator;
  
  /// Item extent for better performance (optional)
  final double? itemExtent;
  
  /// Padding around the list
  final EdgeInsets? padding;
  
  /// Separator between items
  final Widget? separator;
  
  /// Scroll controller (optional)
  final ScrollController? controller;

  const PaginatedListView({
    super.key,
    required this.onLoadPage,
    required this.itemBuilder,
    this.pageSize = 20,
    this.emptyBuilder,
    this.errorBuilder,
    this.showLoadingIndicator = true,
    this.itemExtent,
    this.padding,
    this.separator,
    this.controller,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _scrollController;
  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialItems();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading && 
        _hasMore &&
        _error == null) {
      _loadMoreItems();
    }
  }

  Future<void> _loadInitialItems() async {
    await _loadItems(refresh: true);
  }

  Future<void> _loadMoreItems() async {
    await _loadItems(refresh: false);
  }

  Future<void> _loadItems({required bool refresh}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final newItems = await widget.onLoadPage(_currentPage, widget.pageSize);
      
      if (mounted) {
        setState(() {
          if (refresh) {
            _items.clear();
          }
          _items.addAll(newItems);
          _hasMore = newItems.length >= widget.pageSize;
          _currentPage++;
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadItems(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading state
    if (_isInitialLoad && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state with no data
    if (_error != null && _items.isEmpty) {
      return widget.errorBuilder != null
          ? widget.errorBuilder!(_error!, _loadInitialItems)
          : _buildDefaultError();
    }

    // Empty state
    if (_items.isEmpty && !_isLoading) {
      return widget.emptyBuilder != null
          ? widget.emptyBuilder!()
          : _buildDefaultEmpty();
    }

    // List with items
    return RefreshIndicator(
      onRefresh: _refresh,
      child: widget.itemExtent != null
          ? _buildFixedExtentList()
          : _buildDynamicList(),
    );
  }

  Widget _buildFixedExtentList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemExtent: widget.itemExtent,
      padding: widget.padding,
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return _buildLoadingIndicator();
        }
        return widget.itemBuilder(context, _items[index], index);
      },
    );
  }

  Widget _buildDynamicList() {
    if (widget.separator != null) {
      return ListView.separated(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        padding: widget.padding,
        separatorBuilder: (_, __) => widget.separator!,
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildLoadingIndicator();
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      padding: widget.padding,
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return _buildLoadingIndicator();
        }
        return widget.itemBuilder(context, _items[index], index);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (!widget.showLoadingIndicator || !_isLoading) {
      return const SizedBox(height: 60);
    }
    
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A paginated grid view with lazy loading
class PaginatedGridView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) onLoadPage;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Widget Function()? emptyBuilder;
  final Widget Function(String error, VoidCallback retry)? errorBuilder;
  final EdgeInsets? padding;

  const PaginatedGridView({
    super.key,
    required this.onLoadPage,
    required this.itemBuilder,
    this.pageSize = 20,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1,
    this.emptyBuilder,
    this.errorBuilder,
    this.padding,
  });

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final ScrollController _scrollController = ScrollController();
  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading && 
        _hasMore) {
      _loadMoreItems();
    }
  }

  Future<void> _loadInitialItems() async {
    await _loadItems(refresh: true);
  }

  Future<void> _loadMoreItems() async {
    await _loadItems(refresh: false);
  }

  Future<void> _loadItems({required bool refresh}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final newItems = await widget.onLoadPage(_currentPage, widget.pageSize);
      
      if (mounted) {
        setState(() {
          if (refresh) {
            _items.clear();
          }
          _items.addAll(newItems);
          _hasMore = newItems.length >= widget.pageSize;
          _currentPage++;
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return widget.errorBuilder != null
          ? widget.errorBuilder!(_error!, _loadInitialItems)
          : const Center(child: Text('Error loading data'));
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyBuilder?.call() ?? 
          const Center(child: Text('No items found'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadItems(refresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: _items.length + (_hasMore ? widget.crossAxisCount : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            if (_isLoading && index == _items.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return const SizedBox.shrink();
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/salary_service.dart';
import '../../models/salary_slip.dart';
import '../../models/page_response.dart';
import '../../widgets/admin_layout.dart';
import '../../core/constants/app_routes.dart';
import 'salary_slip_detail_screen.dart';
import 'salary_calculation_screen.dart';

class SalarySlipsListScreen extends StatefulWidget {
  const SalarySlipsListScreen({super.key});

  @override
  State<SalarySlipsListScreen> createState() => _SalarySlipsListScreenState();
}

class _SalarySlipsListScreenState extends State<SalarySlipsListScreen> {
  final SalaryService _salaryService = SalaryService();
  final ScrollController _scrollController = ScrollController();
  List<SalarySlip> _salarySlips = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedYear;
  int? _selectedMonth;
  
  // Pagination state
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSalarySlips(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !mounted) return;
    
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.9) {
      if (_hasMore && !_isLoading) {
        _loadSalarySlips(refresh: false);
      }
    } else if (maxScroll <= 0 && position.viewportDimension > 0) {
      if (_hasMore && !_isLoading && _salarySlips.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _hasMore && !_isLoading) {
            _loadSalarySlips(refresh: false);
          }
        });
      }
    }
  }

  // Use consistent page size of 15
  int _getPageSize() {
    return 15;
  }

  Future<void> _loadSalarySlips({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _salarySlips.clear();
      _hasMore = true;
      _isInitialLoad = true;
    }

    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pageSize = _getPageSize();
      // Use next page number when loading more
      final pageToLoad = refresh ? 0 : _currentPage + 1;
      final pageResponse = await _salaryService.getAllSalarySlipsPaginated(
        year: _selectedYear,
        month: _selectedMonth,
        page: pageToLoad,
        size: pageSize,
        sortBy: 'year',
        sortDir: 'DESC',
      );

      setState(() {
        if (refresh || pageToLoad == 0) {
          _salarySlips = pageResponse.content;
        } else {
          _salarySlips.addAll(pageResponse.content);
        }
        _currentPage = pageResponse.number;
        _hasMore = pageResponse.hasMore;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectYearMonth() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear ?? now.year, _selectedMonth ?? now.month),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
      _selectedYear = picked.year;
      _selectedMonth = picked.month;
      });
      _loadSalarySlips(refresh: true);
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedYear = null;
      _selectedMonth = null;
    });
    _loadSalarySlips(refresh: true);
  }

  Future<void> _deleteSalarySlip(SalarySlip slip) async {
    if (slip.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Salary Slip'),
        content: const Text(
          'Are you sure you want to delete this salary slip? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _salaryService.deleteSalarySlip(slip.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salary slip deleted successfully')),
        );
        _loadSalarySlips(refresh: true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'FINALIZED':
        return Colors.green;
      case 'PAID':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return AdminLayout(
      currentRoute: AppRoutes.adminSalarySlips,
      title: const Text('Salary Slips'),
      actions: [
        if (_selectedYear != null || _selectedMonth != null)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Filter',
            onPressed: _clearFilter,
          ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter by Month',
          onPressed: _selectYearMonth,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Calculate New Salary',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalaryCalculationScreen(),
              ),
            ).then((_) => _loadSalarySlips());
          },
        ),
      ],
      child: Column(
        children: [
          // Filter indicator
          if (_selectedYear != null || _selectedMonth != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Filtered: ${_selectedMonth != null ? DateFormat('MMMM').format(DateTime(2000, _selectedMonth!)) : ''} ${_selectedYear ?? ''}',
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilter,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadSalarySlips(refresh: true),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: theme.textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _loadSalarySlips,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _salarySlips.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.3,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No salary slips found',
                                          style: theme.textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Calculate a new salary slip to get started',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const SalaryCalculationScreen(),
                                              ),
                                            ).then((_) => _loadSalarySlips(refresh: true));
                                          },
                                          icon: const Icon(Icons.calculate),
                                          label: const Text('Calculate Salary'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Builder(
                              builder: (context) {
                                // Check if we need to load more when content fits on screen
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (_scrollController.hasClients && mounted) {
                                    final position = _scrollController.position;
                                    if (position.maxScrollExtent <= 0 && 
                                        position.viewportDimension > 0 &&
                                        _hasMore && 
                                        !_isLoading && 
                                        _salarySlips.isNotEmpty) {
                                      Future.delayed(const Duration(milliseconds: 500), () {
                                        if (mounted && _hasMore && !_isLoading) {
                                          _loadSalarySlips(refresh: false);
                                        }
                                      });
                                    }
                                  }
                                });

                                return NotificationListener<ScrollNotification>(
                                  onNotification: (ScrollNotification notification) {
                                    if (notification is ScrollEndNotification) {
                                      final metrics = notification.metrics;
                                      if (metrics.pixels >= metrics.maxScrollExtent * 0.9) {
                                        if (_hasMore && !_isLoading) {
                                          _loadSalarySlips(refresh: false);
                                        }
                                      }
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _salarySlips.length + (_hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _salarySlips.length) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Center(child: CircularProgressIndicator()),
                                        );
                                      }
                                      final slip = _salarySlips[index];
                                      return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SalarySlipDetailScreen(salarySlip: slip),
                                        ),
                                      ).then((_) => _loadSalarySlips(refresh: true));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      slip.employeeName,
                                                      style: theme.textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${slip.employeeId} • ${slip.periodString}',
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                        color: theme.colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                    if (slip.department != null)
                                                      Text(
                                                        slip.department!,
                                                        style: theme.textTheme.bodySmall,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Chip(
                                                    label: Text(slip.status),
                                                    backgroundColor: _getStatusColor(slip.status).withValues(alpha: 0.2),
                                                    labelStyle: TextStyle(
                                                      color: _getStatusColor(slip.status),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '₹${currencyFormat.format(slip.netSalary ?? 0)}',
                                                    style: theme.textTheme.titleLarge?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 24),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoChip(
                                                  icon: Icons.calendar_today,
                                                  label: 'Working Days',
                                                  value: '${slip.workingDays ?? 0}',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _InfoChip(
                                                  icon: Icons.check_circle,
                                                  label: 'Present',
                                                  value: '${slip.presentDays ?? 0}',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _InfoChip(
                                                  icon: Icons.access_time,
                                                  label: 'OT Hours',
                                                  value: '${(slip.totalOvertimeHours ?? 0).toStringAsFixed(1)}h',
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (slip.status == 'DRAFT')
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton.icon(
                                                    onPressed: () => _deleteSalarySlip(slip),
                                                    icon: const Icon(Icons.delete, size: 18),
                                                    label: const Text('Delete'),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


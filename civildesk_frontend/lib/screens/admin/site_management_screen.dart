import 'package:flutter/material.dart';
import '../../models/site.dart';
import '../../models/employee.dart';
import '../../core/services/site_service.dart';
import '../../core/services/employee_service.dart';
import '../../widgets/admin_layout.dart';
import '../../widgets/map_location_picker.dart';

class SiteManagementScreen extends StatefulWidget {
  const SiteManagementScreen({super.key});

  @override
  State<SiteManagementScreen> createState() => _SiteManagementScreenState();
}

class _SiteManagementScreenState extends State<SiteManagementScreen> {
  final SiteService _siteService = SiteService();
  final EmployeeService _employeeService = EmployeeService();
  List<Site> _sites = [];
  List<Site> _filteredSites = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _statusFilter; // 'active', 'inactive', or null for all

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sites = await _siteService.getAllSites();
      setState(() {
        _sites = sites;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Site> filtered = List.from(_sites);

    // Apply status filter
    if (_statusFilter != null) {
      filtered = filtered.where((site) {
        if (_statusFilter == 'active') return site.isActive;
        if (_statusFilter == 'inactive') return !site.isActive;
        return true;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((site) {
        return site.siteName.toLowerCase().contains(query) ||
            site.siteCode.toLowerCase().contains(query) ||
            (site.fullAddress.toLowerCase().contains(query));
      }).toList();
    }

    setState(() {
      _filteredSites = filtered;
    });
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark 
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : colorScheme.primaryContainer)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected 
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = _isMobile(context);
    
    return AdminLayout(
      currentRoute: '/admin/sites',
      title: Text(
        'Site Management',
        style: isMobile
            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ) ?? TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                )
            : Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ) ?? TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
      ),
      actions: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSiteDialog(),
            tooltip: 'Add Site',
          )
        else
          TextButton.icon(
            onPressed: () => _showSiteDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Site'),
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
        if (!isMobile) const SizedBox(width: 16),
      ],
      child: _buildContent(colorScheme),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSites,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sites.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSites,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sites found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a new construction site to get started',
                    style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showSiteDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Site'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Ensure filtered sites is initialized
    if (_filteredSites.isEmpty && _sites.isNotEmpty && _searchQuery.isEmpty && _statusFilter == null) {
      _filteredSites = List.from(_sites);
    }

    final isMobile = _isMobile(context);
    
    return RefreshIndicator(
      onRefresh: _loadSites,
      child: CustomScrollView(
        slivers: [
          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                isMobile ? 12 : 16,
                isMobile ? 12 : 16,
                isMobile ? 8 : 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Sites',
                      _sites.length.toString(),
                      Icons.location_on,
                      Colors.blue,
                      isMobile: isMobile,
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Expanded(
                    child: _buildStatCard(
                      'Active Sites',
                      _sites.where((s) => s.isActive).length.toString(),
                      Icons.check_circle,
                      Colors.green,
                      isMobile: isMobile,
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Expanded(
                    child: _buildStatCard(
                      'Total Employees',
                      _sites.fold<int>(0, (sum, s) => sum + (s.assignedEmployeeCount ?? 0)).toString(),
                      Icons.people,
                      Colors.orange,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Search and Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                12,
              ),
              child: Column(
                children: [
                  TextField(
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search sites...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: isMobile ? 12 : 14,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFilterChip('All', _statusFilter == null, () {
                          setState(() {
                            _statusFilter = null;
                            _applyFilters();
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active', _statusFilter == 'active', () {
                          setState(() {
                            _statusFilter = 'active';
                            _applyFilters();
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('Inactive', _statusFilter == 'inactive', () {
                          setState(() {
                            _statusFilter = 'inactive';
                            _applyFilters();
                          });
                        }),
                      ],
                    ),
                  ] else
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
                          ),
                          child: PopupMenuButton<String>(
                            initialValue: _statusFilter,
                            icon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.filter_list, size: 18, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    _statusFilter == null
                                        ? 'All'
                                        : _statusFilter == 'active'
                                            ? 'Active'
                                            : 'Inactive',
                                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 18, color: colorScheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              setState(() {
                                _statusFilter = value == 'all' ? null : value;
                                _applyFilters();
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'all', child: Text('All Sites')),
                              const PopupMenuItem(value: 'active', child: Text('Active Only')),
                              const PopupMenuItem(value: 'inactive', child: Text('Inactive Only')),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Sites List - Table for desktop/tablet, Cards for mobile
          if (_filteredSites.isEmpty && (_searchQuery.isNotEmpty || _statusFilter != null))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                      const SizedBox(height: 16),
                      Text(
                        'No sites found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filter',
                        style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (isMobile)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                16,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final site = _filteredSites[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                      child: _buildSiteCard(site, colorScheme, isMobile: isMobile),
                    );
                  },
                  childCount: _filteredSites.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverToBoxAdapter(
                child: _buildSiteTable(colorScheme),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isMobile = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark 
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: isDark 
            ? Border.all(color: colorScheme.outline.withValues(alpha: 0.15), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isMobile ? 18 : 20),
          SizedBox(width: isMobile ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(Site site, ColorScheme colorScheme, {bool isMobile = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark 
              ? colorScheme.outline.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showSiteDetailDialog(site);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: site.isActive 
                        ? (isDark ? Colors.green[400] : Colors.green[600])
                        : colorScheme.onSurfaceVariant,
                    size: isMobile ? 22 : 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site.siteName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 16 : 18,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 10,
                            vertical: isMobile ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: site.isActive 
                                ? (isDark 
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.green[50])
                                : (isDark
                                    ? colorScheme.surfaceContainerHighest
                                    : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            site.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: site.isActive 
                                  ? (isDark 
                                      ? Colors.green[300]
                                      : Colors.green[700])
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showSiteDialog(site: site);
                            break;
                          case 'employees':
                            _showEmployeeAssignmentDialog(site);
                            break;
                          case 'delete':
                            _confirmDelete(site);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Edit Site'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'employees',
                          child: Row(
                            children: [
                              Icon(Icons.people_outline, size: 20),
                              SizedBox(width: 12),
                              Text('Manage Employees'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Text('Delete Site', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Site Code
              if (site.siteCode.isNotEmpty) ...[
                Text(
                  'Code: ${site.siteCode}',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Address (formatted)
              if (site.fullAddress.isNotEmpty) ...[
                Text(
                  'Address:',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAddress(site),
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Footer Stats
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.people,
                      '${site.assignedEmployeeCount ?? 0}',
                      'employee${(site.assignedEmployeeCount ?? 0) != 1 ? 's' : ''}',
                      isMobile: isMobile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.gps_fixed,
                      '${site.geofenceRadiusMeters}m',
                      'radius',
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAddress(Site site) {
    List<String> parts = [];
    if (site.address != null && site.address!.isNotEmpty) {
      parts.add(site.address!);
    }
    if (site.city != null && site.city!.isNotEmpty) {
      parts.add(site.city!);
    }
    if (site.state != null && site.state!.isNotEmpty) {
      parts.add(site.state!);
    }
    if (site.pincode != null && site.pincode!.isNotEmpty) {
      parts.add(site.pincode!);
    }
    
    // Format as multi-line if we have multiple parts
    if (parts.length > 2) {
      // First line: address
      // Second line: city, state pincode
      String firstLine = parts[0];
      String secondLine = parts.length > 1 
          ? parts.sublist(1).join(', ')
          : '';
      return '$firstLine,\n$secondLine';
    }
    return parts.join(', ');
  }

  Widget _buildSiteTable(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate minimum table width based on content
        // Actions column (170) + other columns need at least 1000px
        final minTableWidth = 1140.0;
        final tableWidth = constraints.maxWidth > minTableWidth 
            ? constraints.maxWidth - 32 
            : minTableWidth;
        
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Card(
          elevation: isDark ? 0 : 2,
          color: colorScheme.surface,
          shape: isDark 
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                )
              : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(1),
                      5: FixedColumnWidth(170), // Actions column needs fixed width for 3 icons
                    },
                    children: [
                      // Header Row
                      TableRow(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                        ),
                        children: [
                          _buildTableHeaderCell('Site Name', colorScheme),
                          _buildTableHeaderCell('Code', colorScheme),
                          _buildTableHeaderCell('Address', colorScheme),
                          _buildTableHeaderCell('Employees', colorScheme),
                          _buildTableHeaderCell('Radius', colorScheme),
                          _buildTableHeaderCell('Actions', colorScheme),
                        ],
                      ),
                      // Data Rows
                      ..._filteredSites.map((site) => _buildTableRow(site, colorScheme)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  TableRow _buildTableRow(Site site, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      children: [
            InkWell(
              onTap: () {
                _showSiteDetailDialog(site);
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: site.isActive
                            ? (isDark 
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.green.withValues(alpha: 0.1))
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: site.isActive 
                            ? (isDark ? Colors.green[400] : Colors.green[600])
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            site.siteName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: site.isActive
                                  ? (isDark 
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.green.withValues(alpha: 0.1))
                                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              site.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color: site.isActive 
                                    ? (isDark ? Colors.green[300] : Colors.green[700])
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                site.siteCode,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                site.fullAddress.isNotEmpty
                    ? site.fullAddress
                    : 'No address',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${site.assignedEmployeeCount ?? 0}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${site.geofenceRadiusMeters}m',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showSiteDialog(site: site),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                      maxWidth: 36,
                      maxHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.people, size: 18),
                    onPressed: () => _showEmployeeAssignmentDialog(site),
                    tooltip: 'Manage Employees',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                      maxWidth: 36,
                      maxHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _confirmDelete(site),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                      maxWidth: 36,
                      maxHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }


  Widget _buildInfoChip(IconData icon, String value, String label, {bool isMobile = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isMobile ? 16 : 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(text: value),
                  TextSpan(
                    text: ' $label',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.normal,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showSiteDialog({Site? site}) {
    showDialog(
      context: context,
      builder: (context) => SiteFormDialog(
        site: site,
        onSaved: () {
          _loadSites();
        },
      ),
    );
  }

  void _showSiteDetailDialog(Site site) {
    showDialog(
      context: context,
      builder: (context) => SiteDetailDialog(siteId: site.id!),
    ).then((deleted) {
      if (deleted == true) {
        _loadSites();
      }
    });
  }

  void _showEmployeeAssignmentDialog(Site site) {
    showDialog(
      context: context,
      builder: (context) => EmployeeAssignmentDialog(
        site: site,
        siteService: _siteService,
        employeeService: _employeeService,
        onUpdated: () {
          _loadSites(); // Refresh sites list to update employee count
        },
      ),
    );
  }

  void _confirmDelete(Site site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${site.siteName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _siteService.deleteSite(site.id!);
                _loadSites();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Site deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class SiteFormDialog extends StatefulWidget {
  final Site? site;
  final VoidCallback onSaved;

  const SiteFormDialog({
    super.key,
    this.site,
    required this.onSaved,
  });

  @override
  State<SiteFormDialog> createState() => _SiteFormDialogState();
}

class _SiteFormDialogState extends State<SiteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _siteService = SiteService();

  late TextEditingController _siteNameController;
  late TextEditingController _siteCodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _radiusController;

  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _siteNameController = TextEditingController(text: widget.site?.siteName);
    _siteCodeController = TextEditingController(text: widget.site?.siteCode);
    _descriptionController = TextEditingController(text: widget.site?.description);
    _addressController = TextEditingController(text: widget.site?.address);
    _cityController = TextEditingController(text: widget.site?.city);
    _stateController = TextEditingController(text: widget.site?.state);
    _pincodeController = TextEditingController(text: widget.site?.pincode);
    _latitudeController = TextEditingController(text: widget.site?.latitude.toString() ?? '');
    _longitudeController = TextEditingController(text: widget.site?.longitude.toString() ?? '');
    _radiusController = TextEditingController(text: (widget.site?.geofenceRadiusMeters ?? 100).toString());
    _isActive = widget.site?.isActive ?? true;
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _siteCodeController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _saveSite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final site = Site(
        id: widget.site?.id,
        siteCode: _siteCodeController.text.trim(),
        siteName: _siteNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        geofenceRadiusMeters: int.parse(_radiusController.text.trim()),
        isActive: _isActive,
      );

      if (widget.site != null) {
        await _siteService.updateSite(widget.site!.id!, site);
      } else {
        await _siteService.createSite(site);
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Site ${widget.site != null ? 'updated' : 'created'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  Future<void> _openMapPicker() async {
    final currentLat = double.tryParse(_latitudeController.text.trim());
    final currentLon = double.tryParse(_longitudeController.text.trim());
    final currentAddress = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MapLocationPicker(
        initialLatitude: currentLat,
        initialLongitude: currentLon,
        initialAddress: currentAddress,
      ),
    );

    if (result != null) {
      setState(() {
        _latitudeController.text = result['latitude'].toString();
        _longitudeController.text = result['longitude'].toString();
        
        // Optionally update address if it was provided and address field is empty
        if (result['address'] != null && 
            result['address'].toString().isNotEmpty &&
            _addressController.text.trim().isEmpty) {
          _addressController.text = result['address'].toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.9 : 700,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.site != null ? 'Edit Site' : 'Add New Site',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 18 : null,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Site Name and Code
                      isMobile
                          ? Column(
                              children: [
                                TextFormField(
                                  controller: _siteNameController,
                                  decoration: const InputDecoration(labelText: 'Site Name *'),
                                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _siteCodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Site Code',
                                    hintText: 'Auto-generated if empty',
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _siteNameController,
                                    decoration: const InputDecoration(labelText: 'Site Name *'),
                                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _siteCodeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Site Code',
                                      hintText: 'Auto-generated if empty',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // City, State, Pincode
                      isMobile
                          ? Column(
                              children: [
                                TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(labelText: 'City'),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _stateController,
                                  decoration: const InputDecoration(labelText: 'State'),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _pincodeController,
                                  decoration: const InputDecoration(labelText: 'Pincode'),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(labelText: 'City'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stateController,
                                    decoration: const InputDecoration(labelText: 'State'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    controller: _pincodeController,
                                    decoration: const InputDecoration(labelText: 'Pincode'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'GPS Location & Geofence',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 16 : null,
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Map picker button
                      OutlinedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map),
                        label: const Text('Choose Location from Map'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Latitude and Longitude
                      isMobile
                          ? Column(
                              children: [
                                TextFormField(
                                  controller: _latitudeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Latitude *',
                                    hintText: 'e.g., 28.6139',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) {
                                    if (v?.isEmpty == true) return 'Required';
                                    final lat = double.tryParse(v!);
                                    if (lat == null || lat < -90 || lat > 90) {
                                      return 'Invalid latitude';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _longitudeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Longitude *',
                                    hintText: 'e.g., 77.2090',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) {
                                    if (v?.isEmpty == true) return 'Required';
                                    final lon = double.tryParse(v!);
                                    if (lon == null || lon < -180 || lon > 180) {
                                      return 'Invalid longitude';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _latitudeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Latitude *',
                                      hintText: 'e.g., 28.6139',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (v) {
                                      if (v?.isEmpty == true) return 'Required';
                                      final lat = double.tryParse(v!);
                                      if (lat == null || lat < -90 || lat > 90) {
                                        return 'Invalid latitude';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _longitudeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Longitude *',
                                      hintText: 'e.g., 77.2090',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (v) {
                                      if (v?.isEmpty == true) return 'Required';
                                      final lon = double.tryParse(v!);
                                      if (lon == null || lon < -180 || lon > 180) {
                                        return 'Invalid longitude';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _radiusController,
                        decoration: const InputDecoration(
                          labelText: 'Geofence Radius (meters) *',
                          hintText: 'Distance within which attendance can be marked',
                          suffixText: 'meters',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Required';
                          final radius = int.tryParse(v!);
                          if (radius == null || radius < 10 || radius > 10000) {
                            return 'Enter a value between 10 and 10000';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        subtitle: const Text('Only active sites allow attendance marking'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSite,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(widget.site != null ? 'Update Site' : 'Create Site'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveSite,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.site != null ? 'Update' : 'Create'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeAssignmentDialog extends StatefulWidget {
  final Site site;
  final SiteService siteService;
  final EmployeeService employeeService;
  final VoidCallback onUpdated;

  const EmployeeAssignmentDialog({
    super.key,
    required this.site,
    required this.siteService,
    required this.employeeService,
    required this.onUpdated,
  });

  @override
  State<EmployeeAssignmentDialog> createState() => _EmployeeAssignmentDialogState();
}

class _EmployeeAssignmentDialogState extends State<EmployeeAssignmentDialog> {
  List<Map<String, dynamic>> _assignedEmployees = [];
  List<Employee> _allEmployees = [];
  List<Employee> _availableEmployees = [];
  bool _isLoading = true;
  bool _isAdding = false;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load assigned employees and all employees in parallel
      final results = await Future.wait([
        widget.siteService.getSiteEmployees(widget.site.id!),
        widget.employeeService.getAllEmployees(page: 0, size: 100),
      ]);

      _assignedEmployees = results[0] as List<Map<String, dynamic>>;
      final employeeResponse = results[1] as EmployeeListResponse;
      _allEmployees = employeeResponse.content;
      _totalPages = employeeResponse.totalPages;
      _hasMore = _currentPage < _totalPages - 1;

      // Filter out already assigned employees
      final assignedIds = _assignedEmployees
          .map((e) => e['employeeId'] as int?)
          .where((id) => id != null)
          .toSet();
      _availableEmployees = _allEmployees
          .where((emp) => !assignedIds.contains(emp.id))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreEmployees() async {
    if (!_hasMore || _isLoading) return;

    try {
      final response = await widget.employeeService.getAllEmployees(
        page: _currentPage + 1,
        size: 100,
      );

      setState(() {
        _allEmployees.addAll(response.content);
        _currentPage = response.number;
        _totalPages = response.totalPages;
        _hasMore = _currentPage < _totalPages - 1;
      });

      // Update available employees
      final assignedIds = _assignedEmployees
          .map((e) => e['employeeId'] as int?)
          .where((id) => id != null)
          .toSet();
      _availableEmployees = _allEmployees
          .where((emp) => !assignedIds.contains(emp.id))
          .toList();
    } catch (e) {
      // Silently fail for pagination
    }
  }

  Future<void> _addEmployee(Employee employee) async {
    setState(() {
      _isAdding = true;
      _error = null;
    });

    try {
      await widget.siteService.assignEmployeeToSite(
        employee.id!,
        widget.site.id!,
        isPrimary: false,
      );

      // Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${employee.firstName} ${employee.lastName} assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign employee: $_error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _removeEmployee(Map<String, dynamic> assignment) async {
    final assignmentId = assignment['id'] as int?;
    if (assignmentId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Employee'),
        content: Text(
          'Are you sure you want to remove ${assignment['employeeName']} from this site?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.siteService.removeEmployeeFromSite(assignmentId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove employee: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Employee> get _filteredAvailableEmployees {
    if (_searchQuery.isEmpty) return _availableEmployees;
    final query = _searchQuery.toLowerCase();
    return _availableEmployees.where((emp) {
      final name = '${emp.firstName} ${emp.lastName}'.toLowerCase();
      final code = emp.employeeId.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Employees - ${widget.site.siteName}',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_assignedEmployees.length} assigned',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      tabs: const [
                        Tab(text: 'Assigned Employees', icon: Icon(Icons.people)),
                        Tab(text: 'Add Employee', icon: Icon(Icons.person_add)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Assigned Employees Tab
                          _buildAssignedEmployeesTab(colorScheme),
                          // Add Employee Tab
                          _buildAddEmployeeTab(colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedEmployeesTab(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_assignedEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No employees assigned',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to "Add Employee" tab to assign employees',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _assignedEmployees.length,
      itemBuilder: (context, index) {
        final assignment = _assignedEmployees[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: colorScheme.primary),
          ),
          title: Text(assignment['employeeName'] ?? 'Unknown'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${assignment['employeeCode'] ?? 'N/A'}'),
              if (assignment['isPrimary'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(
                    label: const Text('Primary Site'),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeEmployee(assignment),
            tooltip: 'Remove from site',
          ),
        );
      },
    );
  }

  Widget _buildAddEmployeeTab(ColorScheme colorScheme) {
    final filtered = _filteredAvailableEmployees;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search employees by name or ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Employee list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'All employees are already assigned'
                                : 'No employees found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: TextButton(
                                onPressed: _loadMoreEmployees,
                                child: const Text('Load More'),
                              ),
                            ),
                          );
                        }

                        final employee = filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.person, color: colorScheme.primary),
                          ),
                          title: Text('${employee.firstName} ${employee.lastName}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${employee.employeeId}'),
                              if (employee.department != null)
                                Text('Dept: ${employee.department}'),
                            ],
                          ),
                          trailing: _isAdding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Assign'),
                                  onPressed: () => _addEmployee(employee),
                                ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Site Detail Dialog - converted from SiteDetailScreen
class SiteDetailDialog extends StatefulWidget {
  final int siteId;

  const SiteDetailDialog({
    super.key,
    required this.siteId,
  });

  @override
  State<SiteDetailDialog> createState() => _SiteDetailDialogState();
}

class _SiteDetailDialogState extends State<SiteDetailDialog> {
  final SiteService _siteService = SiteService();
  final EmployeeService _employeeService = EmployeeService();
  Site? _site;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _assignedEmployees = [];
  bool _isLoadingEmployees = false;

  @override
  void initState() {
    super.initState();
    _loadSiteDetails();
  }

  Future<void> _loadSiteDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final site = await _siteService.getSiteById(widget.siteId);
      setState(() {
        _site = site;
        _isLoading = false;
      });
      _loadAssignedEmployees();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAssignedEmployees() async {
    if (_site == null) return;

    setState(() {
      _isLoadingEmployees = true;
    });

    try {
      final employees = await _siteService.getSiteEmployees(_site!.id!);
      setState(() {
        _assignedEmployees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEmployees = false;
      });
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  void _showSiteDialog() {
    showDialog(
      context: context,
      builder: (context) => SiteFormDialog(
        site: _site,
        onSaved: () {
          _loadSiteDetails();
        },
      ),
    );
  }

  void _showEmployeeAssignmentDialog() {
    if (_site == null) return;
    showDialog(
      context: context,
      builder: (context) => EmployeeAssignmentDialog(
        site: _site!,
        siteService: _siteService,
        employeeService: _employeeService,
        onUpdated: () {
          _loadSiteDetails();
        },
      ),
    );
  }

  void _confirmDelete() {
    if (_site == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${_site!.siteName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close delete confirmation
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await _siteService.deleteSite(_site!.id!);
                if (mounted) {
                  navigator.pop(true); // Close detail dialog and return deleted=true
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Site deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = _isMobile(context);

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _site?.siteName ?? 'Site Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 18 : null,
                          ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showSiteDialog();
                          break;
                        case 'employees':
                          _showEmployeeAssignmentDialog();
                          break;
                        case 'delete':
                          _confirmDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Edit Site'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'employees',
                        child: Row(
                          children: [
                            Icon(Icons.people_outline, size: 20),
                            SizedBox(width: 12),
                            Text('Manage Employees'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Delete Site', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadSiteDetails,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Site Header
                              _buildSiteHeader(isMobile),
                              const SizedBox(height: 16),
                              // Site Information
                              _buildInfoSection('Site Information', [
                                _buildInfoTile(Icons.qr_code, 'Site Code', _site!.siteCode, isMobile: isMobile),
                                if (_site!.description?.isNotEmpty == true)
                                  _buildInfoTile(Icons.description, 'Description', _site!.description!, isMobile: isMobile),
                                _buildInfoTile(
                                  Icons.toggle_on,
                                  'Status',
                                  _site!.isActive ? 'Active' : 'Inactive',
                                  valueColor: _site!.isActive ? Colors.green : Colors.grey,
                                  isMobile: isMobile,
                                ),
                              ], isMobile: isMobile),
                              const SizedBox(height: 16),
                              // Location Details
                              _buildInfoSection('Location Details', [
                                if (_site!.fullAddress.isNotEmpty)
                                  _buildInfoTile(Icons.location_city, 'Address', _site!.fullAddress, isMobile: isMobile),
                                if (_site!.city?.isNotEmpty == true)
                                  _buildInfoTile(Icons.location_on, 'City', _site!.city!, isMobile: isMobile),
                                if (_site!.state?.isNotEmpty == true)
                                  _buildInfoTile(Icons.map, 'State', _site!.state!, isMobile: isMobile),
                                if (_site!.pincode?.isNotEmpty == true)
                                  _buildInfoTile(Icons.pin, 'Pincode', _site!.pincode!, isMobile: isMobile),
                              ], isMobile: isMobile),
                              const SizedBox(height: 16),
                              // GPS & Geofence
                              _buildInfoSection('GPS & Geofence', [
                                _buildInfoTile(Icons.gps_fixed, 'Latitude', _site!.latitude.toStringAsFixed(6), isMobile: isMobile),
                                _buildInfoTile(Icons.gps_fixed, 'Longitude', _site!.longitude.toStringAsFixed(6), isMobile: isMobile),
                                _buildInfoTile(Icons.radio_button_checked, 'Geofence Radius', '${_site!.geofenceRadiusMeters}m', isMobile: isMobile),
                              ], isMobile: isMobile),
                              const SizedBox(height: 16),
                              // Assigned Employees Section
                              _buildEmployeesSection(isMobile),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          width: isMobile ? 56 : 64,
          height: isMobile ? 56 : 64,
          decoration: BoxDecoration(
            color: _site!.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.location_on,
            color: _site!.isActive ? Colors.green : Colors.grey,
            size: isMobile ? 32 : 40,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _site!.siteName,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: _site!.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _site!.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: _site!.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, {bool isMobile = false}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? valueColor, bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isMobile ? 18 : 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesSection(bool isMobile) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Employees',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showEmployeeAssignmentDialog,
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoadingEmployees
                ? const Center(child: CircularProgressIndicator())
                : _assignedEmployees.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No employees assigned',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _showEmployeeAssignmentDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Assign Employees'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assignedEmployees.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final assignment = _assignedEmployees[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                                size: isMobile ? 20 : 24,
                              ),
                            ),
                            title: Text(
                              assignment['employeeName'] ?? 'Unknown',
                              style: TextStyle(fontSize: isMobile ? 14 : 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${assignment['employeeCode'] ?? 'N/A'}'),
                                if (assignment['isPrimary'] == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Chip(
                                      label: const Text('Primary Site'),
                                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                                      labelStyle: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}


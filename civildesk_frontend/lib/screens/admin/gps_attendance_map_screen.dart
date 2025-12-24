import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/site.dart';
import '../../models/employee.dart';
import '../../core/services/site_service.dart';
import '../../core/services/employee_service.dart';
import '../../widgets/admin_layout.dart';

class GpsAttendanceMapScreen extends StatefulWidget {
  const GpsAttendanceMapScreen({super.key});

  @override
  State<GpsAttendanceMapScreen> createState() => _GpsAttendanceMapScreenState();
}

class _GpsAttendanceMapScreenState extends State<GpsAttendanceMapScreen> {
  final SiteService _siteService = SiteService();
  final EmployeeService _employeeService = EmployeeService();
  GoogleMapController? _mapController;
  List<GpsAttendanceLog> _attendanceLogs = [];
  List<Site> _sites = [];
  List<Employee> _employees = [];
  bool _isLoading = true;
  String? _error;
  String? _mapError;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSiteFilter;
  String? _selectedPunchTypeFilter;
  String? _selectedEmployeeFilter;
  bool _isFiltersExpanded = true;
  BitmapDescriptor? _customSiteMarker;
  final PageController _statsPageController = PageController();
  
  @override
  void dispose() {
    _mapController?.dispose();
    _statsPageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeCustomMarker();
    _loadData();
  }

  Future<void> _initializeCustomMarker() async {
    final marker = await _createCustomSiteMarker();
    if (mounted) {
      setState(() {
        _customSiteMarker = marker;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _siteService.getAllSites(),
        _siteService.getMapDashboardData(
          _selectedDate,
          employeeId: _selectedEmployeeFilter != null && _selectedEmployeeFilter != 'all'
              ? _selectedEmployeeFilter
              : null,
        ),
        _employeeService.getAllEmployees(page: 0, size: 1000),
      ]);
      
      final sites = results[0] as List<Site>;
      final logs = results[1] as List<GpsAttendanceLog>;
      final employeeResponse = results[2] as EmployeeListResponse;
      
      setState(() {
        _sites = sites;
        _attendanceLogs = logs;
        _employees = employeeResponse.content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<GpsAttendanceLog> get _filteredLogs {
    return _attendanceLogs.where((log) {
      if (_selectedSiteFilter != null && _selectedSiteFilter != 'all') {
        if (log.siteId.toString() != _selectedSiteFilter) return false;
      }
      if (_selectedPunchTypeFilter != null && _selectedPunchTypeFilter != 'all') {
        if (log.punchType.toUpperCase() != _selectedPunchTypeFilter) return false;
      }
      // Employee filtering is done on backend, but keep frontend filter as fallback
      if (_selectedEmployeeFilter != null && _selectedEmployeeFilter != 'all') {
        if (log.employeeId != _selectedEmployeeFilter) return false;
      }
      return true;
    }).toList();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  Future<BitmapDescriptor> _createCustomSiteMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Size size = const Size(56, 72);

    // Draw the marker pin shape (teardrop design)
    final Paint pinPaint = Paint()
      ..color = const Color(0xFF1976D2) // Blue color for site
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw teardrop pin shape - simplified version
    final Path pinPath = Path()
      ..moveTo(size.width / 2, size.height) // Bottom point
      ..lineTo(size.width * 0.2, size.height * 0.6) // Left side start
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.5,
        size.width * 0.2,
        size.height * 0.4,
      )
      ..lineTo(size.width * 0.2, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.15,
        size.width * 0.3,
        size.height * 0.15,
      )
      ..lineTo(size.width * 0.7, size.height * 0.15)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.15,
        size.width * 0.8,
        size.height * 0.25,
      )
      ..lineTo(size.width * 0.8, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.5,
        size.width * 0.8,
        size.height * 0.6,
      )
      ..close();

    canvas.drawPath(pinPath, pinPaint);
    canvas.drawPath(pinPath, borderPaint);

    // Draw building icon inside the pin head
    final Paint iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw building shape (simplified)
    final double iconSize = size.width * 0.45;
    final double iconX = (size.width - iconSize) / 2;
    final double iconY = size.height * 0.22;

    // Building rectangle with rounded corners
    final RRect buildingRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(iconX, iconY, iconSize, iconSize * 0.75),
      const Radius.circular(4),
    );
    canvas.drawRRect(buildingRect, iconPaint);

    // Building roof/top triangle
    final Path roofPath = Path()
      ..moveTo(iconX - 2, iconY)
      ..lineTo(size.width / 2, iconY - iconSize * 0.15)
      ..lineTo(iconX + iconSize + 2, iconY)
      ..close();
    canvas.drawPath(roofPath, iconPaint);

    // Building windows (2x2 grid)
    final Paint windowPaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;

    final double windowSize = iconSize * 0.18;
    final double windowSpacing = iconSize * 0.12;
    final double startX = iconX + windowSpacing;
    final double startY = iconY + windowSpacing + iconSize * 0.1;

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 2; col++) {
        final RRect windowRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + col * (windowSize + windowSpacing),
            startY + row * (windowSize + windowSpacing),
            windowSize,
            windowSize,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(windowRect, windowPaint);
      }
    }

    // Convert to image
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AdminLayout(
      currentRoute: '/admin/gps-attendance-map',
      title: Text(
        'GPS Attendance Dashboard',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      child: _isLoading && _attendanceLogs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _attendanceLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(colorScheme),
                ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    final isMobile = _isMobile(context);
    
    if (isMobile) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Filters Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
              child: _buildCollapsibleMobileFilters(colorScheme),
            ),
            const SizedBox(height: 12),

            // Summary Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMobileSummaryStats(colorScheme),
            ),
            const SizedBox(height: 12),

            // Main Content - Map and List
            _buildMobileMainContent(colorScheme),
          ],
        ),
      );
    } else {
      // Desktop layout - no scroll view wrapper, use Column with Expanded
      return Column(
        children: [
          // Filters Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildCollapsibleDesktopFilters(colorScheme),
          ),
          const SizedBox(height: 12),


          // Summary Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDesktopSummaryStats(),
          ),
          const SizedBox(height: 12),

          // Main Content - Map and List
          Expanded(
            child: _buildDesktopMainContent(colorScheme),
          ),
        ],
      );
    }
  }

  Widget _buildCollapsibleMobileFilters(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              )
            : BorderSide.none,
      ),
      color: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : colorScheme.surface,
      child: Column(
        children: [
          // Filter Header with Toggle
          InkWell(
            onTap: () {
              setState(() {
                _isFiltersExpanded = !_isFiltersExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isFiltersExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible Filter Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildMobileFilters(colorScheme),
            crossFadeState: _isFiltersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Picker
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(10),
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Site Filter
          DropdownButtonFormField<String>(
            initialValue: _selectedSiteFilter,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.business,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              hintText: 'Filter by Site',
              hintStyle: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(minHeight: 44),
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(
                  'All Sites',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
              ..._sites.map((site) => DropdownMenuItem(
                    value: site.id.toString(),
                    child: Text(
                      site.siteName,
                      style: TextStyle(color: colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedSiteFilter = value);
              // Update map camera to fit filtered bounds
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _mapController != null) {
                  _fitBounds();
                }
              });
            },
          ),
          const SizedBox(height: 10),

          // Employee Filter
          DropdownButtonFormField<String>(
            initialValue: _selectedEmployeeFilter,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.person,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              hintText: 'Filter by Employee',
              hintStyle: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(minHeight: 44),
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(
                  'All Employees',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
              ..._employees.map((employee) => DropdownMenuItem(
                    value: employee.employeeId,
                    child: Text(
                      '${employee.firstName} ${employee.lastName}',
                      style: TextStyle(color: colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedEmployeeFilter = value);
              // Update map camera to fit filtered bounds
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _mapController != null) {
                  _fitBounds();
                }
              });
            },
          ),
          const SizedBox(height: 10),

          // Punch Type Filter
          DropdownButtonFormField<String>(
            initialValue: _selectedPunchTypeFilter,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.access_time,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              hintText: 'Filter by Punch',
              hintStyle: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(minHeight: 44),
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Punches')),
              DropdownMenuItem(value: 'CHECK_IN', child: Text('Check In')),
              DropdownMenuItem(value: 'LUNCH_OUT', child: Text('Lunch Out')),
              DropdownMenuItem(value: 'LUNCH_IN', child: Text('Lunch In')),
              DropdownMenuItem(value: 'CHECK_OUT', child: Text('Check Out')),
            ],
            onChanged: (value) {
              setState(() => _selectedPunchTypeFilter = value);
              // Update map camera to fit filtered bounds
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _mapController != null) {
                  _fitBounds();
                }
              });
            },
          ),
        ],
      ),
    );
  }


  Widget _buildCollapsibleDesktopFilters(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Filter Header with Toggle
        InkWell(
          onTap: () {
            setState(() {
              _isFiltersExpanded = !_isFiltersExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isFiltersExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Collapsible Filter Content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildDesktopFilters(colorScheme),
          ),
          crossFadeState: _isFiltersExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildDesktopFilters(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        // Date Picker
        InkWell(
          onTap: _selectDate,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark 
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Site Filter
        Flexible(
          flex: 1,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedSiteFilter,
            decoration: InputDecoration(
              labelText: 'Filter by Site',
              labelStyle: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              constraints: const BoxConstraints(minHeight: 40),
            ),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            items: [
              DropdownMenuItem(value: 'all', child: Text('All Sites')),
              ..._sites.map((site) => DropdownMenuItem(
                    value: site.id.toString(),
                    child: Text(
                      site.siteName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedSiteFilter = value);
              // Update map camera to fit filtered bounds
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _mapController != null) {
                  _fitBounds();
                }
              });
            },
          ),
        ),
        const SizedBox(width: 12),

        // Employee Filter
        Flexible(
          flex: 1,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedEmployeeFilter,
            decoration: InputDecoration(
              labelText: 'Filter by Employee',
              labelStyle: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              constraints: const BoxConstraints(minHeight: 40),
            ),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(
                  'All Employees',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
              ..._employees.map((employee) => DropdownMenuItem(
                    value: employee.employeeId,
                    child: Text(
                      '${employee.firstName} ${employee.lastName}',
                      style: TextStyle(color: colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedEmployeeFilter = value);
              // Update map camera to fit filtered bounds
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _mapController != null) {
                  _fitBounds();
                }
              });
            },
          ),
        ),
        const SizedBox(width: 12),

        // Punch Type Filter
        Flexible(
          flex: 1,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedPunchTypeFilter,
            decoration: InputDecoration(
              labelText: 'Filter by Punch',
              labelStyle: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark 
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              constraints: const BoxConstraints(minHeight: 40),
            ),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Punches')),
              DropdownMenuItem(value: 'CHECK_IN', child: Text('Check In')),
              DropdownMenuItem(value: 'LUNCH_OUT', child: Text('Lunch Out')),
              DropdownMenuItem(value: 'LUNCH_IN', child: Text('Lunch In')),
              DropdownMenuItem(value: 'CHECK_OUT', child: Text('Check Out')),
            ],
            onChanged: (value) {
              setState(() => _selectedPunchTypeFilter = value);
              // Update map camera to fit filtered bounds
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _mapController != null) {
                  _fitBounds();
                }
              });
            },
          ),
        ),
      ],
    );
  }


  Widget _buildMobileSummaryStats(ColorScheme colorScheme) {
    final stats = [
      {
        'label': 'Total Punches',
        'count': _filteredLogs.length,
        'color': Colors.blue,
      },
      {
        'label': 'Check Ins',
        'count': _filteredLogs.where((l) => l.punchType.toUpperCase() == 'CHECK_IN').length,
        'color': const Color(0xFF4CAF50),
      },
      {
        'label': 'Lunch Out',
        'count': _filteredLogs.where((l) => l.punchType.toUpperCase() == 'LUNCH_OUT').length,
        'color': const Color(0xFFFF9800),
      },
      {
        'label': 'Lunch In',
        'count': _filteredLogs.where((l) => l.punchType.toUpperCase() == 'LUNCH_IN').length,
        'color': const Color(0xFF2196F3),
      },
      {
        'label': 'Check Outs',
        'count': _filteredLogs.where((l) => l.punchType.toUpperCase() == 'CHECK_OUT').length,
        'color': const Color(0xFFF44336),
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == stats.length - 1 ? 0 : 8,
            ),
            child: SizedBox(
              width: 120,
              child: _buildSummaryCard(
                stat['label'] as String,
                stat['count'] as int,
                stat['color'] as Color,
                colorScheme,
                isMobile: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopSummaryStats() {
    final colorScheme = Theme.of(context).colorScheme;
    
    final stats = [
      {
        'label': 'Total Punches',
        'count': _filteredLogs.length,
        'color': Colors.blue,
      },
      {
        'label': 'Check Ins',
        'count': _filteredLogs.where((l) => l.punchType.toUpperCase() == 'CHECK_IN').length,
        'color': const Color(0xFF4CAF50),
      },
      {
        'label': 'Lunch Out',
        'count': _filteredLogs.where((l) => l.punchType.toUpperCase() == 'LUNCH_OUT').length,
        'color': const Color(0xFFFF9800),
      },
      {
        'label': 'Lunch In',
        'count': _filteredLogs.where((l) => l.punchType.toUpperCase() == 'LUNCH_IN').length,
        'color': const Color(0xFF2196F3),
      },
      {
        'label': 'Check Outs',
        'count': _filteredLogs.where((l) => l.punchType.toUpperCase() == 'CHECK_OUT').length,
        'color': const Color(0xFFF44336),
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: index == stats.length - 1 ? 0 : 12,
            ),
            child: SizedBox(
              width: 140,
              child: _buildSummaryCard(
                stat['label'] as String,
                stat['count'] as int,
                stat['color'] as Color,
                colorScheme,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileMainContent(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Map View
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _buildMapView(),
              // Map Title (top-left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Punch Locations on Map',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              // Map Controls (top-right)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    _buildMapControlButton(
                      Icons.add,
                      () {
                        _mapController?.animateCamera(
                          CameraUpdate.zoomIn(),
                        );
                      },
                      colorScheme,
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      Icons.remove,
                      () {
                        _mapController?.animateCamera(
                          CameraUpdate.zoomOut(),
                        );
                      },
                      colorScheme,
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      Icons.my_location,
                      () {
                        _fitBounds();
                      },
                      colorScheme,
                    ),
                  ],
                ),
              ),
              // Full Screen Button (bottom-left)
              Positioned(
                bottom: 12,
                left: 12,
                child: _buildMapControlButton(
                  Icons.fullscreen,
                  _showFullScreenMap,
                  colorScheme,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Attendance List
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: isDark ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDark
                ? BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  )
                : BorderSide.none,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance Log (${_filteredLogs.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 400,
                child: _filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Attendance Logs',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'No logs found for the selected filters. Try adjusting your filters or select a different date.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          return _buildAttendanceLogTile(log);
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopMainContent(ColorScheme colorScheme) {
    return Column(
      children: [
        // Map View - Top (60% of available space)
        Expanded(
          flex: 6,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                _buildMapView(),
                // Map Title (top-left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Punch Locations on Map',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                // Map Controls (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      _buildMapControlButton(
                        Icons.add,
                        () {
                          _mapController?.animateCamera(
                            CameraUpdate.zoomIn(),
                          );
                        },
                        colorScheme,
                      ),
                      const SizedBox(height: 8),
                      _buildMapControlButton(
                        Icons.remove,
                        () {
                          _mapController?.animateCamera(
                            CameraUpdate.zoomOut(),
                          );
                        },
                        colorScheme,
                      ),
                      const SizedBox(height: 8),
                      _buildMapControlButton(
                        Icons.my_location,
                        () {
                          _fitBounds();
                        },
                        colorScheme,
                      ),
                    ],
                  ),
                ),
                // Full Screen Button (bottom-left)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _buildMapControlButton(
                    Icons.fullscreen,
                    _showFullScreenMap,
                    colorScheme,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Attendance List - Below Map (40% of available space)
        Expanded(
          flex: 4,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                elevation: isDark ? 0 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isDark
                      ? BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : BorderSide.none,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance Log (${_filteredLogs.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                      ),
                    ),
                    Expanded(
                      child: _filteredLogs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No punch records for today.',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8),
                              itemCount: _filteredLogs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final log = _filteredLogs[index];
                                return _buildAttendanceLogTile(log);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlButton(IconData icon, VoidCallback onPressed, ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color, ColorScheme colorScheme, {bool isMobile = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final card = Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: isDark 
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: isMobile ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return card;
  }



  Widget _buildAttendanceLogTile(GpsAttendanceLog log) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = _isMobile(context);
    final punchColor = Color(log.punchTypeColor);
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: 6,
      ),
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            children: [
              // Punch Type Icon
              Container(
                width: isMobile ? 48 : 56,
                height: isMobile ? 48 : 56,
                decoration: BoxDecoration(
                  color: punchColor.withValues(alpha: isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: punchColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _getPunchTypeIcon(log.punchType),
                  color: punchColor,
                  size: isMobile ? 24 : 28,
                ),
              ),
              const SizedBox(width: 12),
              
              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Employee Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.employeeName ?? log.employeeId,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 15 : 16,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        // Status Badges
                        if (!log.isInsideGeofence)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 12,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Outside',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (log.isMockLocation)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Mock',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Punch Type & Site
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: punchColor.withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            log.punchTypeLabel,
                            style: TextStyle(
                              color: punchColor,
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (log.siteName != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.business,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              log.siteName!,
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Distance & Time
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (log.distanceFromSite != null) ...[
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${log.distanceFromSite!.toStringAsFixed(0)}m',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm:ss').format(log.punchTime),
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Time Badge
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(log.punchTime),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM').format(log.punchTime),
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 10,
                        color: colorScheme.onSurfaceVariant,
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
  }

  IconData _getPunchTypeIcon(String punchType) {
    switch (punchType.toUpperCase()) {
      case 'CHECK_IN':
        return Icons.login;
      case 'LUNCH_OUT':
        return Icons.restaurant;
      case 'LUNCH_IN':
        return Icons.restaurant_menu;
      case 'CHECK_OUT':
        return Icons.logout;
      default:
        return Icons.access_time;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  void _showLogDetails(GpsAttendanceLog log) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final punchColor = Color(log.punchTypeColor);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: punchColor.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getPunchTypeIcon(log.punchType),
                color: punchColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.punchTypeLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm:ss').format(log.punchTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(
                    'Inside Geofence',
                    log.isInsideGeofence,
                    Icons.check_circle,
                    Colors.green,
                    colorScheme,
                    isDark,
                  ),
                  _buildStatusChip(
                    'Mock Location',
                    log.isMockLocation,
                    Icons.warning_amber_rounded,
                    Colors.orange,
                    colorScheme,
                    isDark,
                  ),
                  if (log.networkStatus != null)
                    _buildStatusChip(
                      'Network: ${log.networkStatus}',
                      true,
                      Icons.signal_cellular_alt,
                      Colors.blue,
                      colorScheme,
                      isDark,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Employee Info
              _buildDetailSection(
                'Employee Information',
                Icons.person,
                [
                  _buildDetailRow(
                    Icons.badge,
                    'Employee',
                    log.employeeName ?? log.employeeId,
                    colorScheme,
                  ),
                  if (log.employeeId != (log.employeeName ?? log.employeeId))
                    _buildDetailRow(
                      Icons.tag,
                      'Employee ID',
                      log.employeeId,
                      colorScheme,
                    ),
                ],
                colorScheme,
              ),
              
              const SizedBox(height: 16),
              
              // Location Info
              _buildDetailSection(
                'Location Information',
                Icons.location_on,
                [
                  _buildDetailRow(
                    Icons.business,
                    'Site',
                    log.siteName ?? 'Not specified',
                    colorScheme,
                  ),
                  if (log.siteCode != null)
                    _buildDetailRow(
                      Icons.qr_code,
                      'Site Code',
                      log.siteCode!,
                      colorScheme,
                    ),
                  if (log.distanceFromSite != null)
                    _buildDetailRow(
                      Icons.straighten,
                      'Distance from Site',
                      '${log.distanceFromSite!.toStringAsFixed(0)} meters',
                      colorScheme,
                    ),
                  _buildDetailRow(
                    Icons.my_location,
                    'Coordinates',
                    '${log.latitude.toStringAsFixed(6)}, ${log.longitude.toStringAsFixed(6)}',
                    colorScheme,
                  ),
                  if (log.accuracyMeters != null)
                    _buildDetailRow(
                      Icons.gps_fixed,
                      'Accuracy',
                      '${log.accuracyMeters!.toStringAsFixed(0)} meters',
                      colorScheme,
                    ),
                ],
                colorScheme,
              ),
              
              if (log.deviceName != null || log.deviceId != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection(
                  'Device Information',
                  Icons.phone_android,
                  [
                    if (log.deviceName != null)
                      _buildDetailRow(
                        Icons.devices,
                        'Device Name',
                        log.deviceName!,
                        colorScheme,
                      ),
                    if (log.deviceId != null)
                      _buildDetailRow(
                        Icons.fingerprint,
                        'Device ID',
                        log.deviceId!,
                        colorScheme,
                      ),
                  ],
                  colorScheme,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    bool isActive,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: isDark ? 0.2 : 0.1)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? color : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? color : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    // Show loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_error != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }

    if (_filteredLogs.isEmpty && _sites.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No attendance logs or sites found for the selected date',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Calculate initial camera position
    LatLng initialPosition;
    if (_filteredLogs.isNotEmpty) {
      final firstLog = _filteredLogs.first;
      initialPosition = LatLng(firstLog.latitude, firstLog.longitude);
    } else if (_sites.isNotEmpty) {
      final firstSite = _sites.first;
      initialPosition = LatLng(firstSite.latitude, firstSite.longitude);
    } else {
      // Default to a central location (e.g., India)
      initialPosition = const LatLng(20.5937, 78.9629);
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: _filteredLogs.isEmpty ? 10.0 : 14.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _fitBounds();
            // Clear any map errors on successful creation
            if (mounted) {
              setState(() {
                _mapError = null;
              });
            }
          },
          onCameraMoveStarted: () {
            // Map is interactive, so it's working
            if (mounted && _mapError != null) {
              setState(() {
                _mapError = null;
              });
            }
          },
          markers: _buildMarkers(),
          circles: _buildCircles(),
          mapType: MapType.normal,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          // Add error handling
          onTap: (LatLng position) {
            // Map is responding, clear errors
            if (mounted && _mapError != null) {
              setState(() {
                _mapError = null;
              });
            }
          },
        ),
        // Show error message if map fails to load
        if (_mapError != null)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Map Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _mapError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () {
                        setState(() {
                          _mapError = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Full Screen Button (bottom-left)
        Positioned(
          bottom: 12,
          left: 12,
          child: _buildMapControlButton(
            Icons.fullscreen,
            _showFullScreenMap,
            Theme.of(context).colorScheme,
          ),
        ),
      ],
    );
  }


  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    for (int i = 0; i < _filteredLogs.length; i++) {
      final log = _filteredLogs[i];
      
      markers.add(
        Marker(
          markerId: MarkerId('attendance_${log.id}_$i'),
          position: LatLng(log.latitude, log.longitude),
          infoWindow: InfoWindow(
            title: log.employeeName ?? log.employeeId,
            snippet: '${log.punchTypeLabel}\n${DateFormat('dd MMM yyyy HH:mm').format(log.punchTime)}\n${log.siteName ?? 'Unknown Site'}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHueForPunchType(log.punchType),
          ),
          onTap: () => _showLogDetails(log),
        ),
      );
    }

    // Add site markers (filtered if site filter is active)
    final sitesToShow = _selectedSiteFilter != null && _selectedSiteFilter != 'all'
        ? _sites.where((site) => site.id.toString() == _selectedSiteFilter).toList()
        : _sites;
    
    for (final site in sitesToShow) {
      markers.add(
        Marker(
          markerId: MarkerId('site_${site.id}'),
          position: LatLng(site.latitude, site.longitude),
          infoWindow: InfoWindow(
            title: site.siteName,
            snippet: '${site.siteCode}\nRadius: ${site.geofenceRadiusMeters}m',
          ),
          icon: _customSiteMarker ?? BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    final circles = <Circle>{};
    
    // Filter sites based on selected site filter
    final sitesToShow = _selectedSiteFilter != null && _selectedSiteFilter != 'all'
        ? _sites.where((site) => site.id.toString() == _selectedSiteFilter).toList()
        : _sites;
    
    for (final site in sitesToShow) {
      circles.add(
        Circle(
          circleId: CircleId('site_${site.id}'),
          center: LatLng(site.latitude, site.longitude),
          radius: site.geofenceRadiusMeters.toDouble(),
          strokeColor: Colors.blue.withValues(alpha: 0.5),
          strokeWidth: 2,
          fillColor: Colors.blue.withValues(alpha: 0.1),
        ),
      );
    }

    return circles;
  }

  double _getMarkerHueForPunchType(String punchType) {
    // Map punch types to Google Maps marker hues
    // BitmapDescriptor hue constants are already doubles
    switch (punchType.toUpperCase()) {
      case 'CHECK_IN':
        return BitmapDescriptor.hueGreen; // Green for check in
      case 'LUNCH_OUT':
        return BitmapDescriptor.hueOrange; // Orange for lunch out
      case 'LUNCH_IN':
        return BitmapDescriptor.hueBlue; // Blue for lunch in
      case 'CHECK_OUT':
        return BitmapDescriptor.hueRed; // Red for check out
      default:
        return BitmapDescriptor.hueViolet; // Default color
    }
  }

  void _fitBounds() {
    if (_mapController == null) return;

    // Get filtered sites based on site filter
    final sitesToShow = _selectedSiteFilter != null && _selectedSiteFilter != 'all'
        ? _sites.where((site) => site.id.toString() == _selectedSiteFilter).toList()
        : _sites;

    // If we have filtered logs, use them; otherwise use filtered sites
    if (_filteredLogs.isNotEmpty) {
      try {
        double minLat = _filteredLogs.first.latitude;
        double maxLat = _filteredLogs.first.latitude;
        double minLng = _filteredLogs.first.longitude;
        double maxLng = _filteredLogs.first.longitude;

        for (final log in _filteredLogs) {
          minLat = minLat < log.latitude ? minLat : log.latitude;
          maxLat = maxLat > log.latitude ? maxLat : log.latitude;
          minLng = minLng < log.longitude ? minLng : log.longitude;
          maxLng = maxLng > log.longitude ? maxLng : log.longitude;
        }

        // Also include filtered sites in bounds calculation
        for (final site in sitesToShow) {
          minLat = minLat < site.latitude ? minLat : site.latitude;
          maxLat = maxLat > site.latitude ? maxLat : site.latitude;
          minLng = minLng < site.longitude ? minLng : site.longitude;
          maxLng = maxLng > site.longitude ? maxLng : site.longitude;
        }

        // Add padding
        final latPadding = (maxLat - minLat) * 0.1;
        final lngPadding = (maxLng - minLng) * 0.1;

        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat - latPadding, minLng - lngPadding),
              northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
            ),
            100.0, // padding
          ),
        );
      } catch (e) {
        // If bounds calculation fails, try to center on first log or site
        if (_filteredLogs.isNotEmpty) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_filteredLogs.first.latitude, _filteredLogs.first.longitude),
            ),
          );
        } else if (sitesToShow.isNotEmpty) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(sitesToShow.first.latitude, sitesToShow.first.longitude),
            ),
          );
        }
      }
    } else if (sitesToShow.isNotEmpty) {
      // If no filtered logs but we have filtered sites, center on the first site
      try {
        double minLat = sitesToShow.first.latitude;
        double maxLat = sitesToShow.first.latitude;
        double minLng = sitesToShow.first.longitude;
        double maxLng = sitesToShow.first.longitude;

        for (final site in sitesToShow) {
          minLat = minLat < site.latitude ? minLat : site.latitude;
          maxLat = maxLat > site.latitude ? maxLat : site.latitude;
          minLng = minLng < site.longitude ? minLng : site.longitude;
          maxLng = maxLng > site.longitude ? maxLng : site.longitude;
        }

        // Add padding
        final latPadding = (maxLat - minLat) * 0.1;
        final lngPadding = (maxLng - minLng) * 0.1;

        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat - latPadding, minLng - lngPadding),
              northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
            ),
            100.0, // padding
          ),
        );
      } catch (e) {
        // If bounds calculation fails, just center on first site
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(sitesToShow.first.latitude, sitesToShow.first.longitude),
          ),
        );
      }
    }
  }

  void _showFullScreenMap() {
    // Get current camera position from visible region
    double initialZoom = 14.0;

    if (_mapController != null) {
      _mapController!.getVisibleRegion().then((bounds) {
        // Calculate center from visible bounds
        final center = LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        );
        
        // Estimate zoom from bounds (rough calculation)
        final latDiff = bounds.northeast.latitude - bounds.southwest.latitude;
        final lngDiff = bounds.northeast.longitude - bounds.southwest.longitude;
        final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
        
        // Rough zoom estimation (this is approximate)
        if (maxDiff > 10) {
          initialZoom = 5.0;
        } else if (maxDiff > 5) {
          initialZoom = 7.0;
        } else if (maxDiff > 1) {
          initialZoom = 10.0;
        } else if (maxDiff > 0.1) {
          initialZoom = 12.0;
        } else {
          initialZoom = 14.0;
        }

        if (!mounted) return;
        final navigator = Navigator.of(context);
        navigator.push(
          MaterialPageRoute(
            builder: (context) => _FullScreenMapView(
              attendanceLogs: _filteredLogs,
              allAttendanceLogs: _attendanceLogs,
              sites: _sites,
              employees: _employees,
              selectedDate: _selectedDate,
              selectedSiteFilter: _selectedSiteFilter,
              selectedEmployeeFilter: _selectedEmployeeFilter,
              selectedPunchTypeFilter: _selectedPunchTypeFilter,
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: initialZoom,
              ),
              onMarkerTap: _showLogDetails,
              getMarkerHueForPunchType: _getMarkerHueForPunchType,
              customSiteMarker: _customSiteMarker,
              onDateChanged: (date) {
                setState(() => _selectedDate = date);
                _loadData();
              },
              onSiteFilterChanged: (siteId) {
                setState(() => _selectedSiteFilter = siteId);
              },
              onEmployeeFilterChanged: (employeeId) {
                setState(() => _selectedEmployeeFilter = employeeId);
              },
              onPunchTypeFilterChanged: (punchType) {
                setState(() => _selectedPunchTypeFilter = punchType);
              },
            ),
            fullscreenDialog: true,
          ),
        );
      }).catchError((e) {
        // Fallback if getting visible region fails
        _navigateToFullScreen();
      });
    } else {
      // No map controller, use fallback
      _navigateToFullScreen();
    }
  }

  void _navigateToFullScreen() {
    LatLng? initialPosition;
    if (_filteredLogs.isNotEmpty) {
      final firstLog = _filteredLogs.first;
      initialPosition = LatLng(firstLog.latitude, firstLog.longitude);
    } else if (_sites.isNotEmpty) {
      final firstSite = _sites.first;
      initialPosition = LatLng(firstSite.latitude, firstSite.longitude);
    } else {
      initialPosition = const LatLng(20.5937, 78.9629);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenMapView(
          attendanceLogs: _filteredLogs,
          allAttendanceLogs: _attendanceLogs,
          sites: _sites,
          employees: _employees,
          selectedDate: _selectedDate,
          selectedSiteFilter: _selectedSiteFilter,
          selectedEmployeeFilter: _selectedEmployeeFilter,
          selectedPunchTypeFilter: _selectedPunchTypeFilter,
          initialCameraPosition: CameraPosition(
            target: initialPosition!,
            zoom: _filteredLogs.isEmpty ? 10.0 : 14.0,
          ),
          onMarkerTap: _showLogDetails,
          getMarkerHueForPunchType: _getMarkerHueForPunchType,
          customSiteMarker: _customSiteMarker,
          onDateChanged: (date) {
            setState(() => _selectedDate = date);
            _loadData();
          },
          onSiteFilterChanged: (siteId) {
            setState(() => _selectedSiteFilter = siteId);
          },
          onEmployeeFilterChanged: (employeeId) {
            setState(() => _selectedEmployeeFilter = employeeId);
          },
          onPunchTypeFilterChanged: (punchType) {
            setState(() => _selectedPunchTypeFilter = punchType);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

// Full Screen Map View Widget
class _FullScreenMapView extends StatefulWidget {
  final List<GpsAttendanceLog> attendanceLogs;
  final List<GpsAttendanceLog> allAttendanceLogs;
  final List<Site> sites;
  final List<Employee> employees;
  final DateTime selectedDate;
  final String? selectedSiteFilter;
  final String? selectedEmployeeFilter;
  final String? selectedPunchTypeFilter;
  final CameraPosition? initialCameraPosition;
  final Function(GpsAttendanceLog) onMarkerTap;
  final double Function(String) getMarkerHueForPunchType;
  final BitmapDescriptor? customSiteMarker;
  final Function(DateTime) onDateChanged;
  final Function(String?) onSiteFilterChanged;
  final Function(String?) onEmployeeFilterChanged;
  final Function(String?) onPunchTypeFilterChanged;

  const _FullScreenMapView({
    required this.attendanceLogs,
    required this.allAttendanceLogs,
    required this.sites,
    required this.employees,
    required this.selectedDate,
    this.selectedSiteFilter,
    this.selectedEmployeeFilter,
    this.selectedPunchTypeFilter,
    this.initialCameraPosition,
    required this.onMarkerTap,
    required this.getMarkerHueForPunchType,
    this.customSiteMarker,
    required this.onDateChanged,
    required this.onSiteFilterChanged,
    required this.onEmployeeFilterChanged,
    required this.onPunchTypeFilterChanged,
  });

  @override
  State<_FullScreenMapView> createState() => _FullScreenMapViewState();
}

class _FullScreenMapViewState extends State<_FullScreenMapView> {
  GoogleMapController? _fullScreenMapController;
  bool _showFilters = true;
  late String? _selectedSiteFilter;
  late String? _selectedEmployeeFilter;
  late String? _selectedPunchTypeFilter;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedSiteFilter = widget.selectedSiteFilter;
    _selectedEmployeeFilter = widget.selectedEmployeeFilter;
    _selectedPunchTypeFilter = widget.selectedPunchTypeFilter;
    _selectedDate = widget.selectedDate;
  }

  @override
  void dispose() {
    _fullScreenMapController?.dispose();
    super.dispose();
  }

  List<GpsAttendanceLog> get _filteredLogs {
    return widget.allAttendanceLogs.where((log) {
      if (_selectedSiteFilter != null && _selectedSiteFilter != 'all') {
        if (log.siteId.toString() != _selectedSiteFilter) return false;
      }
      if (_selectedPunchTypeFilter != null && _selectedPunchTypeFilter != 'all') {
        if (log.punchType.toUpperCase() != _selectedPunchTypeFilter) return false;
      }
      if (_selectedEmployeeFilter != null && _selectedEmployeeFilter != 'all') {
        if (log.employeeId != _selectedEmployeeFilter) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateChanged(picked);
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final filteredLogs = _filteredLogs;
    
    for (int i = 0; i < filteredLogs.length; i++) {
      final log = filteredLogs[i];
      
      markers.add(
        Marker(
          markerId: MarkerId('attendance_${log.id}_$i'),
          position: LatLng(log.latitude, log.longitude),
          infoWindow: InfoWindow(
            title: log.employeeName ?? log.employeeId,
            snippet: '${log.punchTypeLabel}\n${DateFormat('dd MMM yyyy HH:mm').format(log.punchTime)}\n${log.siteName ?? 'Unknown Site'}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.getMarkerHueForPunchType(log.punchType),
          ),
          onTap: () => widget.onMarkerTap(log),
        ),
      );
    }

    // Add site markers (filtered if site filter is active)
    final sitesToShow = _selectedSiteFilter != null && _selectedSiteFilter != 'all'
        ? widget.sites.where((site) => site.id.toString() == _selectedSiteFilter).toList()
        : widget.sites;
    
    for (final site in sitesToShow) {
      markers.add(
        Marker(
          markerId: MarkerId('site_${site.id}'),
          position: LatLng(site.latitude, site.longitude),
          infoWindow: InfoWindow(
            title: site.siteName,
            snippet: '${site.siteCode}\nRadius: ${site.geofenceRadiusMeters}m',
          ),
          icon: widget.customSiteMarker ?? BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    final circles = <Circle>{};
    
    // Filter sites based on selected site filter
    final sitesToShow = _selectedSiteFilter != null && _selectedSiteFilter != 'all'
        ? widget.sites.where((site) => site.id.toString() == _selectedSiteFilter).toList()
        : widget.sites;
    
    for (final site in sitesToShow) {
      circles.add(
        Circle(
          circleId: CircleId('site_${site.id}'),
          center: LatLng(site.latitude, site.longitude),
          radius: site.geofenceRadiusMeters.toDouble(),
          strokeColor: Colors.blue.withValues(alpha: 0.5),
          strokeWidth: 2,
          fillColor: Colors.blue.withValues(alpha: 0.1),
        ),
      );
    }

    return circles;
  }

  void _fitBounds() {
    if (_fullScreenMapController == null) return;

    // Get filtered sites based on site filter
    final sitesToShow = _selectedSiteFilter != null && _selectedSiteFilter != 'all'
        ? widget.sites.where((site) => site.id.toString() == _selectedSiteFilter).toList()
        : widget.sites;

    // If we have filtered logs, use them; otherwise use filtered sites
    final filteredLogs = _filteredLogs;
    if (filteredLogs.isNotEmpty) {
      try {
        double minLat = filteredLogs.first.latitude;
        double maxLat = filteredLogs.first.latitude;
        double minLng = filteredLogs.first.longitude;
        double maxLng = filteredLogs.first.longitude;

        for (final log in filteredLogs) {
          minLat = minLat < log.latitude ? minLat : log.latitude;
          maxLat = maxLat > log.latitude ? maxLat : log.latitude;
          minLng = minLng < log.longitude ? minLng : log.longitude;
          maxLng = maxLng > log.longitude ? maxLng : log.longitude;
        }

        // Also include filtered sites in bounds calculation
        for (final site in sitesToShow) {
          minLat = minLat < site.latitude ? minLat : site.latitude;
          maxLat = maxLat > site.latitude ? maxLat : site.latitude;
          minLng = minLng < site.longitude ? minLng : site.longitude;
          maxLng = maxLng > site.longitude ? maxLng : site.longitude;
        }

        // Add padding
        final latPadding = (maxLat - minLat) * 0.1;
        final lngPadding = (maxLng - minLng) * 0.1;

        _fullScreenMapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat - latPadding, minLng - lngPadding),
              northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
            ),
            100.0, // padding
          ),
        );
      } catch (e) {
        // If bounds calculation fails, try to center on first log or site
        if (filteredLogs.isNotEmpty) {
          _fullScreenMapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(filteredLogs.first.latitude, filteredLogs.first.longitude),
            ),
          );
        } else if (sitesToShow.isNotEmpty) {
          _fullScreenMapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(sitesToShow.first.latitude, sitesToShow.first.longitude),
            ),
          );
        }
      }
    } else if (sitesToShow.isNotEmpty) {
      // If no filtered logs but we have filtered sites, center on the first site
      try {
        double minLat = sitesToShow.first.latitude;
        double maxLat = sitesToShow.first.latitude;
        double minLng = sitesToShow.first.longitude;
        double maxLng = sitesToShow.first.longitude;

        for (final site in sitesToShow) {
          minLat = minLat < site.latitude ? minLat : site.latitude;
          maxLat = maxLat > site.latitude ? maxLat : site.latitude;
          minLng = minLng < site.longitude ? minLng : site.longitude;
          maxLng = maxLng > site.longitude ? maxLng : site.longitude;
        }

        // Add padding
        final latPadding = (maxLat - minLat) * 0.1;
        final lngPadding = (maxLng - minLng) * 0.1;

        _fullScreenMapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat - latPadding, minLng - lngPadding),
              northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
            ),
            100.0, // padding
          ),
        );
      } catch (e) {
        // If bounds calculation fails, just center on first site
        _fullScreenMapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(sitesToShow.first.latitude, sitesToShow.first.longitude),
          ),
        );
      }
    }
  }

  Widget _buildFilters(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              )
            : BorderSide.none,
      ),
      color: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : colorScheme.surface,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date Picker
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark 
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Site Filter
            DropdownButtonFormField<String>(
              initialValue: _selectedSiteFilter,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.business,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                hintText: 'Filter by Site',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark 
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark 
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(minHeight: 44),
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    'All Sites',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
                ...widget.sites.map((site) => DropdownMenuItem(
                      value: site.id.toString(),
                      child: Text(
                        site.siteName,
                        style: TextStyle(color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSiteFilter = value;
                });
                widget.onSiteFilterChanged(value);
                // Refresh markers after filter change
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && _fullScreenMapController != null) {
                    _fitBounds();
                  }
                });
              },
            ),
            const SizedBox(height: 10),

            // Employee Filter
            DropdownButtonFormField<String>(
              initialValue: _selectedEmployeeFilter,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                hintText: 'Filter by Employee',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark 
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark 
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(minHeight: 44),
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    'All Employees',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
                ...widget.employees.map((employee) => DropdownMenuItem(
                      value: employee.employeeId,
                      child: Text(
                        '${employee.firstName} ${employee.lastName}',
                        style: TextStyle(color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (value) {
                widget.onEmployeeFilterChanged(value);
                setState(() {});
                // Refresh markers after filter change
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && _fullScreenMapController != null) {
                    _fitBounds();
                  }
                });
              },
            ),
            const SizedBox(height: 10),

            // Punch Type Filter
            DropdownButtonFormField<String>(
              initialValue: _selectedPunchTypeFilter,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                hintText: 'Filter by Punch',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark 
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark 
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(minHeight: 44),
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Punches')),
                DropdownMenuItem(value: 'CHECK_IN', child: Text('Check In')),
                DropdownMenuItem(value: 'LUNCH_OUT', child: Text('Lunch Out')),
                DropdownMenuItem(value: 'LUNCH_IN', child: Text('Lunch In')),
                DropdownMenuItem(value: 'CHECK_OUT', child: Text('Check Out')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPunchTypeFilter = value;
                });
                widget.onPunchTypeFilterChanged(value);
                // Refresh markers after filter change
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && _fullScreenMapController != null) {
                    _fitBounds();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Calculate initial camera position if not provided
    LatLng initialPosition;
    double initialZoom = 14.0;

    if (widget.initialCameraPosition != null) {
      initialPosition = widget.initialCameraPosition!.target;
      initialZoom = widget.initialCameraPosition!.zoom;
    } else {
      final filteredLogs = _filteredLogs;
      if (filteredLogs.isNotEmpty) {
        final firstLog = filteredLogs.first;
        initialPosition = LatLng(firstLog.latitude, firstLog.longitude);
      } else if (widget.sites.isNotEmpty) {
        final firstSite = widget.sites.first;
        initialPosition = LatLng(firstSite.latitude, firstSite.longitude);
      } else {
        initialPosition = const LatLng(20.5937, 78.9629);
        initialZoom = 10.0;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Full Screen Map',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Fit Bounds',
            onPressed: _fitBounds,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: initialZoom,
            ),
            onMapCreated: (GoogleMapController controller) {
              _fullScreenMapController = controller;
              // Delay fit bounds to ensure markers are built
              Future.delayed(const Duration(milliseconds: 500), () {
                _fitBounds();
              });
            },
            markers: _buildMarkers(),
            circles: _buildCircles(),
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
          if (_showFilters)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFilters(colorScheme),
            ),
        ],
      ),
    );
  }
}


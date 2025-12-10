import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/site.dart';
import '../../core/services/site_service.dart';
import '../../widgets/admin_layout.dart';

class GpsAttendanceMapScreen extends StatefulWidget {
  const GpsAttendanceMapScreen({super.key});

  @override
  State<GpsAttendanceMapScreen> createState() => _GpsAttendanceMapScreenState();
}

class _GpsAttendanceMapScreenState extends State<GpsAttendanceMapScreen> {
  final SiteService _siteService = SiteService();
  GoogleMapController? _mapController;
  List<GpsAttendanceLog> _attendanceLogs = [];
  List<Site> _sites = [];
  bool _isLoading = true;
  String? _error;
  String? _mapError;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSiteFilter;
  String? _selectedPunchTypeFilter;
  BitmapDescriptor? _customSiteMarker;
  bool _isLegendExpanded = false;
  
  @override
  void dispose() {
    _mapController?.dispose();
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
      final sites = await _siteService.getAllSites();
      final logs = await _siteService.getMapDashboardData(_selectedDate);
      
      setState(() {
        _sites = sites;
        _attendanceLogs = logs;
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
      return true;
    }).toList();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  Future<BitmapDescriptor> _createCustomSiteMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Size size = const Size(100, 120);

    // Draw the marker pin shape (teardrop design)
    final Paint pinPaint = Paint()
      ..color = const Color(0xFF1976D2) // Blue color for site
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

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

    return BitmapDescriptor.fromBytes(uint8List);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isMobile = _isMobile(context);
    
    return AdminLayout(
      currentRoute: '/admin/gps-attendance-map',
      title: const Text('GPS Attendance Dashboard'),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMobileFilters(),
            ),

            // Summary Stats
            Container(
              padding: const EdgeInsets.all(12),
              child: _buildMobileSummaryStats(),
            ),

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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildDesktopFilters(),
          ),

          // Summary Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildDesktopSummaryStats(),
          ),

          // Main Content - Map and List
          Expanded(
            child: _buildDesktopMainContent(colorScheme),
          ),
        ],
      );
    }
  }

  Widget _buildMobileFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Picker
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Site Filter
        DropdownButtonFormField<String>(
          value: _selectedSiteFilter,
          decoration: const InputDecoration(
            labelText: 'Filter by Site',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Sites')),
            ..._sites.map((site) => DropdownMenuItem(
                  value: site.id.toString(),
                  child: Text(site.siteName),
                )),
          ],
          onChanged: (value) {
            setState(() => _selectedSiteFilter = value);
          },
        ),
        const SizedBox(height: 12),

        // Punch Type Filter
        DropdownButtonFormField<String>(
          value: _selectedPunchTypeFilter,
          decoration: const InputDecoration(
            labelText: 'Filter by Punch',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
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
          },
        ),
        const SizedBox(height: 12),

        // Legend - Mobile version
        _buildMobileLegend(),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Date Picker
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Site Filter
        Flexible(
          flex: 1,
          child: SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: _selectedSiteFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by Site',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Sites')),
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
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Punch Type Filter
        Flexible(
          flex: 1,
          child: SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              value: _selectedPunchTypeFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by Punch',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
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
              },
            ),
          ),
        ),

        // Legend - Compact version (already handled in map view, so remove from filters)
      ],
    );
  }

  Widget _buildMobileSummaryStats() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildSummaryCard('Total Punches', _filteredLogs.length, Colors.blue, isMobile: true),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Check Ins',
            _filteredLogs.where((l) => l.punchType.toUpperCase() == 'CHECK_IN').length,
            const Color(0xFF4CAF50),
            isMobile: true,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Lunch Out',
            _filteredLogs.where((l) => l.punchType.toUpperCase() == 'LUNCH_OUT').length,
            const Color(0xFFFF9800),
            isMobile: true,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Lunch In',
            _filteredLogs.where((l) => l.punchType.toUpperCase() == 'LUNCH_IN').length,
            const Color(0xFF2196F3),
            isMobile: true,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Check Outs',
            _filteredLogs.where((l) => l.punchType.toUpperCase() == 'CHECK_OUT').length,
            const Color(0xFFF44336),
            isMobile: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSummaryStats() {
    return Row(
      children: [
        _buildSummaryCard('Total Punches', _filteredLogs.length, Colors.blue),
        const SizedBox(width: 16),
        _buildSummaryCard(
          'Check Ins',
          _filteredLogs.where((l) => l.punchType.toUpperCase() == 'CHECK_IN').length,
          const Color(0xFF4CAF50),
        ),
        const SizedBox(width: 16),
        _buildSummaryCard(
          'Lunch Out',
          _filteredLogs.where((l) => l.punchType.toUpperCase() == 'LUNCH_OUT').length,
          const Color(0xFFFF9800),
        ),
        const SizedBox(width: 16),
        _buildSummaryCard(
          'Lunch In',
          _filteredLogs.where((l) => l.punchType.toUpperCase() == 'LUNCH_IN').length,
          const Color(0xFF2196F3),
        ),
        const SizedBox(width: 16),
        _buildSummaryCard(
          'Check Outs',
          _filteredLogs.where((l) => l.punchType.toUpperCase() == 'CHECK_OUT').length,
          const Color(0xFFF44336),
        ),
      ],
    );
  }

  Widget _buildMobileMainContent(ColorScheme colorScheme) {
    return Column(
      children: [
        // Map View
        Container(
          height: 300,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildMapView(),
        ),

        // Attendance List
        Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance Log (${_filteredLogs.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No attendance records',
                              style: TextStyle(color: Colors.grey[600]),
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
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildMapView(),
          ),
        ),

        // Attendance List - Below Map (40% of available space)
        Expanded(
          flex: 4,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance Log (${_filteredLogs.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No attendance records',
                                style: TextStyle(color: Colors.grey[600]),
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
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem('Check In', const Color(0xFF4CAF50)),
        _buildLegendItem('Lunch Out', const Color(0xFFFF9800)),
        _buildLegendItem('Lunch In', const Color(0xFF2196F3)),
        _buildLegendItem('Check Out', const Color(0xFFF44336)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color, {bool isMobile = false}) {
    final card = Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      width: isMobile ? 100 : null,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: color.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (isMobile) {
      return card;
    } else {
      return Expanded(child: card);
    }
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem('Check In', const Color(0xFF4CAF50)),
        const SizedBox(width: 16),
        _buildLegendItem('Lunch Out', const Color(0xFFFF9800)),
        const SizedBox(width: 16),
        _buildLegendItem('Lunch In', const Color(0xFF2196F3)),
        const SizedBox(width: 16),
        _buildLegendItem('Check Out', const Color(0xFFF44336)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: _isMobile(context) ? 11 : 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLegend() {
    final isMobile = _isMobile(context);
    return Card(
      child: _isLegendExpanded
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? 200 : 220,
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: isMobile ? 16 : 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Legend',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 12 : 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _isLegendExpanded = false;
                            });
                          },
                          tooltip: 'Hide Legend',
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    _buildLegendItem('Check In', Colors.green),
                    SizedBox(height: isMobile ? 3 : 4),
                    _buildLegendItem('Lunch Out', Colors.orange),
                    SizedBox(height: isMobile ? 3 : 4),
                    _buildLegendItem('Lunch In', Colors.blue),
                    SizedBox(height: isMobile ? 3 : 4),
                    _buildLegendItem('Check Out', Colors.red),
                    SizedBox(height: isMobile ? 6 : 8),
                    const Divider(height: 1),
                    SizedBox(height: isMobile ? 6 : 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isMobile ? 12 : 14,
                          height: isMobile ? 12 : 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey,
                              width: isMobile ? 1.5 : 2,
                            ),
                            color: Colors.transparent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Site Boundary',
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : IconButton(
              icon: Icon(
                Icons.info_outline,
                size: isMobile ? 20 : 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _isLegendExpanded = true;
                });
              },
              tooltip: 'Show Legend',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.all(isMobile ? 8 : 10),
              ),
            ),
    );
  }

  Widget _buildAttendanceLogTile(GpsAttendanceLog log) {
    final isMobile = _isMobile(context);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 6 : 4,
      ),
      dense: isMobile,
      leading: Container(
        width: isMobile ? 36 : 40,
        height: isMobile ? 36 : 40,
        decoration: BoxDecoration(
          color: Color(log.punchTypeColor).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getPunchTypeIcon(log.punchType),
          color: Color(log.punchTypeColor),
          size: isMobile ? 18 : 20,
        ),
      ),
      title: Text(
        log.employeeName ?? log.employeeId,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 13 : 14,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            log.punchTypeLabel,
            style: TextStyle(
              color: Color(log.punchTypeColor),
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (log.siteName != null)
            Text(
              log.siteName!,
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          if (log.distanceFromSite != null)
            Text(
              '${log.distanceFromSite!.toStringAsFixed(0)}m from site',
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(log.punchTime),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 14,
            ),
          ),
          if (!log.isInsideGeofence)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Outside',
                style: TextStyle(fontSize: 9, color: Colors.red),
              ),
            ),
        ],
      ),
      isThreeLine: !isMobile,
      onTap: () => _showLogDetails(log),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.punchTypeLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Employee', log.employeeName ?? log.employeeId),
            _buildDetailRow('Time', DateFormat('HH:mm:ss').format(log.punchTime)),
            _buildDetailRow('Site', log.siteName ?? 'Not specified'),
            _buildDetailRow('Coordinates', '${log.latitude.toStringAsFixed(6)}, ${log.longitude.toStringAsFixed(6)}'),
            if (log.distanceFromSite != null)
              _buildDetailRow('Distance', '${log.distanceFromSite!.toStringAsFixed(0)} meters'),
            _buildDetailRow('Inside Geofence', log.isInsideGeofence ? 'Yes' : 'No'),
            _buildDetailRow('Mock Location', log.isMockLocation ? 'Yes' : 'No'),
            if (log.deviceName != null)
              _buildDetailRow('Device', log.deviceName!),
            _buildDetailRow('Network', log.networkStatus ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'No attendance logs or sites found for the selected date',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Calculate initial camera position
    LatLng? initialPosition;
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
            target: initialPosition!,
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
          zoomControlsEnabled: true,
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
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Map Error',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _mapError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
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
        // Full Screen Button
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton(
            mini: _isMobile(context),
            onPressed: _showFullScreenMap,
            tooltip: 'Full Screen',
            child: Icon(
              Icons.fullscreen,
              size: _isMobile(context) ? 20 : 24,
            ),
          ),
        ),
        // Legend - Compact with info icon
        Positioned(
          top: 16,
          right: 16,
          child: _buildCompactLegend(),
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

    // Add site markers
    for (final site in _sites) {
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
    
    for (final site in _sites) {
      circles.add(
        Circle(
          circleId: CircleId('site_${site.id}'),
          center: LatLng(site.latitude, site.longitude),
          radius: site.geofenceRadiusMeters.toDouble(),
          strokeColor: Colors.blue.withOpacity(0.5),
          strokeWidth: 2,
          fillColor: Colors.blue.withOpacity(0.1),
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
    if (_mapController == null || _filteredLogs.isEmpty) return;

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
      // If bounds calculation fails, just center on first log
      if (_filteredLogs.isNotEmpty) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_filteredLogs.first.latitude, _filteredLogs.first.longitude),
          ),
        );
      }
    }
  }

  void _showFullScreenMap() {
    // Get current camera position from visible region
    LatLng? initialPosition;
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

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _FullScreenMapView(
              attendanceLogs: _filteredLogs,
              sites: _sites,
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: initialZoom,
              ),
              onMarkerTap: _showLogDetails,
              getMarkerHueForPunchType: _getMarkerHueForPunchType,
              customSiteMarker: _customSiteMarker,
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
          sites: _sites,
          initialCameraPosition: CameraPosition(
            target: initialPosition!,
            zoom: _filteredLogs.isEmpty ? 10.0 : 14.0,
          ),
          onMarkerTap: _showLogDetails,
          getMarkerHueForPunchType: _getMarkerHueForPunchType,
          customSiteMarker: _customSiteMarker,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

// Full Screen Map View Widget
class _FullScreenMapView extends StatefulWidget {
  final List<GpsAttendanceLog> attendanceLogs;
  final List<Site> sites;
  final CameraPosition? initialCameraPosition;
  final Function(GpsAttendanceLog) onMarkerTap;
  final double Function(String) getMarkerHueForPunchType;
  final BitmapDescriptor? customSiteMarker;

  const _FullScreenMapView({
    required this.attendanceLogs,
    required this.sites,
    this.initialCameraPosition,
    required this.onMarkerTap,
    required this.getMarkerHueForPunchType,
    this.customSiteMarker,
  });

  @override
  State<_FullScreenMapView> createState() => _FullScreenMapViewState();
}

class _FullScreenMapViewState extends State<_FullScreenMapView> {
  GoogleMapController? _fullScreenMapController;
  bool _isLegendExpanded = false;

  @override
  void dispose() {
    _fullScreenMapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    for (int i = 0; i < widget.attendanceLogs.length; i++) {
      final log = widget.attendanceLogs[i];
      
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

    // Add site markers
    for (final site in widget.sites) {
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
    
    for (final site in widget.sites) {
      circles.add(
        Circle(
          circleId: CircleId('site_${site.id}'),
          center: LatLng(site.latitude, site.longitude),
          radius: site.geofenceRadiusMeters.toDouble(),
          strokeColor: Colors.blue.withOpacity(0.5),
          strokeWidth: 2,
          fillColor: Colors.blue.withOpacity(0.1),
        ),
      );
    }

    return circles;
  }

  void _fitBounds() {
    if (_fullScreenMapController == null || widget.attendanceLogs.isEmpty) return;

    try {
      double minLat = widget.attendanceLogs.first.latitude;
      double maxLat = widget.attendanceLogs.first.latitude;
      double minLng = widget.attendanceLogs.first.longitude;
      double maxLng = widget.attendanceLogs.first.longitude;

      for (final log in widget.attendanceLogs) {
        minLat = minLat < log.latitude ? minLat : log.latitude;
        maxLat = maxLat > log.latitude ? maxLat : log.latitude;
        minLng = minLng < log.longitude ? minLng : log.longitude;
        maxLng = maxLng > log.longitude ? maxLng : log.longitude;
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
      // If bounds calculation fails, just center on first log
      if (widget.attendanceLogs.isNotEmpty) {
        _fullScreenMapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(widget.attendanceLogs.first.latitude, widget.attendanceLogs.first.longitude),
          ),
        );
      }
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFullScreenLegend() {
    return Card(
      color: Colors.white,
      child: _isLegendExpanded
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Legend',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey[900],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: Colors.grey[700]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _isLegendExpanded = false;
                          });
                        },
                        tooltip: 'Hide Legend',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem('Check In', Colors.green),
                  _buildLegendItem('Lunch Out', Colors.orange),
                  _buildLegendItem('Lunch In', Colors.blue),
                  _buildLegendItem('Check Out', Colors.red),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 2),
                          color: Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Site Boundary', style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                    ],
                  ),
                ],
              ),
            )
          : IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _isLegendExpanded = true;
                });
              },
              tooltip: 'Show Legend',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(10),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate initial camera position if not provided
    LatLng initialPosition;
    double initialZoom = 14.0;

    if (widget.initialCameraPosition != null) {
      initialPosition = widget.initialCameraPosition!.target;
      initialZoom = widget.initialCameraPosition!.zoom;
    } else if (widget.attendanceLogs.isNotEmpty) {
      final firstLog = widget.attendanceLogs.first;
      initialPosition = LatLng(firstLog.latitude, firstLog.longitude);
    } else if (widget.sites.isNotEmpty) {
      final firstSite = widget.sites.first;
      initialPosition = LatLng(firstSite.latitude, firstSite.longitude);
    } else {
      initialPosition = const LatLng(20.5937, 78.9629);
      initialZoom = 10.0;
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
              _fitBounds();
            },
            markers: _buildMarkers(),
            circles: _buildCircles(),
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
          // Legend - Compact with info icon
          Positioned(
            top: 16,
            right: 16,
            child: _buildFullScreenLegend(),
          ),
        ],
      ),
    );
  }
}


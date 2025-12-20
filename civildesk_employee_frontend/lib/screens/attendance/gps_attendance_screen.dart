import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/services/location_service.dart';
import '../../core/services/gps_attendance_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/site.dart';
import '../../widgets/employee_layout.dart';
import '../../core/constants/app_routes.dart';

class GpsAttendanceScreen extends StatefulWidget {
  const GpsAttendanceScreen({super.key});

  @override
  State<GpsAttendanceScreen> createState() => _GpsAttendanceScreenState();
}

class _GpsAttendanceScreenState extends State<GpsAttendanceScreen> {
  final LocationService _locationService = LocationService();
  final GpsAttendanceService _attendanceService = GpsAttendanceService();

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _isFetchingLocation = false; // Prevent multiple simultaneous requests
  String? _error;
  Position? _currentPosition;
  List<Site> _assignedSites = [];
  List<Map<String, dynamic>> _sitesWithDistance = []; // Sites with calculated distances
  Site? _nearestSite;
  double? _distanceFromSite;
  List<GpsAttendanceLog> _todayLogs = [];
  String? _employeeId;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure the widget is built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    // Clean up any ongoing operations
    _isFetchingLocation = false;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get employee ID from authenticated user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Fetch employee data to get employeeId
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      ));

      final response = await dio.get('/employees/user/$userId').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final employeeData = data['data'] as Map<String, dynamic>;
          _employeeId = employeeData['employeeId'] as String?;
        }
      }

      if (_employeeId == null || _employeeId!.isEmpty) {
        throw Exception('Employee ID not found. Please contact administrator.');
      }

      // Load assigned sites and attendance in parallel
      final results = await Future.wait([
        _attendanceService.getAssignedSites(_employeeId!),
        _attendanceService.getTodayAttendance(_employeeId!),
      ]);

      if (!mounted) return;

      setState(() {
        _assignedSites = results[0] as List<Site>;
        _todayLogs = results[1] as List<GpsAttendanceLog>;
      });

      // Get current location separately (non-blocking) - don't await
      // This prevents blocking the UI while location is being fetched
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _getCurrentLocation();
        }
      });

      // Calculate distances if position is already available
      if (_currentPosition != null) {
        _calculateSitesDistance();
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        if (e is DioException) {
          if (e.response?.data != null && e.response?.data['message'] != null) {
            _error = e.response?.data['message'];
          } else if (e.type == DioExceptionType.connectionTimeout || 
                     e.type == DioExceptionType.receiveTimeout) {
            _error = 'Connection timeout. Please check your internet connection.';
          } else {
            _error = 'Network error: ${e.message ?? "Unknown error"}';
          }
        } else {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted || _isFetchingLocation) return;
    
    _isFetchingLocation = true;
    
    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
        // Don't clear error here, keep previous errors if any
      });
    }

    try {
      // First check if we have permission with timeout
      final hasPermission = await _locationService.hasPermission()
          .timeout(const Duration(seconds: 5));
      
      if (!hasPermission) {
        // Request permission with timeout
        await _locationService.requestPermission()
            .timeout(const Duration(seconds: 10));
      }

      // Get position with timeout
      final position = await _locationService.getCurrentPosition()
          .timeout(const Duration(seconds: 15));
      
      if (!mounted) return;
      
      // Check for mock location
      if (position.isMocked) {
        throw LocationException('Mock location detected. Please disable mock location apps.');
      }

      setState(() {
        _currentPosition = position;
        _findNearestSite();
        _calculateSitesDistance();
        _error = null; // Clear any previous errors only on success
      });
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (errorMessage.contains('permanently denied')) {
        errorMessage = 'Location permission is permanently denied. Please enable it in your device settings.\n\nSettings > Apps > Civildesk Employee > Permissions > Location';
      } else if (errorMessage.contains('denied')) {
        errorMessage = 'Location permission is required to mark attendance. Please grant location permission.';
      } else if (errorMessage.contains('disabled')) {
        errorMessage = 'Location services are disabled. Please enable location services in your device settings.';
      }
      
      setState(() {
        // Only update error if it's a location-specific error
        if (errorMessage.contains('location') || errorMessage.contains('permission') || errorMessage.contains('timeout')) {
          _error = errorMessage;
        }
        // Otherwise keep the previous error (like employee ID error)
      });
    } finally {
      _isFetchingLocation = false;
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _findNearestSite() {
    if (_currentPosition == null || _assignedSites.isEmpty) return;

    double minDistance = double.infinity;
    Site? nearest;

    for (final site in _assignedSites) {
      final distance = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        site.latitude,
        site.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = site;
      }
    }

    setState(() {
      _nearestSite = nearest;
      _distanceFromSite = minDistance;
    });
  }

  void _calculateSitesDistance() {
    if (_currentPosition == null || _assignedSites.isEmpty) {
      _sitesWithDistance = [];
      return;
    }

    _sitesWithDistance = _assignedSites.map((site) {
      final distance = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        site.latitude,
        site.longitude,
      );
      return {
        'site': site,
        'distance': distance,
        'isInsideGeofence': distance <= site.geofenceRadiusMeters,
      };
    }).toList();

    // Sort by distance (closest first)
    _sitesWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
  }

  bool get _isInsideGeofence {
    if (_nearestSite == null || _distanceFromSite == null) {
      // If no site assigned, allow marking (will be validated on server)
      // If location not determined yet, return false to wait
      return _assignedSites.isEmpty;
    }
    return _distanceFromSite! <= _nearestSite!.geofenceRadiusMeters;
  }

  String? get _nextPunchType {
    final hasCheckIn = _todayLogs.any((l) => l.punchType.toUpperCase() == 'CHECK_IN');
    final hasLunchOut = _todayLogs.any((l) => l.punchType.toUpperCase() == 'LUNCH_OUT');
    final hasLunchIn = _todayLogs.any((l) => l.punchType.toUpperCase() == 'LUNCH_IN');
    final hasCheckOut = _todayLogs.any((l) => l.punchType.toUpperCase() == 'CHECK_OUT');

    if (!hasCheckIn) return 'CHECK_IN';
    if (!hasLunchOut) return 'LUNCH_OUT';
    if (!hasLunchIn) return 'LUNCH_IN';
    if (!hasCheckOut) return 'CHECK_OUT';
    return null;
  }

  Future<void> _markAttendance(String punchType) async {
    if (_employeeId == null || _employeeId!.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Employee ID not found. Please refresh the page.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // CRITICAL: Always fetch fresh location right before marking attendance
      // This prevents using stale/cached location data
      Position? freshPosition;
      try {
        freshPosition = await _locationService.getCurrentPosition();
        
        // Check for mock location
        if (freshPosition.isMocked) {
          throw LocationException('Mock location detected. Please disable mock location apps.');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.contains('timeout')) {
          errorMessage = 'Location request timed out. Please try again.';
        } else if (errorMessage.contains('permission')) {
          errorMessage = 'Location permission is required. Please grant location permission.';
        }
        
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Find nearest site with fresh location
      Site? nearestSiteForFreshLocation;
      double? distanceFromSiteForFreshLocation;
      
      if (_assignedSites.isNotEmpty) {
        double minDistance = double.infinity;
        Site? nearest;
        
        for (final site in _assignedSites) {
          final distance = _locationService.calculateDistance(
            freshPosition.latitude,
            freshPosition.longitude,
            site.latitude,
            site.longitude,
          );
          
          if (distance < minDistance) {
            minDistance = distance;
            nearest = site;
          }
        }
        
        nearestSiteForFreshLocation = nearest;
        distanceFromSiteForFreshLocation = minDistance;
      }

      // Validate that employee is inside geofence with fresh location
      if (nearestSiteForFreshLocation == null || distanceFromSiteForFreshLocation == null) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'You are not assigned to any site or location could not be determined. Please contact your administrator.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final isInsideGeofence = distanceFromSiteForFreshLocation <= nearestSiteForFreshLocation.geofenceRadiusMeters;
      
      if (!isInsideGeofence) {
        setState(() => _isLoading = false);
        final distanceToMove = (distanceFromSiteForFreshLocation - nearestSiteForFreshLocation.geofenceRadiusMeters).clamp(0, double.infinity);
        Fluttertoast.showToast(
          msg: 'You must be inside the site to mark attendance. '
              'You are ${distanceFromSiteForFreshLocation.toStringAsFixed(0)}m away. '
              'Please move ${distanceToMove.toStringAsFixed(0)}m closer (within ${nearestSiteForFreshLocation.geofenceRadiusMeters}m of the site).',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Create request with fresh location and current timestamp in UTC
      // Using UTC ensures consistent time comparison regardless of device/server timezone
      final locationCaptureTime = DateTime.now().toUtc();
      final request = GpsAttendanceRequest(
        employeeId: _employeeId!,
        punchType: punchType,
        latitude: freshPosition.latitude,
        longitude: freshPosition.longitude,
        accuracyMeters: freshPosition.accuracy,
        altitude: freshPosition.altitude,
        isMockLocation: freshPosition.isMocked,
        networkStatus: 'ONLINE',
        siteId: nearestSiteForFreshLocation.id,
        deviceName: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
        locationTimestamp: locationCaptureTime, // Send UTC timestamp to backend for validation
      );

      await _attendanceService.markAttendance(request);

      // Reload attendance logs
      _todayLogs = await _attendanceService.getTodayAttendance(_employeeId!);

      if (mounted) {
        // Update current position with fresh location
        setState(() {
          _currentPosition = freshPosition;
          _nearestSite = nearestSiteForFreshLocation;
          _distanceFromSite = distanceFromSiteForFreshLocation;
        });
        
        // Recalculate distances with fresh location
        _calculateSitesDistance();
        
        final siteName = nearestSiteForFreshLocation.siteName;
        final time = _formatTime12Hour(DateTime.now());
        
        Fluttertoast.showToast(
          msg: '${_getPunchTypeLabel(punchType)} at $siteName — $time',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF16A34A),
          textColor: Colors.white,
        );
        
        // Refresh the UI
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        
        // Show user-friendly error messages
        if (errorMessage.contains('Mock location')) {
          errorMessage = 'Mock location detected. Please disable mock location apps and try again.';
        } else if (errorMessage.contains('geofence') || errorMessage.contains('boundary')) {
          errorMessage = 'You are outside the site boundary. Please move closer to the site.';
        } else if (errorMessage.contains('already recorded')) {
          errorMessage = 'This punch has already been recorded for today.';
        } else if (errorMessage.contains('sequence') || errorMessage.contains('first')) {
          errorMessage = 'Please mark punches in the correct sequence.';
        }
        
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getPunchTypeLabel(String punchType) {
    switch (punchType.toUpperCase()) {
      case 'CHECK_IN':
        return 'Check In';
      case 'LUNCH_OUT':
        return 'Lunch Out';
      case 'LUNCH_IN':
        return 'Lunch In';
      case 'CHECK_OUT':
        return 'Check Out';
      default:
        return punchType;
    }
  }

  Color _getPunchTypeColor(String punchType) {
    switch (punchType.toUpperCase()) {
      case 'CHECK_IN':
        return Colors.green;
      case 'LUNCH_OUT':
        return Colors.orange;
      case 'LUNCH_IN':
        return Colors.blue;
      case 'CHECK_OUT':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EmployeeLayout(
      currentRoute: AppRoutes.gpsAttendance,
      title: const Text('GPS Attendance'),
      actions: [],
      child: _isLoading && _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _currentPosition == null
              ? _buildErrorView()
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: () async {
                    await _loadData();
                    if (_currentPosition == null) {
                      await _getCurrentLocation();
                    } else {
                      // Recalculate distances if position is already available
                      _calculateSitesDistance();
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current Time Card
                        _buildTimeCard(colorScheme),
                        const SizedBox(height: 2),

                        // Combined Location & Assigned Sites Card
                        _buildCombinedLocationAndSitesCard(colorScheme),
                        const SizedBox(height: 2),

                        // Punch Buttons
                        _buildPunchButtons(colorScheme),
                        const SizedBox(height: 2),

                        // Today's Attendance Log
                        _buildTodayLog(colorScheme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    final isPermissionError = _error != null && 
        (_error!.toLowerCase().contains('permission') || 
         _error!.toLowerCase().contains('denied'));
    final isPermanentlyDenied = _error != null && 
        _error!.toLowerCase().contains('permanently denied');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Location Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unable to get location',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (isPermanentlyDenied) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5B36),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: () async {
                if (isPermissionError) {
                  // Request permission again
                  await _getCurrentLocation();
                } else {
                  // Retry loading data
                  await _loadData();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format distance
  String _formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Helper method to format time in 12-hour format
  String _formatTime12Hour(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  Widget _buildTimeCard(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Create adaptive gradient colors based on theme and palette
    Color primaryColor = colorScheme.primary;
    Color primaryContainerColor = colorScheme.primaryContainer;
    
    // For dark theme, use slightly lighter variants for better contrast
    if (isDark) {
      primaryColor = Color.alphaBlend(
        Colors.white.withValues(alpha: 0.1),
        colorScheme.primary,
      );
      primaryContainerColor = Color.alphaBlend(
        Colors.white.withValues(alpha: 0.15),
        colorScheme.primaryContainer,
      );
    } else {
      // For light theme, use slightly darker variants for depth
      primaryColor = Color.alphaBlend(
        Colors.black.withValues(alpha: 0.1),
        colorScheme.primary,
      );
      primaryContainerColor = colorScheme.primaryContainer;
    }
    
    // Determine text color based on contrast
    final textColor = _getContrastingTextColor(primaryColor);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 105,
          maxHeight: 105,
        ),
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryContainerColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Text(
                    DateFormat('hh:mm:ss a').format(DateTime.now()),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine contrasting text color
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    // Use white text for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildCombinedLocationAndSitesCard(ColorScheme colorScheme) {
    final accuracy = _currentPosition?.accuracy ?? 0.0;
    final accuracyColor = accuracy <= 20
        ? const Color(0xFF16A34A) // Green for good accuracy
        : accuracy <= 50
            ? const Color(0xFFF59E0B) // Orange for medium
            : Colors.red; // Red for poor

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location Status Section
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Location & Sites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                ),
                const Spacer(),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Refresh Location',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Location Details
            if (_currentPosition != null) ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accuracyColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Accuracy: ±${accuracy.toStringAsFixed(0)} m',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• GPS',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_nearestSite != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isInsideGeofence
                        ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isInsideGeofence
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFF59E0B),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: _isInsideGeofence
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_nearestSite!.siteName} • ${_formatDistance(_distanceFromSite ?? 0)} • ${_isInsideGeofence ? "Inside" : "Outside"}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (!_isInsideGeofence) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Move ${_formatDistance((_distanceFromSite! - _nearestSite!.geofenceRadiusMeters).clamp(0, double.infinity))} closer to mark attendance',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  accuracy <= 20
                      ? 'Good accuracy (±${accuracy.toStringAsFixed(0)} m)'
                      : 'Low accuracy — move to open sky',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.gps_off,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for location...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Assigned Sites Section
            if (_assignedSites.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Assigned Sites',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 10),
              if (_sitesWithDistance.isEmpty && _currentPosition == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Waiting for location to calculate distances...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else if (_sitesWithDistance.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'No assigned sites',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ..._sitesWithDistance.map((siteData) {
                  final site = siteData['site'] as Site;
                  final distance = siteData['distance'] as double;
                  final isInside = siteData['isInsideGeofence'] as bool;
                  final isNearest = _nearestSite?.id == site.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    constraints: const BoxConstraints(
                      minHeight: 64,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // TODO: Expand to show full address, map preview, and actions
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isNearest
                                  ? const Color(0xFF2563EB)
                                  : isInside
                                      ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              width: isNearest ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isNearest
                                          ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                          : isInside
                                              ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                                              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isNearest ? Icons.near_me : Icons.location_on,
                                      color: isNearest
                                          ? const Color(0xFF2563EB)
                                          : isInside
                                              ? const Color(0xFF16A34A)
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          site.siteName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_formatDistance(distance)} away',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (site.address != null && site.address!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            site.fullAddress,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Chips positioned at top right
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Wrap(
                                  spacing: 4,
                                  direction: Axis.horizontal,
                                  children: [
                                    if (isNearest)
                                      _buildGlassStatusChip(
                                        'Closest',
                                        const Color(0xFF2563EB),
                                      ),
                                    _buildGlassStatusChip(
                                      isInside ? 'Inside' : 'Outside',
                                      isInside ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ] else if (!_isLoading) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No sites assigned. Please contact your administrator.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGlassStatusChip(String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(
        minHeight: 20,
        maxHeight: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showConfirmationDialog(String punchType) {
    final siteName = _nearestSite?.siteName ?? 'Unknown Site';
    final time = _formatTime12Hour(DateTime.now());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm ${_getPunchTypeLabel(punchType)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm ${_getPunchTypeLabel(punchType)} at $siteName?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: $time',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAttendance(punchType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B5B36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchButtons(ColorScheme colorScheme) {
    final nextPunch = _nextPunchType;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    // Calculate responsive spacing and aspect ratio
    final spacing = isSmallScreen ? 8.0 : 10.0;
    final aspectRatio = isSmallScreen ? 1.3 : 1.2; // Lower aspect ratio = taller buttons

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mark Attendance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 15 : 16,
                  ),
            ),
            const SizedBox(height: 12),
            if (nextPunch == null)
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF16A34A),
                      size: isSmallScreen ? 28 : 32,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Flexible(
                      child: Text(
                        'All punches completed for today!',
                        style: TextStyle(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                    children: [
                      _buildPunchButton('CHECK_IN', nextPunch == 'CHECK_IN', isSmallScreen),
                      _buildPunchButton('LUNCH_OUT', nextPunch == 'LUNCH_OUT', isSmallScreen),
                      _buildPunchButton('LUNCH_IN', nextPunch == 'LUNCH_IN', isSmallScreen),
                      _buildPunchButton('CHECK_OUT', nextPunch == 'CHECK_OUT', isSmallScreen),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchButton(String punchType, bool isActive, bool isSmallScreen) {
    final color = _getPunchTypeColor(punchType);
    final icon = _getPunchTypeIcon(punchType);
    final label = _getPunchTypeLabel(punchType);
    final isDone = _todayLogs.any((l) => l.punchType.toUpperCase() == punchType);
    // Require employee to be inside geofence to enable punch buttons
    final isEnabled = !isDone && 
        isActive && 
        !_isLoading && 
        _currentPosition != null && 
        _isInsideGeofence &&
        _employeeId != null &&
        _employeeId!.isNotEmpty;
    
    // Get the time for this punch type if it's already done
    String? punchTime;
    if (isDone) {
      final log = _todayLogs.firstWhere(
        (l) => l.punchType.toUpperCase() == punchType,
        orElse: () => _todayLogs.first,
      );
      punchTime = _formatTime12Hour(log.punchTime);
    }
    
    // Responsive sizes
    final iconSize = isSmallScreen ? 26.0 : 32.0;
    final fontSize = isSmallScreen ? 12.0 : 13.0;
    final padding = isSmallScreen 
        ? const EdgeInsets.symmetric(vertical: 12, horizontal: 4)
        : const EdgeInsets.symmetric(vertical: 16, horizontal: 6);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: isDone
          ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey[200])
          : isActive
              ? color.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : Colors.grey[100]),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isEnabled
            ? () async {
                // Check employee ID first
                if (_employeeId == null || _employeeId!.isEmpty) {
                  if (mounted) {
                    Fluttertoast.showToast(
                      msg: 'Employee ID not found. Please refresh the page.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                  // Try to reload employee ID
                  await _loadData();
                  return;
                }
                // Check if location is available
                if (_currentPosition == null) {
                  // Try to get location first
                  if (!_isLoadingLocation && !_isFetchingLocation) {
                    await _getCurrentLocation();
                    // Wait a bit for location to be fetched
                    await Future.delayed(const Duration(milliseconds: 500));
                  }
                  
                  if (_currentPosition == null) {
                    if (mounted) {
                      Fluttertoast.showToast(
                        msg: 'Location is being determined. Please wait or tap the refresh icon in Location Status.',
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.orange,
                        textColor: Colors.white,
                      );
                    }
                    return;
                  }
                }
                
                // Only allow marking if inside geofence
                _markAttendance(punchType);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone
                  ? theme.colorScheme.outline
                  : isActive && isEnabled
                      ? color
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
              width: isActive && !isDone && isEnabled ? 2 : 1,
            ),
            color: !isEnabled && !isDone 
                ? (isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey[50])
                : null,
          ),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading && isActive && !isDone)
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(
                    isDone ? Icons.check_circle : icon,
                    size: iconSize,
                    color: isDone
                        ? theme.colorScheme.onSurfaceVariant
                        : isActive
                            ? color
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isActive && !isDone ? FontWeight.bold : FontWeight.normal,
                      color: isDone
                          ? theme.colorScheme.onSurfaceVariant
                          : isActive
                              ? color
                              : theme.colorScheme.onSurfaceVariant,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDone && punchTime != null) ...[
                  SizedBox(height: isSmallScreen ? 3 : 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      punchTime,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
                else if (!isActive && _nextPunchType != null)
                  Padding(
                    padding: EdgeInsets.only(top: isSmallScreen ? 3 : 4),
                    child: Text(
                      'Not available',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (_currentPosition == null && !isDone)
                  Padding(
                    padding: EdgeInsets.only(top: isSmallScreen ? 3 : 4),
                    child: Text(
                      'Waiting...',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        color: Colors.orange[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (!_isInsideGeofence && !isDone && isActive)
                  Padding(
                    padding: EdgeInsets.only(top: isSmallScreen ? 3 : 4),
                    child: Text(
                      'Move to site',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        color: Colors.red[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayLog(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Today's Log",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_todayLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No attendance recorded yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayLogs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = _todayLogs[index];
                final color = _getPunchTypeColor(log.punchType);
                final icon = _getPunchTypeIcon(log.punchType);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    log.punchTypeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: log.siteName != null
                      ? Text(
                          log.siteName!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        )
                      : null,
                  trailing: Text(
                    _formatTime12Hour(log.punchTime),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}


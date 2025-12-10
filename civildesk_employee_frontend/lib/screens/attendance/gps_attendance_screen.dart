import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
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
  Site? _nearestSite;
  double? _distanceFromSite;
  List<GpsAttendanceLog> _todayLogs = [];
  String? _employeeId;

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

  void _showGeofenceWarningDialog(String punchType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Outside Site Boundary'),
        content: Text(
          'You are ${_distanceFromSite?.toStringAsFixed(0)}m away from the site. '
          'The site boundary is ${_nearestSite?.geofenceRadiusMeters}m.\n\n'
          'Attendance may be rejected by the server. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAttendance(punchType, forceAllow: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Mark Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAttendance(String punchType, {bool forceAllow = false}) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be determined'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!forceAllow && !_isInsideGeofence && _nearestSite != null && _distanceFromSite != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are ${_distanceFromSite?.toStringAsFixed(0)}m from the site. '
            'Please move closer (within ${_nearestSite?.geofenceRadiusMeters}m) to mark attendance.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_employeeId == null || _employeeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee ID not found. Please refresh the page.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = GpsAttendanceRequest(
        employeeId: _employeeId!,
        punchType: punchType,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracyMeters: _currentPosition!.accuracy,
        altitude: _currentPosition!.altitude,
        isMockLocation: _currentPosition!.isMocked,
        networkStatus: 'ONLINE',
        siteId: _nearestSite?.id,
        deviceName: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
      );

      final log = await _attendanceService.markAttendance(request);

      // Reload attendance logs
      _todayLogs = await _attendanceService.getTodayAttendance(_employeeId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getPunchTypeLabel(punchType)} marked successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
      ],
      child: _isLoading && _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _currentPosition == null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current Time Card
                        _buildTimeCard(colorScheme),
                        const SizedBox(height: 16),

                        // Location Status Card
                        _buildLocationCard(colorScheme),
                        const SizedBox(height: 16),

                        // Punch Buttons
                        _buildPunchButtons(colorScheme),
                        const SizedBox(height: 24),

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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unable to get location',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(ColorScheme colorScheme) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: TextStyle(
                color: colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return Text(
                  DateFormat('HH:mm:ss').format(DateTime.now()),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLoadingLocation
                      ? Icons.gps_not_fixed
                      : _currentPosition != null
                          ? Icons.gps_fixed
                          : Icons.gps_off,
                  color: _isLoadingLocation
                      ? Colors.orange
                      : _currentPosition != null
                          ? Colors.green
                          : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
                    icon: const Icon(Icons.refresh),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Refresh Location',
                  ),
              ],
            ),
            const Divider(),
            if (_currentPosition != null) ...[
              _buildLocationRow(
                'Coordinates',
                '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
              ),
              _buildLocationRow(
                'Accuracy',
                '±${_currentPosition!.accuracy.toStringAsFixed(0)}m',
              ),
              if (_nearestSite != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isInsideGeofence
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isInsideGeofence ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: _isInsideGeofence ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nearestSite!.siteName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_distanceFromSite?.toStringAsFixed(0)}m away',
                                  style: TextStyle(
                                    color: _isInsideGeofence ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isInsideGeofence ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isInsideGeofence ? 'Inside' : 'Outside',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!_isInsideGeofence) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Move ${(_distanceFromSite! - _nearestSite!.geofenceRadiusMeters).toStringAsFixed(0)}m closer to mark attendance',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Waiting for location...'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
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

  Widget _buildPunchButtons(ColorScheme colorScheme) {
    final nextPunch = _nextPunchType;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark Attendance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (nextPunch == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'All punches completed for today!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildPunchButton('CHECK_IN', nextPunch == 'CHECK_IN'),
                  _buildPunchButton('LUNCH_OUT', nextPunch == 'LUNCH_OUT'),
                  _buildPunchButton('LUNCH_IN', nextPunch == 'LUNCH_IN'),
                  _buildPunchButton('CHECK_OUT', nextPunch == 'CHECK_OUT'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchButton(String punchType, bool isActive) {
    final color = _getPunchTypeColor(punchType);
    final icon = _getPunchTypeIcon(punchType);
    final label = _getPunchTypeLabel(punchType);
    final isDone = _todayLogs.any((l) => l.punchType.toUpperCase() == punchType);
    final isEnabled = !isDone && isActive && !_isLoading;

    return Material(
      color: isDone
          ? Colors.grey[200]
          : isActive
              ? color.withOpacity(0.1)
              : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isEnabled
            ? () async {
                // Check employee ID first
                if (_employeeId == null || _employeeId!.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Employee ID not found. Please refresh the page.'),
                        backgroundColor: Colors.red,
                      ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Location is being determined. Please wait or tap the refresh icon in Location Status.'),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: 'Refresh',
                            textColor: Colors.white,
                            onPressed: () => _getCurrentLocation(),
                          ),
                        ),
                      );
                    }
                    return;
                  }
                }
                
                // If outside geofence, show confirmation dialog
                if (_nearestSite != null && _distanceFromSite != null && 
                    !_isInsideGeofence) {
                  _showGeofenceWarningDialog(punchType);
                } else {
                  _markAttendance(punchType);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone
                  ? Colors.grey
                  : isActive && isEnabled
                      ? color
                      : Colors.grey[300]!,
              width: isActive && !isDone && isEnabled ? 2 : 1,
            ),
            color: !isEnabled && !isDone ? Colors.grey[50] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading && isActive && !isDone)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(
                  isDone ? Icons.check_circle : icon,
                  size: 32,
                  color: isDone
                      ? Colors.grey
                      : isActive
                          ? color
                          : Colors.grey[400],
                ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive && !isDone ? FontWeight.bold : FontWeight.normal,
                  color: isDone
                      ? Colors.grey
                      : isActive
                          ? color
                          : Colors.grey[600],
                ),
              ),
              if (isDone)
                Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                )
              else if (!isActive && _nextPunchType != null)
                Text(
                  'Not available',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                )
              else if (_currentPosition == null)
                Text(
                  'Waiting for location...',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayLog(ColorScheme colorScheme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Text(
                  "Today's Log",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_todayLogs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No attendance recorded yet'),
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
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(log.punchTypeLabel),
                  subtitle: log.siteName != null
                      ? Text(log.siteName!, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                      : null,
                  trailing: Text(
                    DateFormat('HH:mm').format(log.punchTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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


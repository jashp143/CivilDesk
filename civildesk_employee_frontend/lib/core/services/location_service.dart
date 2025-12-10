import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions using permission_handler
  Future<bool> requestPermission() async {
    // First check with permission_handler
    PermissionStatus status;
    
    if (Platform.isAndroid) {
      // For Android, request location permission
      status = await Permission.location.request();
    } else {
      // For iOS, request location when in use
      status = await Permission.locationWhenInUse.request();
    }
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      throw LocationException(
        'Location permissions are permanently denied. Please enable them in app settings.',
      );
    } else {
      throw LocationException('Location permissions are denied.');
    }
  }

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    PermissionStatus status;
    
    if (Platform.isAndroid) {
      status = await Permission.location.status;
    } else {
      status = await Permission.locationWhenInUse.status;
    }
    
    return status.isGranted;
  }

  /// Get current position
  Future<Position> getCurrentPosition() async {
    try {
      // Check if location services are enabled (with timeout)
      final serviceEnabled = await isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3));
      
      if (!serviceEnabled) {
        throw LocationException('Location services are disabled. Please enable location services in your device settings.');
      }

      // Check and request permission using permission_handler
      final hasPermission = await this.hasPermission()
          .timeout(const Duration(seconds: 3));
      
      if (!hasPermission) {
        // Request permission
        await requestPermission();
      }

      // Verify permission with Geolocator as well
      var geolocatorPermission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 3));
      
      if (geolocatorPermission == LocationPermission.denied) {
        geolocatorPermission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10));
        
        if (geolocatorPermission == LocationPermission.denied) {
          throw LocationException('Location permissions are denied. Please grant location permission to mark attendance.');
        }
      }

      if (geolocatorPermission == LocationPermission.deniedForever) {
        throw LocationException(
          'Location permissions are permanently denied. Please enable them in app settings.',
        );
      }

      // Get position with high accuracy and shorter timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw LocationException('Location request timed out. Please try again.');
        },
      );
    } catch (e) {
      if (e is LocationException) {
        rethrow;
      }
      throw LocationException('Failed to get location: ${e.toString()}');
    }
  }

  /// Check if current location is mock/spoofed
  Future<bool> isMockLocation() async {
    try {
      final position = await getCurrentPosition();
      return position.isMocked;
    } catch (e) {
      return false;
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if position is inside a circular geofence
  bool isInsideGeofence(
    Position position,
    double centerLatitude,
    double centerLongitude,
    double radiusMeters,
  ) {
    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      centerLatitude,
      centerLongitude,
    );
    return distance <= radiusMeters;
  }

  /// Get device info
  Future<Map<String, String>> getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
    };
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}


class Site {
  final int? id;
  final String siteCode;
  final String siteName;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double latitude;
  final double longitude;
  final GeofenceType geofenceType;
  final int geofenceRadiusMeters;
  final String? geofencePolygon;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final String? lunchStartTime;
  final String? lunchEndTime;
  final int? assignedEmployeeCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Site({
    this.id,
    required this.siteCode,
    required this.siteName,
    this.description,
    this.address,
    this.city,
    this.state,
    this.pincode,
    required this.latitude,
    required this.longitude,
    this.geofenceType = GeofenceType.radius,
    this.geofenceRadiusMeters = 100,
    this.geofencePolygon,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.shiftStartTime,
    this.shiftEndTime,
    this.lunchStartTime,
    this.lunchEndTime,
    this.assignedEmployeeCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] as int?,
      siteCode: json['siteCode'] as String,
      siteName: json['siteName'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geofenceType: json['geofenceType'] != null
          ? GeofenceType.values.firstWhere(
              (e) => e.name.toUpperCase() == (json['geofenceType'] as String).toUpperCase(),
              orElse: () => GeofenceType.radius,
            )
          : GeofenceType.radius,
      geofenceRadiusMeters: json['geofenceRadiusMeters'] as int? ?? 100,
      geofencePolygon: json['geofencePolygon'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      shiftStartTime: json['shiftStartTime'] as String?,
      shiftEndTime: json['shiftEndTime'] as String?,
      lunchStartTime: json['lunchStartTime'] as String?,
      lunchEndTime: json['lunchEndTime'] as String?,
      assignedEmployeeCount: json['assignedEmployeeCount'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'siteCode': siteCode,
      'siteName': siteName,
      if (description != null) 'description': description,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceType': geofenceType.name.toUpperCase(),
      'geofenceRadiusMeters': geofenceRadiusMeters,
      if (geofencePolygon != null) 'geofencePolygon': geofencePolygon,
      'isActive': isActive,
      if (startDate != null) 'startDate': startDate!.toIso8601String().split('T')[0],
      if (endDate != null) 'endDate': endDate!.toIso8601String().split('T')[0],
      if (shiftStartTime != null) 'shiftStartTime': shiftStartTime,
      if (shiftEndTime != null) 'shiftEndTime': shiftEndTime,
      if (lunchStartTime != null) 'lunchStartTime': lunchStartTime,
      if (lunchEndTime != null) 'lunchEndTime': lunchEndTime,
    };
  }

  String get fullAddress {
    List<String> parts = [];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);
    return parts.join(', ');
  }
}

enum GeofenceType {
  radius,
  polygon,
}

class GpsAttendanceLog {
  final int? id;
  final int? attendanceId;
  final String employeeId;
  final String? employeeName;
  final String punchType;
  final DateTime punchTime;
  final DateTime? serverTimestamp;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String? deviceId;
  final String? deviceName;
  final bool isMockLocation;
  final bool isInsideGeofence;
  final double? distanceFromSite;
  final int? siteId;
  final String? siteName;
  final String? siteCode;
  final String? networkStatus;
  final String? syncStatus;
  final DateTime? createdAt;

  GpsAttendanceLog({
    this.id,
    this.attendanceId,
    required this.employeeId,
    this.employeeName,
    required this.punchType,
    required this.punchTime,
    this.serverTimestamp,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.deviceId,
    this.deviceName,
    this.isMockLocation = false,
    this.isInsideGeofence = true,
    this.distanceFromSite,
    this.siteId,
    this.siteName,
    this.siteCode,
    this.networkStatus,
    this.syncStatus,
    this.createdAt,
  });

  factory GpsAttendanceLog.fromJson(Map<String, dynamic> json) {
    return GpsAttendanceLog(
      id: json['id'] as int?,
      attendanceId: json['attendanceId'] as int?,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String?,
      punchType: json['punchType'] as String,
      punchTime: DateTime.parse(json['punchTime'] as String),
      serverTimestamp: json['serverTimestamp'] != null
          ? DateTime.parse(json['serverTimestamp'] as String)
          : null,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: json['accuracyMeters'] != null
          ? (json['accuracyMeters'] as num).toDouble()
          : null,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      isMockLocation: json['isMockLocation'] as bool? ?? false,
      isInsideGeofence: json['isInsideGeofence'] as bool? ?? true,
      distanceFromSite: json['distanceFromSite'] != null
          ? (json['distanceFromSite'] as num).toDouble()
          : null,
      siteId: json['siteId'] as int?,
      siteName: json['siteName'] as String?,
      siteCode: json['siteCode'] as String?,
      networkStatus: json['networkStatus'] as String?,
      syncStatus: json['syncStatus'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  // Get color for punch type marker
  int get punchTypeColor {
    switch (punchType.toUpperCase()) {
      case 'CHECK_IN':
        return 0xFF4CAF50; // Green
      case 'LUNCH_OUT':
        return 0xFFFF9800; // Orange
      case 'LUNCH_IN':
        return 0xFF2196F3; // Blue
      case 'CHECK_OUT':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  String get punchTypeLabel {
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
}


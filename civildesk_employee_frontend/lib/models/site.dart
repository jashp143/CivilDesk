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
  final String geofenceType;
  final int geofenceRadiusMeters;
  final bool isActive;

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
    this.geofenceType = 'RADIUS',
    this.geofenceRadiusMeters = 100,
    this.isActive = true,
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
      geofenceType: json['geofenceType'] as String? ?? 'RADIUS',
      geofenceRadiusMeters: json['geofenceRadiusMeters'] as int? ?? 100,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }
}

class GpsAttendanceRequest {
  final String employeeId;
  final String punchType;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? altitude;
  final String? deviceId;
  final String? deviceName;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final bool isMockLocation;
  final String networkStatus;
  final DateTime? offlineTimestamp;
  final int? siteId;

  GpsAttendanceRequest({
    required this.employeeId,
    required this.punchType,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.altitude,
    this.deviceId,
    this.deviceName,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    this.isMockLocation = false,
    this.networkStatus = 'ONLINE',
    this.offlineTimestamp,
    this.siteId,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'punchType': punchType,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (altitude != null) 'altitude': altitude,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (osVersion != null) 'osVersion': osVersion,
      if (appVersion != null) 'appVersion': appVersion,
      'isMockLocation': isMockLocation,
      'networkStatus': networkStatus,
      if (offlineTimestamp != null) 'offlineTimestamp': offlineTimestamp!.toIso8601String(),
      if (siteId != null) 'siteId': siteId,
    };
  }
}

class GpsAttendanceLog {
  final int? id;
  final String employeeId;
  final String? employeeName;
  final String punchType;
  final DateTime punchTime;
  final double latitude;
  final double longitude;
  final bool isInsideGeofence;
  final double? distanceFromSite;
  final String? siteName;
  final String? siteCode;

  GpsAttendanceLog({
    this.id,
    required this.employeeId,
    this.employeeName,
    required this.punchType,
    required this.punchTime,
    required this.latitude,
    required this.longitude,
    this.isInsideGeofence = true,
    this.distanceFromSite,
    this.siteName,
    this.siteCode,
  });

  factory GpsAttendanceLog.fromJson(Map<String, dynamic> json) {
    return GpsAttendanceLog(
      id: json['id'] as int?,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String?,
      punchType: json['punchType'] as String,
      punchTime: DateTime.parse(json['punchTime'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isInsideGeofence: json['isInsideGeofence'] as bool? ?? true,
      distanceFromSite: json['distanceFromSite'] != null
          ? (json['distanceFromSite'] as num).toDouble()
          : null,
      siteName: json['siteName'] as String?,
      siteCode: json['siteCode'] as String?,
    );
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


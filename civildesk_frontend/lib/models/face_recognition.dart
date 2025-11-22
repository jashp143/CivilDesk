class FaceRecognitionResponse {
  final bool success;
  final List<DetectedFace> faces;

  FaceRecognitionResponse({
    required this.success,
    required this.faces,
  });

  factory FaceRecognitionResponse.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionResponse(
      success: json['success'] as bool? ?? false,
      faces: (json['faces'] as List<dynamic>?)
              ?.map((e) => DetectedFace.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DetectedFace {
  final BoundingBox bbox;
  final double confidence;
  final bool recognized;
  final String? employeeId;
  final String? firstName;
  final String? lastName;
  final double matchConfidence;

  DetectedFace({
    required this.bbox,
    required this.confidence,
    required this.recognized,
    this.employeeId,
    this.firstName,
    this.lastName,
    required this.matchConfidence,
  });

  String get displayName => firstName != null && lastName != null 
      ? '$firstName $lastName'
      : employeeId ?? 'Unknown';

  String get storageKey => firstName != null && lastName != null
      ? '${firstName}_$lastName'
      : employeeId ?? 'Unknown';

  factory DetectedFace.fromJson(Map<String, dynamic> json) {
    return DetectedFace(
      bbox: BoundingBox.fromJson(json['bbox'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recognized: json['recognized'] as bool? ?? false,
      employeeId: json['employee_id'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      matchConfidence: (json['match_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BoundingBox {
  final int x1;
  final int y1;
  final int x2;
  final int y2;

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: (json['x1'] as num?)?.toInt() ?? 0,
      y1: (json['y1'] as num?)?.toInt() ?? 0,
      x2: (json['x2'] as num?)?.toInt() ?? 0,
      y2: (json['y2'] as num?)?.toInt() ?? 0,
    );
  }
}


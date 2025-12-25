import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/face_recognition_service.dart';
import '../../core/services/employee_service.dart';
import '../../models/face_recognition.dart';
import '../../widgets/admin_layout.dart';
import '../../widgets/toast.dart';
import '../../core/constants/app_routes.dart';

enum AttendanceType {
  punchIn,
  lunchOut,
  lunchIn,
  punchOut;

  String get apiValue {
    switch (this) {
      case AttendanceType.punchIn:
        return 'PUNCH_IN';
      case AttendanceType.lunchOut:
        return 'LUNCH_OUT';
      case AttendanceType.lunchIn:
        return 'LUNCH_IN';
      case AttendanceType.punchOut:
        return 'PUNCH_OUT';
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceType.punchIn:
        return 'Punch In';
      case AttendanceType.lunchOut:
        return 'Lunch Out';
      case AttendanceType.lunchIn:
        return 'Lunch In';
      case AttendanceType.punchOut:
        return 'Punch Out';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceType.punchIn:
        return Icons.login;
      case AttendanceType.lunchOut:
        return Icons.restaurant;
      case AttendanceType.lunchIn:
        return Icons.restaurant_menu;
      case AttendanceType.punchOut:
        return Icons.logout;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceType.punchIn:
        return Colors.green;
      case AttendanceType.lunchOut:
        return Colors.orange;
      case AttendanceType.lunchIn:
        return Colors.blue;
      case AttendanceType.punchOut:
        return Colors.red;
    }
  }
}

class AdminAttendanceMarkingScreen extends StatefulWidget {
  const AdminAttendanceMarkingScreen({super.key});

  @override
  State<AdminAttendanceMarkingScreen> createState() =>
      _AdminAttendanceMarkingScreenState();
}

class _AdminAttendanceMarkingScreenState
    extends State<AdminAttendanceMarkingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  bool _isProcessing = false;
  FaceRecognitionResponse? _lastDetection;
  Size? _lastImageSize;
  String? _detectedEmployeeId;
  String? _detectedEmployeeName;
  double? _detectionConfidence;
  AttendanceType? _selectedAttendanceType;
  final AttendanceService _attendanceService = AttendanceService();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final EmployeeService _employeeService = EmployeeService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find front-facing camera for face attendance
        CameraDescription? frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first, // Fallback to first camera if no front camera found
        );
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {});
        _startDetection();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startDetection() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isProcessing && _selectedAttendanceType == null) {
        _detectFaces();
      }
    });
  }

  Future<void> _detectFaces() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing ||
        _selectedAttendanceType != null) {
      return;
    }

    setState(() {
      _isDetecting = true;
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);

      // Get the actual image size for coordinate transformation
      final imageBytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final imageSize = Size(
          frame.image.width.toDouble(), frame.image.height.toDouble());

      // Detect faces
      final response = await _faceService.detectFaces(file);
      final faceResponse = FaceRecognitionResponse.fromJson(response);

      // Find recognized face and fetch employee details
      String? detectedEmployeeId;
      String? detectedEmployeeName;
      double? detectionConfidence;

      if (faceResponse.faces.isNotEmpty) {
        final recognizedFace = faceResponse.faces.firstWhere(
          (face) => face.recognized,
          orElse: () => faceResponse.faces.first,
        );

        if (recognizedFace.recognized) {
          detectedEmployeeId = recognizedFace.employeeId;
          detectionConfidence = recognizedFace.matchConfidence;
          // Set employee ID as temporary name - will be updated when fetched
          detectedEmployeeName = recognizedFace.employeeId;
        }
      }

      // Update UI immediately with detected face
      setState(() {
        _lastDetection = faceResponse;
        _lastImageSize = imageSize;
        _isDetecting = false;
        _detectedEmployeeId = detectedEmployeeId;
        _detectedEmployeeName = detectedEmployeeName; // Will show employee ID initially
        _detectionConfidence = detectionConfidence;
      });

      // Fetch employee details in background (non-blocking)
      if (detectedEmployeeId != null) {
        _fetchEmployeeName(detectedEmployeeId);
      }

      // Continue detection if no face recognized
      if (_detectedEmployeeId == null) {
        _startDetection();
      }
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      setState(() {
        _isDetecting = false;
      });
      _startDetection();
    }
  }

  Future<void> _fetchEmployeeName(String employeeId) async {
    try {
      final employee = await _employeeService.getEmployeeByEmployeeId(employeeId);
      if (mounted && _detectedEmployeeId == employeeId) {
        setState(() {
          _detectedEmployeeName = employee.fullName;
        });
      }
    } catch (e) {
      debugPrint('Error fetching employee name: $e');
      // Keep the employee ID as name if fetch fails
    }
  }

  Future<void> _markAttendance(AttendanceType attendanceType) async {
    if (_detectedEmployeeId == null || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _selectedAttendanceType = attendanceType;
    });

    try {
      // Capture current frame
      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);

      final response = await _attendanceService.markAttendanceWithFace(
        file,
        attendanceType: attendanceType.apiValue,
        employeeId: _detectedEmployeeId, // Send the already detected employee ID
      );

      if (mounted) {
        if (response['success'] == true) {
          Toast.success(
            context,
            '${attendanceType.displayName} marked successfully for $_detectedEmployeeName',
            duration: const Duration(seconds: 3),
          );

          // Reset for next detection
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _detectedEmployeeId = null;
                _detectedEmployeeName = null;
                _detectionConfidence = null;
                _selectedAttendanceType = null;
                _lastDetection = null;
              });
              _startDetection();
            }
          });
        } else {
          Toast.error(context, response['message'] ?? 'Failed to mark attendance');
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.attendanceMarking,
      title: const Text('Mark Attendance'),
      child: _cameraController == null ||
              !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Camera preview
                Center(
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),

                // Draw bounding boxes
                if (_lastDetection != null &&
                    _lastDetection!.faces.isNotEmpty &&
                    _lastImageSize != null)
                  ..._lastDetection!.faces.map((face) {
                    final bbox = face.bbox;
                    final screenSize = MediaQuery.of(context).size;
                    final imageSize = _lastImageSize!;

                    // Calculate the actual preview display size
                    final previewAspectRatio =
                        _cameraController!.value.aspectRatio;
                    double previewWidth, previewHeight;

                    if (screenSize.width / screenSize.height >
                        previewAspectRatio) {
                      previewHeight = screenSize.height;
                      previewWidth = previewHeight * previewAspectRatio;
                    } else {
                      previewWidth = screenSize.width;
                      previewHeight = previewWidth / previewAspectRatio;
                    }

                    final scaleX = previewWidth / imageSize.width;
                    final scaleY = previewHeight / imageSize.height;

                    final left = bbox.x1 * scaleX;
                    final top = bbox.y1 * scaleY;
                    final width = (bbox.x2 - bbox.x1) * scaleX;
                    final height = (bbox.y2 - bbox.y1) * scaleY;

                    final offsetX = (screenSize.width - previewWidth) / 2;
                    final offsetY = (screenSize.height - previewHeight) / 2;

                    return Positioned(
                      left: left + offsetX,
                      top: top + offsetY,
                      child: Container(
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: face.recognized ? Colors.green : Colors.red,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),

                // Employee info and attendance type selection
                if (_detectedEmployeeId != null && _selectedAttendanceType == null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          margin: const EdgeInsets.all(24),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.face,
                                  size: 64,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 16),
                                // Show employee name or loading indicator
                                _detectedEmployeeName != null && 
                                _detectedEmployeeName != _detectedEmployeeId
                                    ? Text(
                                        _detectedEmployeeName!,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Loading...',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                const SizedBox(height: 8),
                                Text(
                                  'Employee ID: $_detectedEmployeeId',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_detectionConfidence != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Confidence: ${(_detectionConfidence! * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
                                const Text(
                                  'Select Attendance Type:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: AttendanceType.values.map((type) {
                                    return ElevatedButton.icon(
                                      onPressed: () => _markAttendance(type),
                                      icon: Icon(type.icon),
                                      label: Text(type.displayName),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: type.color,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Processing overlay
                if (_isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              'Marking ${_selectedAttendanceType?.displayName ?? "attendance"}...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Instructions
                if (_detectedEmployeeId == null && !_isProcessing)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Instructions:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Position your face in front of the camera',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const Text(
                            '• Wait for face detection',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const Text(
                            '• Select attendance type after recognition',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}


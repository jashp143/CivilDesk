import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/face_recognition_service.dart';
import '../../models/face_recognition.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  const AttendanceMarkingScreen({super.key});

  @override
  State<AttendanceMarkingScreen> createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  bool _isProcessing = false;
  FaceRecognitionResponse? _lastDetection;
  Size? _lastImageSize; // Store the size of the last captured image
  final AttendanceService _attendanceService = AttendanceService();
  final FaceRecognitionService _faceService = FaceRecognitionService();

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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isProcessing) {
        _detectFaces();
      }
    });
  }

  Future<void> _detectFaces() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
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
      final imageSize = Size(frame.image.width.toDouble(), frame.image.height.toDouble());

      // Detect faces
      final response = await _faceService.detectFaces(file);
      final faceResponse = FaceRecognitionResponse.fromJson(response);

      setState(() {
        _lastDetection = faceResponse;
        _lastImageSize = imageSize;
        _isDetecting = false;
      });

      // Continue detection
      _startDetection();
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      setState(() {
        _isDetecting = false;
      });
      _startDetection();
    }
  }

  Future<void> _markAttendance(DetectedFace face) async {
    if (face.employeeId == null || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture current frame
      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);

      final response = await _attendanceService.markAttendanceWithFace(file);
      
      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance marked for ${face.employeeId}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to mark attendance'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mark Attendance'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition Attendance'),
      ),
      body: Stack(
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
              final previewAspectRatio = _cameraController!.value.aspectRatio;
              double previewWidth, previewHeight;
              
              if (screenSize.width / screenSize.height > previewAspectRatio) {
                // Screen is wider than preview aspect ratio
                previewHeight = screenSize.height;
                previewWidth = previewHeight * previewAspectRatio;
              } else {
                // Screen is taller than preview aspect ratio
                previewWidth = screenSize.width;
                previewHeight = previewWidth / previewAspectRatio;
              }
              
              // Calculate scale factors from image coordinates to preview coordinates
              // The bounding box coordinates are in the captured image space
              final scaleX = previewWidth / imageSize.width;
              final scaleY = previewHeight / imageSize.height;
              
              // Calculate position and size
              final left = bbox.x1 * scaleX;
              final top = bbox.y1 * scaleY;
              final width = (bbox.x2 - bbox.x1) * scaleX;
              final height = (bbox.y2 - bbox.y1) * scaleY;
              
              // Center the preview if needed
              final offsetX = (screenSize.width - previewWidth) / 2;
              final offsetY = (screenSize.height - previewHeight) / 2;

              return Positioned(
                left: left + offsetX,
                top: top + offsetY,
                child: GestureDetector(
                  onTap: face.recognized ? () => _markAttendance(face) : null,
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
                    child: Stack(
                      children: [
                        if (face.recognized)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.8),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    face.employeeId ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${(face.matchConfidence * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (!_isProcessing)
                                    const Text(
                                      'Tap to mark attendance',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Marking attendance...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Instructions
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
                    '• Green box = Recognized face',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Text(
                    '• Red box = Unknown face',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Text(
                    '• Tap on green box to mark attendance',
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


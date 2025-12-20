import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/services/face_recognition_service.dart';
import '../../models/face_recognition.dart';

/// Face Attendance Screen with optimized frame processing
/// Phase 2 Optimization - Debouncing and cancel tokens for network efficiency
class FaceAttendanceScreen extends StatefulWidget {
  const FaceAttendanceScreen({super.key});

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  bool _isProcessing = false;
  List<DetectedFace> _detectedFaces = [];
  Size? _lastImageSize;
  DetectedFace? _selectedFace;
  final FaceRecognitionService _faceService = FaceRecognitionService();

  // Phase 2 Optimization: Debounce timer and cancel token
  Timer? _debounceTimer;
  CancelToken? _cancelToken;
  static const Duration _detectionInterval = Duration(
    seconds: 2,
  ); // Increased from 1.5s

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
          orElse: () => _cameras!
              .first, // Fallback to first camera if no front camera found
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    // Use debounce timer to avoid too frequent requests
    _debounceTimer = Timer(_detectionInterval, () {
      if (mounted && !_isProcessing) {
        _detectFaces();
      }
    });
  }

  Future<void> _detectFaces() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isDetecting ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isDetecting = true;
    });

    // Cancel previous request if still pending
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);

      // Get image size
      final imageBytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );

      // Recognize faces with cancel token
      final response = await _faceService.recognizeStream(
        file,
        cancelToken: _cancelToken,
      );

      if (response['success'] == true && response['faces'] != null) {
        final faces = (response['faces'] as List)
            .map((face) => DetectedFace.fromJson(face))
            .toList();

        setState(() {
          _detectedFaces = faces;
          _lastImageSize = imageSize;
          _isDetecting = false;
        });
      } else {
        setState(() {
          _detectedFaces = [];
          _isDetecting = false;
        });
      }

      // Clean up temp file
      try {
        await file.delete();
      } catch (_) {}

      // Continue detection
      _startDetection();
    } on DioException catch (e) {
      // Ignore cancelled requests
      if (e.type != DioExceptionType.cancel) {
        debugPrint('Error detecting faces: $e');
        setState(() {
          _detectedFaces = [];
        });
      }
      setState(() {
        _isDetecting = false;
      });
      _startDetection();
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      setState(() {
        _isDetecting = false;
        _detectedFaces = [];
      });
      _startDetection();
    }
  }

  Future<void> _markAttendance(DetectedFace face, String punchType) async {
    if (face.employeeId == null || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await _faceService.markAttendance(
        employeeId: face.employeeId!,
        punchType: punchType,
        confidence: face.matchConfidence,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Attendance marked for ${face.displayName} - ${_getPunchTypeName(punchType)}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Clear selection after successful attendance marking
          setState(() {
            _selectedFace = null;
          });
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  String _getPunchTypeName(String punchType) {
    switch (punchType) {
      case 'check_in':
        return 'Check In';
      case 'lunch_out':
        return 'Lunch Out';
      case 'lunch_in':
        return 'Lunch In';
      case 'check_out':
        return 'Check Out';
      default:
        return punchType;
    }
  }

  IconData _getPunchTypeIcon(String punchType) {
    switch (punchType) {
      case 'check_in':
        return Icons.login;
      case 'lunch_out':
        return Icons.restaurant;
      case 'lunch_in':
        return Icons.restaurant_menu;
      case 'check_out':
        return Icons.logout;
      default:
        return Icons.check;
    }
  }

  Color _getPunchTypeColor(String punchType) {
    switch (punchType) {
      case 'check_in':
        return Colors.green;
      case 'lunch_out':
        return Colors.orange;
      case 'lunch_in':
        return Colors.blue;
      case 'check_out':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    // Cancel pending operations
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Face Recognition Attendance')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition Attendance'),
        actions: [
          if (_isDetecting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
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
          if (_detectedFaces.isNotEmpty && _lastImageSize != null)
            ..._detectedFaces.map((face) {
              return _buildFaceBoundingBox(face);
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

          // Selected face info and punch buttons
          if (_selectedFace != null && !_isProcessing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Employee info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _selectedFace!.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${_selectedFace!.employeeId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confidence: ${(_selectedFace!.matchConfidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Punch buttons
                    const Text(
                      'Select Punch Type:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPunchButton('check_in'),
                        _buildPunchButton('lunch_out'),
                        _buildPunchButton('lunch_in'),
                        _buildPunchButton('check_out'),
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFace = null;
                        });
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions (when no face selected)
          if (_selectedFace == null && !_isProcessing)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                      '• Tap on green box to mark attendance',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (_detectedFaces.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${_detectedFaces.where((f) => f.recognized).length} face(s) recognized',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaceBoundingBox(DetectedFace face) {
    final bbox = face.bbox;
    final screenSize = MediaQuery.of(context).size;
    final imageSize = _lastImageSize!;

    // Calculate preview size
    final previewAspectRatio = _cameraController!.value.aspectRatio;
    double previewWidth, previewHeight;

    if (screenSize.width / screenSize.height > previewAspectRatio) {
      previewHeight = screenSize.height;
      previewWidth = previewHeight * previewAspectRatio;
    } else {
      previewWidth = screenSize.width;
      previewHeight = previewWidth / previewAspectRatio;
    }

    // Scale factors
    final scaleX = previewWidth / imageSize.width;
    final scaleY = previewHeight / imageSize.height;

    // Calculate position and size
    final left = bbox.x1 * scaleX;
    final top = bbox.y1 * scaleY;
    final width = (bbox.x2 - bbox.x1) * scaleX;
    final height = (bbox.y2 - bbox.y1) * scaleY;

    // Center offset
    final offsetX = (screenSize.width - previewWidth) / 2;
    final offsetY = (screenSize.height - previewHeight) / 2;

    return Positioned(
      left: left + offsetX,
      top: top + offsetY,
      child: GestureDetector(
        onTap: face.recognized
            ? () {
                setState(() {
                  _selectedFace = face;
                });
              }
            : null,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(
              color: face.recognized ? Colors.green : Colors.red,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Name label at top
              if (face.recognized)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          face.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(face.matchConfidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
  }

  Widget _buildPunchButton(String punchType) {
    return ElevatedButton(
      onPressed: () => _markAttendance(_selectedFace!, punchType),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getPunchTypeColor(punchType),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPunchTypeIcon(punchType), size: 24),
          const SizedBox(height: 4),
          Text(
            _getPunchTypeName(punchType),
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

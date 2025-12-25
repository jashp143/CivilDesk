import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/services/face_recognition_service.dart';
import '../../models/face_recognition.dart';
import '../../widgets/toast.dart';

class FaceAttendanceAnnotatedScreen extends StatefulWidget {
  const FaceAttendanceAnnotatedScreen({super.key});

  @override
  State<FaceAttendanceAnnotatedScreen> createState() => _FaceAttendanceAnnotatedScreenState();
}

class _FaceAttendanceAnnotatedScreenState extends State<FaceAttendanceAnnotatedScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  bool _isProcessing = false;
  Uint8List? _annotatedImageBytes;
  List<DetectedFace> _detectedFaces = [];
  DetectedFace? _selectedFace;
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
      if (mounted) {
        Toast.error(context, 'Error initializing camera: $e');
      }
    }
  }

  void _startDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
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

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);

      // Get both annotated image AND face recognition data
      final annotatedImageBytes = await _faceService.getAnnotatedImage(file);
      
      // Also get face recognition data for punch buttons
      final recognitionResponse = await _faceService.recognizeStream(file);
      
      if (mounted) {
        List<DetectedFace> faces = [];
        if (recognitionResponse['success'] == true && recognitionResponse['faces'] != null) {
          faces = (recognitionResponse['faces'] as List)
              .map((face) => DetectedFace.fromJson(face))
              .toList();
        }
        
        // Enhanced console logging
        debugPrint('\n${'='*80}');
        debugPrint('🔍 FACE DETECTION RESULT (FRONTEND):');
        debugPrint('   Total faces detected: ${faces.length}');
        
        for (var i = 0; i < faces.length; i++) {
          final face = faces[i];
          if (face.recognized) {
            debugPrint('   ✅ Face #${i+1}: ${face.firstName}_${face.lastName}');
            debugPrint('      🆔 Employee ID: ${face.employeeId}');
            debugPrint('      📊 Confidence: ${(face.matchConfidence * 100).toStringAsFixed(1)}%');
          } else {
            debugPrint('   ⚠️  Face #${i+1}: Unknown');
          }
        }
        debugPrint('='*80 + '\n');
        
        setState(() {
          _annotatedImageBytes = annotatedImageBytes;
          _detectedFaces = faces;
          _isDetecting = false;
        });
      }

      // Continue detection loop
      _startDetection();
    } catch (e) {
      debugPrint('\n❌ ERROR DETECTING FACES: $e\n');
      if (mounted) {
        setState(() {
          _isDetecting = false;
          _annotatedImageBytes = null;
          _detectedFaces = [];
        });
      }
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
          // Enhanced console logging for attendance marking
          debugPrint('\n${'🎯'*40}');
          debugPrint('✅ ATTENDANCE MARKED SUCCESSFULLY (FRONTEND):');
          debugPrint('   👤 Name: ${face.firstName}_${face.lastName}');
          debugPrint('   🆔 Employee ID: ${face.employeeId}');
          debugPrint('   ⏰ Punch Type: ${punchType.toUpperCase().replaceAll('_', ' ')}');
          debugPrint('   📊 Confidence: ${(face.matchConfidence * 100).toStringAsFixed(1)}%');
          if (response['attendance_id'] != null) {
            debugPrint('   🔖 Attendance ID: ${response['attendance_id']}');
          }
          debugPrint('${'🎯'*40}\n');
          
          Toast.success(
            context,
            'Attendance marked for ${face.displayName} - ${_getPunchTypeName(punchType)}',
            duration: const Duration(seconds: 2),
          );
          
          setState(() {
            _selectedFace = null;
          });
        } else {
          debugPrint('\n❌ ATTENDANCE MARKING FAILED: ${response['message'] ?? 'Unknown error'}\n');
          
          Toast.error(context, response['message'] ?? 'Failed to mark attendance');
        }
      }
    } catch (e) {
      debugPrint('\n❌ ERROR MARKING ATTENDANCE: $e\n');
      
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
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Face Recognition Attendance'),
        ),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Face Recognition Attendance'),
            Text(
              'With Bounding Boxes & Names',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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
          // Show annotated image if available, otherwise show camera preview
          Center(
            child: GestureDetector(
              onTap: () {
                // When user taps on image, select first recognized face
                final recognizedFaces = _detectedFaces.where((f) => f.recognized).toList();
                if (recognizedFaces.isNotEmpty && _selectedFace == null) {
                  setState(() {
                    _selectedFace = recognizedFaces.first;
                  });
                }
              },
              child: _annotatedImageBytes != null
                  ? Image.memory(
                      _annotatedImageBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true, // Smooth transition between frames
                    )
                  : AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
            ),
          ),

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE DETECTION',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bounding boxes & names drawn by AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Recognized',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Unknown',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                    if (_detectedFaces.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: [
                            Text(
                              '${_detectedFaces.where((f) => f.recognized).length} face(s) recognized',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap on image to mark attendance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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

  Widget _buildPunchButton(String punchType) {
    return ElevatedButton(
      onPressed: () => _markAttendance(_selectedFace!, punchType),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getPunchTypeColor(punchType),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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


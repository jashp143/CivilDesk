import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/services/face_recognition_service.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class FaceRegistrationScreen extends StatefulWidget {
  final String employeeId;

  const FaceRegistrationScreen({Key? key, required this.employeeId}) : super(key: key);

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isProcessing = false;
  int _recordingDuration = 0;
  String? _videoPath;
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
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Start recording - the camera package will save to a temporary location
      // We'll get the actual path from stopVideoRecording()
      await _cameraController!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _videoPath = null; // Will be set from stopVideoRecording()
      });

      // Start timer
      _startTimer();
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration++;
        });
        
        if (_recordingDuration >= 15) {
          _stopRecording();
        } else {
          _startTimer();
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) {
      return;
    }

    try {
      // stopVideoRecording returns an XFile with the actual video path
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      
      setState(() {
        _isRecording = false;
        _videoPath = videoFile.path; // Use the actual path from the XFile
      });

      // Verify the file exists before processing
      final file = File(_videoPath!);
      if (await file.exists()) {
        await _processVideo();
      } else {
        throw Exception('Video file not found at path: $_videoPath');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _processVideo() async {
    if (_videoPath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final videoFile = File(_videoPath!);
      
      // Verify file exists and has content
      if (!await videoFile.exists()) {
        throw Exception('Video file does not exist at path: $_videoPath');
      }
      
      final fileSize = await videoFile.length();
      if (fileSize == 0) {
        throw Exception('Video file is empty');
      }
      
      final response = await _faceService.registerFace(widget.employeeId, videoFile);

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Failed to register face'),
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
          title: const Text('Face Registration'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Face Registration'),
            Text(
              'Employee ID: ${widget.employeeId}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
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
          
          // Instructions overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Position your face in the center',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Text(
                    '2. Ensure good lighting',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Text(
                    '3. Keep your face still',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Text(
                    '4. Recording will last 15 seconds',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Recording indicator
          if (_isRecording)
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recording: ${_recordingDuration}/15s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Processing indicator
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
                        'Processing video...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Control buttons
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _isRecording
                  ? ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _startRecording,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Start Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


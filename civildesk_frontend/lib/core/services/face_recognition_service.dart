import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class FaceRecognitionService {
  late Dio _faceServiceDio;

  FaceRecognitionService() {
    _faceServiceDio = Dio(
      BaseOptions(
        baseUrl: AppConstants.faceServiceUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  /// Register face from 15-second video
  Future<Map<String, dynamic>> registerFace(String employeeId, File videoFile) async {
    try {
      FormData formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(videoFile.path),
        'employee_id': employeeId,
      });

      final response = await _faceServiceDio.post(
        '/face/register',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return response.data;
    } catch (e) {
      throw Exception('Error registering face: $e');
    }
  }

  /// Detect faces in an image
  Future<Map<String, dynamic>> detectFaces(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _faceServiceDio.post(
        '/face/detect',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return response.data;
    } catch (e) {
      throw Exception('Error detecting faces: $e');
    }
  }

  /// Recognize faces in real-time stream
  /// Phase 2 Optimization: Added CancelToken support for cancelling in-flight requests
  Future<Map<String, dynamic>> recognizeStream(
    File imageFile, {
    CancelToken? cancelToken,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _faceServiceDio.post(
        '/face/recognize-stream',
        data: formData,
        cancelToken: cancelToken,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return response.data;
    } on DioException {
      rethrow; // Allow caller to handle cancel errors
    } catch (e) {
      throw Exception('Error recognizing faces: $e');
    }
  }

  /// Mark attendance using face recognition
  Future<Map<String, dynamic>> markAttendance({
    required String employeeId,
    required String punchType,
    required double confidence,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'employee_id': employeeId,
        'punch_type': punchType,
        'confidence': confidence,
      });

      final response = await _faceServiceDio.post(
        '/face/attendance/mark',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return response.data;
    } catch (e) {
      throw Exception('Error marking attendance: $e');
    }
  }

  /// Check face recognition service health
  Future<bool> checkHealth() async {
    try {
      final response = await _faceServiceDio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete face embeddings for an employee
  Future<bool> deleteFaceEmbeddings(String employeeId) async {
    try {
      final response = await _faceServiceDio.delete('/face/embeddings/$employeeId');
      if (response.statusCode == 200) {
        final data = response.data;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      // If employee doesn't have face embeddings, that's okay
      return false;
    }
  }

  /// Get annotated image with bounding boxes and names drawn
  Future<Uint8List?> getAnnotatedImage(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _faceServiceDio.post(
        '/face/recognize-annotated',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          responseType: ResponseType.bytes, // Important: get bytes response
        ),
      );

      return response.data as Uint8List;
    } catch (e) {
      debugPrint('Error getting annotated image: $e');
      return null;
    }
  }

  /// List all registered face embeddings
  Future<Map<String, dynamic>> listEmbeddings() async {
    try {
      final response = await _faceServiceDio.get('/face/embeddings/list');
      return response.data;
    } catch (e) {
      throw Exception('Error listing embeddings: $e');
    }
  }
}


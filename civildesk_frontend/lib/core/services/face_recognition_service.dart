import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class FaceRecognitionService {
  final ApiService _apiService = ApiService();
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

  /// Register face from 10-second video
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
}


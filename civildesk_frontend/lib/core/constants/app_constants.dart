import 'dart:io';

class AppConstants {
  // API Configuration
  // Production Backend URL - Update this with your deployed server URL
  // IMPORTANT: Do NOT include /api in the URL - it will be added automatically
  // Examples:
  //   - HTTPS with domain: 'https://your-domain.com'
  //   - HTTPS with IP: 'https://123.456.789.0'
  //   - HTTP only: 'http://your-server-ip:8080' (if Nginx is not configured)
  static const String _productionBackendUrl = 'https://civildesk-api.devopsinfos.live'; // TODO: Replace with your actual backend URL
  static const String _productionFaceServiceUrl = 'https://your-aws-face-service-url.com'; // TODO: Replace with your face service URL (or leave as is if not using face service)
  
  // Development URLs (for local testing)
  static const String _devBackendUrl = 'http://192.168.0.193:8080/api';
  static const String _devFaceServiceUrl = 'http://192.168.0.193:8000';
  
  // Set to true for production, false for local development
  static const bool _isProduction = false; // TODO: Set to false for local development
  
  static String get baseUrl {
    if (_isProduction) {
      // Production: Use deployed backend URL
      return '$_productionBackendUrl/api';
    } else {
      // Development: Use local URLs based on platform
      if (Platform.isAndroid) {
        // Android emulator uses 10.0.2.2 to access host machine's localhost
        return _devBackendUrl;
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost
        return 'http://localhost:8080/api';
      } else {
        // For other platforms (Windows, macOS, Linux), use localhost
        return 'http://localhost:8080/api';
      }
    }
  }

  static String get faceServiceUrl {
    if (_isProduction) {
      // Production: Use deployed face service URL
      return _productionFaceServiceUrl;
    } else {
      // Development: Use local URLs
      if (Platform.isAndroid) {
        return _devFaceServiceUrl;
      } else if (Platform.isIOS) {
        return 'http://localhost:8000';
      } else {
        return 'http://localhost:8000';
      }
    }
  }

  // Alternative: Use your actual IP address for physical devices
  // Uncomment and replace with your computer's IP address if testing on physical device
  // static const String baseUrl = 'http://192.168.1.100:8080/api';
  // static const String faceServiceUrl = 'http://192.168.1.100:8000';
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // API Endpoints
  static const String loginEndpoint = '/auth/login/admin';
  static const String signupEndpoint = '/auth/signup';
  static const String sendOtpEndpoint = '/auth/send-otp';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String employeesEndpoint = '/employees';
  static const String attendanceEndpoint = '/attendance';
  static const String salaryEndpoint = '/salary';
  static const String leaveEndpoint = '/leave';
  static const String dashboardEndpoint = '/dashboard';

  // Face Recognition Endpoints
  static const String faceRegisterEndpoint = '/face/register';
  static const String faceRecognizeEndpoint = '/face/recognize';

  // User Roles
  static const String roleAdmin = 'ADMIN';
  static const String roleHrManager = 'HR_MANAGER';
  static const String roleEmployee = 'EMPLOYEE';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy HH:mm';

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  
  // Aadhar & PAN validation
  static const int aadharLength = 12;
  static const int panLength = 10;
}


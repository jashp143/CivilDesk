import 'dart:io';

class AppConstants {
  // API Configuration
  // For Android emulator, use 10.0.2.2 instead of localhost
  // For iOS simulator, localhost works
  // For physical devices, use your computer's IP address (e.g., http://192.168.1.100:8080)
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:8080/api';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:8080/api';
    } else {
      // For other platforms (Windows, macOS, Linux), use localhost
      return 'http://localhost:8080/api';
    }
  }

  static String get faceServiceUrl {
    if (Platform.isAndroid) {
      return 'http://localhost:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      return 'http://localhost:8000';
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


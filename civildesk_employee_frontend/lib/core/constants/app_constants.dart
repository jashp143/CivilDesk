import 'dart:io';

class AppConstants {
  // API Configuration
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.0.193:8080/api';
    } else if (Platform.isIOS) {
      return 'http://192.168.0.193:8080/api';
    } else {
      return 'http://192.168.0.193:8080/api';
    }
  }

  static String get faceServiceUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.0.193:8000';
    } else if (Platform.isIOS) {
      return 'http://192.168.0.193:8000';
    } else {
      return 'http://192.168.0.193:8000';
    }
  }

  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeModeKey = 'theme_mode';
  static const String colorPaletteKey = 'color_palette';

  // API Endpoints
  static const String loginEndpoint = '/auth/login/employee';
  static const String logoutEndpoint = '/auth/logout';
  static const String employeesEndpoint = '/employees';
  static const String attendanceEndpoint = '/attendance';
  static const String leaveEndpoint = '/leave';
  static const String dashboardEndpoint = '/dashboard/employee';

  // Face Recognition Endpoints
  static const String faceRecognizeEndpoint = '/face/recognize';

  // User Roles
  static const String roleEmployee = 'EMPLOYEE';

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy HH:mm';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
}


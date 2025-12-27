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
      // Development: Use local URLs
      return _devBackendUrl;
    }
  }

  static String get faceServiceUrl {
    if (_isProduction) {
      // Production: Use deployed face service URL
      return _productionFaceServiceUrl;
    } else {
      // Development: Use local URLs
      return _devFaceServiceUrl;
    }
  }

  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeModeKey = 'theme_mode';
  static const String colorPaletteKey = 'color_palette';
  static const String notificationsEnabledKey = 'notifications_enabled';

  // API Endpoints
  static const String loginEndpoint = '/auth/login/employee';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String changePasswordEndpoint = '/auth/change-password';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
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


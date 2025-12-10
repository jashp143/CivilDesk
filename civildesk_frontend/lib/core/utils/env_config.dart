import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  /// Get Google Maps API Key from environment variables
  static String get googleMapsApiKey {
    try {
      return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    } catch (e) {
      // Return empty string if dotenv is not loaded or key doesn't exist
      return '';
    }
  }
  
  /// Check if Google Maps API Key is configured
  static bool get isGoogleMapsConfigured {
    final key = googleMapsApiKey;
    return key.isNotEmpty && key != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  }
}


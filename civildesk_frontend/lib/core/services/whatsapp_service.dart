import 'package:url_launcher/url_launcher.dart';

/// Service for sending WhatsApp messages to employees
class WhatsAppService {
  /// Launches WhatsApp with a pre-filled message to a specific phone number
  /// 
  /// [phoneNumber] - The phone number in format: 91XXXXXXXXXX (country code + number)
  /// [message] - The message to pre-fill (optional)
  /// 
  /// Returns true if WhatsApp was launched successfully, false otherwise
  static Future<bool> launchWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      // Format phone number: remove any spaces, dashes, or special characters
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // If phone number doesn't start with +, add country code (assuming India +91)
      if (!cleanPhone.startsWith('+')) {
        // If it's a 10-digit number, add +91
        if (cleanPhone.length == 10) {
          cleanPhone = '+91$cleanPhone';
        } else if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
          cleanPhone = '+$cleanPhone';
        } else {
          // Assume it already has country code
          cleanPhone = '+$cleanPhone';
        }
      }

      // Remove the + sign for whatsapp:// scheme (it doesn't need it)
      String phoneWithoutPlus = cleanPhone.replaceFirst('+', '');

      // Try multiple methods to launch WhatsApp
      // Method 1: Try https://wa.me first (most reliable, works even if queries fail)
      String url = 'https://wa.me/$phoneWithoutPlus';
      
      if (message != null && message.isNotEmpty) {
        final encodedMessage = Uri.encodeComponent(message);
        url = 'https://wa.me/$phoneWithoutPlus?text=$encodedMessage';
      }

      final uri = Uri.parse(url);
      
      // Try launching directly without canLaunchUrl check (more reliable)
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        // Continue to next method
      }

      // Method 2: Try whatsapp:// scheme directly (don't check canLaunchUrl)
      if (message != null && message.isNotEmpty) {
        final encodedMessage = Uri.encodeComponent(message);
        final whatsappUri = Uri.parse('whatsapp://send?phone=$phoneWithoutPlus&text=$encodedMessage');
        
        try {
          final launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        } catch (e) {
          // Continue
        }
      } else {
        // No message, just open chat
        final whatsappUri = Uri.parse('whatsapp://send?phone=$phoneWithoutPlus');
        
        try {
          final launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        } catch (e) {
          // Continue
        }
      }

      // Method 3: Try platform default as last resort
      try {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Shares a message via WhatsApp without specifying a phone number
  /// Opens WhatsApp share dialog where user can choose the contact
  /// 
  /// [message] - The message to share (required)
  /// 
  /// Returns true if WhatsApp was launched successfully, false otherwise
  static Future<bool> shareViaWhatsApp({
    required String message,
  }) async {
    try {
      if (message.isEmpty) {
        return false;
      }

      // Encode the message
      final encodedMessage = Uri.encodeComponent(message);
      
      // Method 1: Try whatsapp://send?text= first (opens share dialog, most reliable)
      final whatsappUri = Uri.parse('whatsapp://send?text=$encodedMessage');
      
      try {
        final launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      } catch (e) {
        // Continue to next method
      }

      // Method 2: Try https://wa.me/?text= (works without queries)
      final webUri = Uri.parse('https://wa.me/?text=$encodedMessage');
      
      try {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      } catch (e) {
        // Try platform default
        try {
          return await launchUrl(webUri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Formats a 10-digit Indian phone number to WhatsApp format
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any spaces, dashes, or special characters
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it's a 10-digit number, add +91
    if (cleanPhone.length == 10) {
      return '+91$cleanPhone';
    } else if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      return '+$cleanPhone';
    } else if (cleanPhone.startsWith('+')) {
      return cleanPhone;
    } else {
      // Assume it needs country code
      return '+91$cleanPhone';
    }
  }
}


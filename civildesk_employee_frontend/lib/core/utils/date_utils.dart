import 'package:intl/intl.dart';

/// Utility class for date and time operations
class DateUtils {
  /// India Standard Time offset: UTC+5:30
  static const Duration indiaTimeOffset = Duration(hours: 5, minutes: 30);

  /// Converts a DateTime to India Standard Time (IST)
  /// Assumes the input DateTime is in UTC (as received from backend)
  /// and converts it to IST (UTC+5:30)
  static DateTime toIndiaTime(DateTime dateTime) {
    // Convert to UTC if not already, then add IST offset
    final utcTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
    return utcTime.add(indiaTimeOffset);
  }

  /// Formats a DateTime to India time with date and time
  /// Returns formatted string: "MMM dd, yyyy • hh:mm a"
  static String formatIndiaDateTime(DateTime dateTime) {
    final indiaTime = toIndiaTime(dateTime);
    return '${DateFormat('MMM dd, yyyy').format(indiaTime)} • ${DateFormat('hh:mm a').format(indiaTime)}';
  }

  /// Formats a DateTime to India time with date only
  /// Returns formatted string: "MMM dd, yyyy"
  static String formatIndiaDate(DateTime dateTime) {
    final indiaTime = toIndiaTime(dateTime);
    return DateFormat('MMM dd, yyyy').format(indiaTime);
  }

  /// Formats a DateTime to India time with time only
  /// Returns formatted string: "hh:mm a"
  static String formatIndiaTime(DateTime dateTime) {
    final indiaTime = toIndiaTime(dateTime);
    return DateFormat('hh:mm a').format(indiaTime);
  }
}


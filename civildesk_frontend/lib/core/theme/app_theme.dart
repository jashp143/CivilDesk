import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Dashboard-Specific Colors (used in both themes)
class AppThemeColors {
  // Statistics Card Colors
  static const Color statBlue = Color(0xFF3B82F6); // Total Employees
  static const Color statCyan = Color(0xFF06B6D4); // Total Leaves
  static const Color statPurple = Color(0xFF8B5CF6); // Total Overtime
  static const Color statGreen = Color(0xFF10B981); // Total Expenses
  static const Color statIndigo = Color(0xFF6366F1); // Total Tasks

  // Status Colors
  static const Color statusPending = Color(0xFFF59E0B); // Amber/Orange
  static const Color statusApproved = Color(0xFF10B981); // Green
  static const Color statusRejected = Color(0xFFEF4444); // Red

  // Tracking Card Colors
  static const Color trackingExpense = Color(0xFF10B981); // Green
  static const Color trackingLeave = Color(0xFFF59E0B); // Amber/Orange
  static const Color trackingOvertime = Color(0xFF8B5CF6); // Purple

  // Text colors with opacity (approximated for const usage)
  // Black with 0.7 opacity on white ≈ #4D4D4D
  static const Color lightTextSecondary = Color(0xFF4D4D4D);
  // Black with 0.6 opacity on white ≈ #666666
  static const Color lightTextTertiary = Color(0xFF666666);
  // White with 0.7 opacity on black ≈ #B2B2B2
  static const Color darkTextSecondary = Color(0xFFB2B2B2);
  // White with 0.6 opacity on black ≈ #999999
  static const Color darkTextTertiary = Color(0xFF999999);
}

// Welcome Section Colors Helper
class WelcomeColors {
  // Light Theme Welcome Colors
  static Color getLightGradientStart() => Colors.blue[50]!; // #EFF6FF
  static Color getLightGradientEnd() => Colors.blue[100]!.withValues(alpha: 0.5);
  static Color getLightBorder() => Colors.blue[200]!.withValues(alpha: 0.5);
  static List<Color> getLightIconGradient() => [
        Colors.blue[500]!,
        Colors.blue[700]!,
      ];
  static Color getLightGreetingText() => Colors.blue[700]!;
  static Color getLightDateBadgeBackground() => Colors.blue[200]!.withValues(alpha: 0.5);
  static Color getLightDateBadgeText() => Colors.blue[700]!;
  static Color getLightTrendingIcon() => Colors.blue[600]!;
  static Color getLightSubtitleText() => Colors.blue[700]!.withValues(alpha: 0.8);

  // Dark Theme Welcome Colors
  static Color getDarkGradientStart() => Colors.blue[900]!.withValues(alpha: 0.3);
  static Color getDarkGradientEnd() => Colors.blue[800]!.withValues(alpha: 0.2);
  static Color getDarkBorder() => Colors.blue[700]!.withValues(alpha: 0.3);
  static List<Color> getDarkIconGradient() => [
        Colors.blue[600]!,
        Colors.blue[800]!,
      ];
  static Color getDarkGreetingText() => Colors.blue[200]!;
  static Color getDarkDateBadgeBackground() => Colors.blue[800]!.withValues(alpha: 0.3);
  static Color getDarkDateBadgeText() => Colors.blue[300]!;
  static Color getDarkTrendingIcon() => Colors.blue[300]!;
  static Color getDarkSubtitleText() => Colors.blue[200]!.withValues(alpha: 0.8);
}

// Shadow Helpers
class AppThemeShadows {
  // Welcome Section Shadows (Light)
  static List<BoxShadow> getLightWelcomeShadows() => [
        BoxShadow(
          color: Colors.blue.withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // Welcome Section Shadows (Dark)
  static List<BoxShadow> getDarkWelcomeShadows() => [
        BoxShadow(
          color: Colors.blue.withValues(alpha: 0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // Icon Shadow (Welcome Section)
  static BoxShadow getIconShadow() => BoxShadow(
        color: Colors.blue.withValues(alpha: 0.4),
        blurRadius: 16,
        offset: const Offset(0, 6),
      );

  // Statistics Card Shadow (Light) - Color-specific
  static BoxShadow getStatCardShadowLight(Color color) => BoxShadow(
        color: color.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 4),
      );

  // Statistics Card Shadow (Dark)
  static BoxShadow getStatCardShadowDark() => BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 4),
      );
}

class AppTheme {
  // Dashboard-Specific Colors (used in both themes)
  // Statistics Card Colors
  static const Color statBlue = AppThemeColors.statBlue;
  static const Color statCyan = AppThemeColors.statCyan;
  static const Color statPurple = AppThemeColors.statPurple;
  static const Color statGreen = AppThemeColors.statGreen;
  static const Color statIndigo = AppThemeColors.statIndigo;

  // Status Colors
  static const Color statusPending = AppThemeColors.statusPending;
  static const Color statusApproved = AppThemeColors.statusApproved;
  static const Color statusRejected = AppThemeColors.statusRejected;

  // Tracking Card Colors
  static const Color trackingExpense = AppThemeColors.trackingExpense;
  static const Color trackingLeave = AppThemeColors.trackingLeave;
  static const Color trackingOvertime = AppThemeColors.trackingOvertime;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        secondary: Colors.black,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        outline: const Color(0xFF333333), // Black with 0.2 opacity
      ),

      // Scaffold
      scaffoldBackgroundColor: Colors.white,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark status bar icons for light background
      ),

      // Cards
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        labelStyle: const TextStyle(color: Colors.black),
        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
        ),
      ),

      // Dividers
      dividerColor: Colors.black,
      dividerTheme: const DividerThemeData(color: Colors.black, thickness: 1),

      // Typography
      textTheme: TextTheme(
        // Headline Values: 28px, Bold, Letter Spacing -0.8, Line Height 1.1
        headlineLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.8,
          height: 1.1,
          color: Colors.black,
        ),
        // Section Titles: 18px, Bold, Letter Spacing -0.3
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          color: Colors.black,
        ),
        // Card Titles: 13px, Weight 500, Opacity 0.7
        titleMedium: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppThemeColors.lightTextSecondary,
        ),
        // Subtitle Text: 13px, Weight 500
        titleSmall: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        // Small Text: 11px, Weight 500, Opacity 0.6
        bodySmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppThemeColors.lightTextTertiary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        secondary: Colors.white,
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.white,
        outline: const Color(0xFFCCCCCC), // White with 0.2 opacity
      ),

      // Scaffold
      scaffoldBackgroundColor: Colors.black,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light, // Light status bar icons for dark background
      ),

      // Cards
      cardTheme: CardThemeData(
        color: Colors.black,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white, width: 1),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
        ),
      ),

      // Dividers
      dividerColor: Colors.white,
      dividerTheme: const DividerThemeData(color: Colors.white, thickness: 1),

      // Typography
      textTheme: TextTheme(
        // Headline Values: 28px, Bold, Letter Spacing -0.8, Line Height 1.1
        headlineLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.8,
          height: 1.1,
          color: Colors.white,
        ),
        // Section Titles: 18px, Bold, Letter Spacing -0.3
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          color: Colors.white,
        ),
        // Card Titles: 13px, Weight 500, Opacity 0.7
        titleMedium: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppThemeColors.darkTextSecondary,
        ),
        // Subtitle Text: 13px, Weight 500
        titleSmall: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        // Small Text: 11px, Weight 500, Opacity 0.6
        bodySmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppThemeColors.darkTextTertiary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

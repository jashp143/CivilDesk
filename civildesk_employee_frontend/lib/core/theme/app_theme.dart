import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  // Primary
  static const Color lightPrimary = Color(0xFF6B2B3A);
  static const Color lightPrimaryLight = Color(0xFF8B4B5A);
  static const Color lightPrimaryDark = Color(0xFF4B1B2A);
  
  // Secondary
  static const Color lightSecondary = Color(0xFF9B5B6A);
  static const Color lightSecondaryLight = Color(0xFFB37B8A);
  static const Color lightSecondaryDark = Color(0xFF7B3B4A);
  
  // Background
  static const Color lightBackground = Color(0xFFF8F2F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  // Text
  static const Color lightTextPrimary = Color(0xFF6B2B3A);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  
  // Error
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightOnError = Color(0xFFFFFFFF);
  
  // On Colors
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF6B2B3A);
  static const Color lightOnSurface = Color(0xFF6B2B3A);

  // Dark Theme Colors
  // Primary
  static const Color darkPrimary = Color(0xFF8B4B5A);
  static const Color darkPrimaryLight = Color(0xFFAB6B7A);
  static const Color darkPrimaryDark = Color(0xFF6B2B3A);
  
  // Secondary
  static const Color darkSecondary = Color(0xFF9B5B6A);
  static const Color darkSecondaryLight = Color(0xFFBB7B8A);
  static const Color darkSecondaryDark = Color(0xFF7B3B4A);
  
  // Background
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  // Text
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE0E0E0);
  
  // Actions
  static const Color darkActionActive = Color(0xFFFFFFFF);
  static const Color darkActionHover = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color darkActionSelected = Color.fromRGBO(255, 255, 255, 0.16);
  static const Color darkActionDisabled = Color.fromRGBO(255, 255, 255, 0.3);
  static const Color darkActionDisabledBackground = Color.fromRGBO(255, 255, 255, 0.12);
  static const Color darkDivider = Color.fromRGBO(255, 255, 255, 0.12);
  
  // Error
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkOnError = Color(0xFFFFFFFF);
  
  // On Colors
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnSecondary = Color(0xFFFFFFFF);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFFFFFFF);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      primaryColorDark: lightPrimaryDark,
      primaryColorLight: lightPrimaryLight,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        primaryContainer: lightPrimaryLight,
        secondary: lightSecondary,
        secondaryContainer: lightSecondaryLight,
        surface: lightSurface,
        surfaceVariant: lightBackground,
        error: lightError,
        onPrimary: lightOnPrimary,
        onSecondary: lightOnSecondary,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightTextSecondary,
        onError: lightOnError,
        outline: lightTextSecondary,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: lightTextPrimary),
        bodyMedium: TextStyle(color: lightTextPrimary),
        bodySmall: TextStyle(color: lightTextSecondary),
        labelLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: lightTextSecondary),
        labelSmall: TextStyle(color: lightTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightPrimary,
        foregroundColor: lightOnPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: lightOnPrimary),
        titleTextStyle: const TextStyle(
          color: lightOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2.0,
        shadowColor: lightPrimary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: lightPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: lightTextSecondary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: lightTextSecondary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: lightPrimary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: lightError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: lightError, width: 2.0),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: TextStyle(color: lightTextSecondary.withOpacity(0.6)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightPrimary,
        foregroundColor: lightOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: lightTextSecondary.withOpacity(0.2),
        thickness: 1.0,
        space: 1.0,
      ),
      iconTheme: const IconThemeData(
        color: lightTextPrimary,
        size: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBackground,
        selectedColor: lightPrimary,
        labelStyle: const TextStyle(color: lightTextPrimary),
        secondaryLabelStyle: const TextStyle(color: lightOnPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurface,
        contentTextStyle: const TextStyle(color: lightOnSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: lightSurface,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: lightPrimary,
        selectedTileColor: lightPrimary.withOpacity(0.1),
        iconColor: lightTextPrimary,
        textColor: lightTextPrimary,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      primaryColorDark: darkPrimaryDark,
      primaryColorLight: darkPrimaryLight,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        primaryContainer: darkPrimaryLight,
        secondary: darkSecondary,
        secondaryContainer: darkSecondaryLight,
        surface: darkSurface,
        surfaceVariant: darkBackground,
        error: darkError,
        onPrimary: darkOnPrimary,
        onSecondary: darkOnSecondary,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkTextSecondary,
        onError: darkOnError,
        outline: darkDivider,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: darkTextPrimary),
        bodyMedium: TextStyle(color: darkTextPrimary),
        bodySmall: TextStyle(color: darkTextSecondary),
        labelLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: darkTextSecondary),
        labelSmall: TextStyle(color: darkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkOnSurface),
        titleTextStyle: const TextStyle(
          color: darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2.0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: darkPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: darkPrimary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: darkError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: darkError, width: 2.0),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: TextStyle(color: darkTextSecondary.withOpacity(0.6)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: darkOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1.0,
        space: 1.0,
      ),
      iconTheme: const IconThemeData(
        color: darkTextPrimary,
        size: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: darkPrimary,
        labelStyle: const TextStyle(color: darkTextPrimary),
        secondaryLabelStyle: const TextStyle(color: darkOnPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: const TextStyle(color: darkOnSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: darkActionSelected,
        selectedTileColor: darkActionSelected,
        iconColor: darkTextPrimary,
        textColor: darkTextPrimary,
      ),
    );
  }
}

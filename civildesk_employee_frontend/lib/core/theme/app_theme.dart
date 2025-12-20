import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class AppTheme {
  // Color Palette 1: Blue tones
  // Light: #0047AB, #000080, #82C8E5, #6D8196
  // Dark: #0047AB, #000080, #82C8E5, #6D8196
  static const Color _palette1LightPrimary = Color(0xFF0047AB);
  static const Color _palette1LightPrimaryDark = Color(0xFF000080);
  static const Color _palette1LightSecondary = Color(0xFF82C8E5);
  static const Color _palette1LightAccent = Color(0xFF6D8196);
  
  static const Color _palette1DarkPrimary = Color(0xFF0047AB);
  static const Color _palette1DarkPrimaryDark = Color(0xFF000080);
  static const Color _palette1DarkSecondary = Color(0xFF82C8E5);
  static const Color _palette1DarkAccent = Color(0xFF6D8196);

  // Color Palette 2: Grayscale
  // Light: #FFFFFF, #D4D4D4, #B3B3B3, #2B2B2B
  // Dark: #FFFFFF, #D4D4D4, #B3B3B3, #2B2B2B
  static const Color _palette2LightPrimary = Color(0xFF2B2B2B);
  static const Color _palette2LightPrimaryDark = Color(0xFF1A1A1A);
  static const Color _palette2LightSecondary = Color(0xFFB3B3B3);
  static const Color _palette2LightAccent = Color(0xFFD4D4D4);
  
  static const Color _palette2DarkPrimary = Color(0xFFB3B3B3);
  static const Color _palette2DarkPrimaryDark = Color(0xFFD4D4D4);
  static const Color _palette2DarkSecondary = Color(0xFF2B2B2B);
  static const Color _palette2DarkAccent = Color(0xFF1A1A1A);

  // Color Palette 3: Green/Red tones
  // Light: #CBCBCB, #F2F2F2, #174D38, #4D1717
  // Dark: #CBCBCB, #F2F2F2, #174D38, #4D1717
  static const Color _palette3LightPrimary = Color(0xFF174D38);
  static const Color _palette3LightPrimaryDark = Color(0xFF0F3525);
  static const Color _palette3LightSecondary = Color(0xFF4D1717);
  static const Color _palette3LightAccent = Color(0xFFCBCBCB);
  
  static const Color _palette3DarkPrimary = Color(0xFF174D38);
  static const Color _palette3DarkPrimaryDark = Color(0xFF0F3525);
  static const Color _palette3DarkSecondary = Color(0xFF4D1717);
  static const Color _palette3DarkAccent = Color(0xFFCBCBCB);

  // Common colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightOnError = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkOnError = Color(0xFFFFFFFF);
  static const Color darkDivider = Color.fromRGBO(255, 255, 255, 0.12);

  // Get theme based on palette and brightness
  static ThemeData getTheme(ColorPalette palette, Brightness brightness) {
    if (brightness == Brightness.light) {
      return _getLightTheme(palette);
    } else {
      return _getDarkTheme(palette);
    }
  }

  static ThemeData _getLightTheme(ColorPalette palette) {
    Color primary;
    Color primaryDark;
    Color secondary;
    Color accent;

    switch (palette) {
      case ColorPalette.palette1:
        primary = _palette1LightPrimary;
        primaryDark = _palette1LightPrimaryDark;
        secondary = _palette1LightSecondary;
        accent = _palette1LightAccent;
        break;
      case ColorPalette.palette2:
        primary = _palette2LightPrimary;
        primaryDark = _palette2LightPrimaryDark;
        secondary = _palette2LightSecondary;
        accent = _palette2LightAccent;
        break;
      case ColorPalette.palette3:
        primary = _palette3LightPrimary;
        primaryDark = _palette3LightPrimaryDark;
        secondary = _palette3LightSecondary;
        accent = _palette3LightAccent;
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      primaryColorDark: primaryDark,
      scaffoldBackgroundColor: palette == ColorPalette.palette2 ? Color(0xFFF2F2F2) : lightBackground,
      colorScheme: ColorScheme.light(
        primary: primary,
        primaryContainer: primaryDark,
        secondary: secondary,
        secondaryContainer: accent,
        surface: palette == ColorPalette.palette2 ? Color(0xFFFFFFFF) : lightSurface,
        surfaceContainerHighest: palette == ColorPalette.palette2 ? Color(0xFFF2F2F2) : lightBackground,
        error: lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        onError: lightOnError,
        outline: lightTextSecondary,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary),
        bodyMedium: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary),
        bodySmall: TextStyle(color: lightTextSecondary),
        labelLarge: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: lightTextSecondary),
        labelSmall: TextStyle(color: lightTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette == ColorPalette.palette2 ? Color(0xFFFFFFFF) : lightSurface,
        elevation: 2.0,
        shadowColor: primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
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
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: primary, width: 1.5),
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
          foregroundColor: primary,
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
        fillColor: palette == ColorPalette.palette2 ? Color(0xFFFFFFFF) : lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: lightTextSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: lightTextSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: lightError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: lightError, width: 2.0),
        ),
        labelStyle: TextStyle(color: lightTextSecondary),
        hintStyle: TextStyle(color: lightTextSecondary.withValues(alpha: 0.6)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: lightTextSecondary.withValues(alpha: 0.2),
        thickness: 1.0,
        space: 1.0,
      ),
      iconTheme: IconThemeData(
        color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary,
        size: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette == ColorPalette.palette2 ? Color(0xFFF2F2F2) : lightBackground,
        selectedColor: primary,
        labelStyle: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette == ColorPalette.palette2 ? Color(0xFFFFFFFF) : lightSurface,
        contentTextStyle: TextStyle(color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: palette == ColorPalette.palette2 ? Color(0xFFFFFFFF) : lightSurface,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: primary,
        selectedTileColor: primary.withValues(alpha: 0.1),
        iconColor: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary,
        textColor: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : lightTextPrimary,
      ),
    );
  }

  static ThemeData _getDarkTheme(ColorPalette palette) {
    Color primary;
    Color primaryDark;
    Color secondary;
    Color accent;

    switch (palette) {
      case ColorPalette.palette1:
        primary = _palette1DarkPrimary;
        primaryDark = _palette1DarkPrimaryDark;
        secondary = _palette1DarkSecondary;
        accent = _palette1DarkAccent;
        break;
      case ColorPalette.palette2:
        primary = _palette2DarkPrimary;
        primaryDark = _palette2DarkPrimaryDark;
        secondary = _palette2DarkSecondary;
        accent = _palette2DarkAccent;
        break;
      case ColorPalette.palette3:
        primary = _palette3DarkPrimary;
        primaryDark = _palette3DarkPrimaryDark;
        secondary = _palette3DarkSecondary;
        accent = _palette3DarkAccent;
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      primaryColorDark: primaryDark,
      scaffoldBackgroundColor: palette == ColorPalette.palette2 ? Color(0xFF1A1A1A) : darkBackground,
      colorScheme: ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryDark,
        secondary: secondary,
        secondaryContainer: accent,
        surface: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : darkSurface,
        surfaceContainerHighest: palette == ColorPalette.palette2 ? Color(0xFF1A1A1A) : darkBackground,
        error: darkError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
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
        backgroundColor: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: const TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : darkSurface,
        elevation: 2.0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
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
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: primary, width: 1.5),
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
          foregroundColor: primary,
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
        fillColor: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : darkSurface,
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
          borderSide: BorderSide(color: primary, width: 2.0),
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
        hintStyle: TextStyle(color: darkTextSecondary.withValues(alpha: 0.6)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
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
        backgroundColor: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : darkSurface,
        selectedColor: primary,
        labelStyle: const TextStyle(color: darkTextPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : darkSurface,
        contentTextStyle: const TextStyle(color: darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: palette == ColorPalette.palette2 ? Color(0xFF2B2B2B) : darkSurface,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: primary,
        selectedTileColor: primary.withValues(alpha: 0.2),
        iconColor: darkTextPrimary,
        textColor: darkTextPrimary,
      ),
    );
  }

  // Legacy methods for backward compatibility
  static ThemeData get lightTheme => _getLightTheme(ColorPalette.palette1);
  static ThemeData get darkTheme => _getDarkTheme(ColorPalette.palette1);
}

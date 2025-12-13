import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

enum ColorPalette {
  palette1, // #0047AB, #000080, #82C8E5, #6D8196
  palette2, // #FFFFFF, #D4D4D4, #B3B3B3, #2B2B2B
  palette3, // #CBCBCB, #F2F2F2, #174D38, #4D1717
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ColorPalette _colorPalette = ColorPalette.palette1;

  ThemeMode get themeMode => _themeMode;
  ColorPalette get colorPalette => _colorPalette;
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeIndex = prefs.getInt(AppConstants.themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex.clamp(0, 2)];
    
    // Load color palette
    final paletteIndex = prefs.getInt(AppConstants.colorPaletteKey) ?? 0;
    _colorPalette = ColorPalette.values[paletteIndex.clamp(0, 2)];
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.themeModeKey, mode.index);
    notifyListeners();
  }

  Future<void> setColorPalette(ColorPalette palette) async {
    _colorPalette = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.colorPaletteKey, palette.index);
    notifyListeners();
  }

  // Legacy method for backward compatibility
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.light;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    await setThemeMode(_themeMode);
  }
}


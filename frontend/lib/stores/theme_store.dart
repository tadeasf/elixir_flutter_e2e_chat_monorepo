import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption {
  system,
  light,
  dark,
}

class ThemeStore {
  late final Signal<ThemeModeOption> _themeModeOption;
  late final Signal<ThemeData> theme;
  late final Signal<ThemeData> darkTheme;

  // Define your light and dark themes here
  // Inspired by shadcn/ui slate/zinc
  final _lightThemeData = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue, // Adjust seed color
      brightness: Brightness.light,
      primary: const Color(0xFF2563EB), // slate-700ish
      onPrimary: Colors.white,
      secondary: const Color(0xFF475569), // slate-600
      onSecondary: Colors.white,
      error: const Color(0xFFDC2626), // red-600
      onError: Colors.white,
      surface: const Color(0xFFF8FAFC), // slate-50
      onSurface: const Color(0xFF0F172A), // slate-900
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  final _darkThemeData = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue, // Adjust seed color
      brightness: Brightness.dark,
      primary: const Color(0xFF3B82F6), // slate-500ish
      onPrimary: const Color(0xFFF8FAFC), // slate-50
      secondary: const Color(0xFF94A3B8), // slate-400
      onSecondary: const Color(0xFF0F172A), // slate-900
      error: const Color(0xFFF87171), // red-400
      onError: const Color(0xFF0F172A),
      surface: const Color(0xFF0F172A), // slate-900
      onSurface: const Color(0xFFF1F5F9), // slate-100
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Color(0xFFF1F5F9),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E293B),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      fillColor: const Color(0xFF334155), // slate-700
      filled: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF60A5FA), // slate-400
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  ThemeStore() {
    _themeModeOption = Signal(ThemeModeOption.system);
    theme = Signal(_lightThemeData);
    darkTheme = Signal(_darkThemeData);
    _loadThemePreference();

    // Auto update theme based on option
    Effect((_) {
      final mode = _themeModeOption();
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      bool isDark;
      switch (mode) {
        case ThemeModeOption.light:
          isDark = false;
          break;
        case ThemeModeOption.dark:
          isDark = true;
          break;
        case ThemeModeOption.system:
          isDark = brightness == Brightness.dark;
          break;
      }
      theme.value = isDark ? _darkThemeData : _lightThemeData;
    });
  }

  ThemeMode get currentThemeMode {
    switch (_themeModeOption()) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeModeOption mode) {
    _themeModeOption.value = mode;
    _saveThemePreference(mode);
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex =
          prefs.getInt('themeMode') ?? ThemeModeOption.system.index;
      _themeModeOption.value = ThemeModeOption.values[themeIndex];
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      // Default to system if loading fails
      _themeModeOption.value = ThemeModeOption.system;
    }
  }

  Future<void> _saveThemePreference(ThemeModeOption mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', mode.index);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}

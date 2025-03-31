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

  // Define your light and dark themes here - minimalist white/black for light and black/gray for dark
  final _lightThemeData = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.grey.shade800,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red.shade600,
      onError: Colors.white,
      surfaceContainerHighest: Colors.grey.shade200,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      floatingLabelStyle: const TextStyle(color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.black,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 16,
      ),
    ),
  );

  final _darkThemeData = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.grey.shade400,
      onSecondary: Colors.black,
      surface: Colors.grey.shade900,
      onSurface: Colors.white,
      error: Colors.red.shade400,
      onError: Colors.black,
      surfaceContainerHighest: Colors.grey.shade700,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade900,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.grey.shade900,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white),
      ),
      filled: true,
      fillColor: Colors.grey.shade900,
      labelStyle: TextStyle(color: Colors.grey.shade300),
      floatingLabelStyle: const TextStyle(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.grey.shade900,
      surfaceTintColor: Colors.grey.shade900,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: Colors.grey.shade300,
        fontSize: 16,
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

  ThemeData getDarkTheme() {
    return _darkThemeData;
  }

  ThemeData lightTheme() {
    return _lightThemeData;
  }

  bool isDarkMode() {
    return _themeModeOption() == ThemeModeOption.dark ||
        (_themeModeOption() == ThemeModeOption.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
  }

  void toggleTheme() {
    final currentMode = _themeModeOption();
    if (currentMode == ThemeModeOption.dark) {
      setThemeMode(ThemeModeOption.light);
    } else {
      setThemeMode(ThemeModeOption.dark);
    }
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

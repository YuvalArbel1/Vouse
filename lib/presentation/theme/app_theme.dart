// lib/presentation/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/util/colors.dart';

import '../../core/util/ui_settings.dart';

/// A class that centralizes app theme configuration.
class AppTheme {
  /// Returns the light theme for the app.
  ThemeData get lightTheme {
    return ThemeData(
      // Use primary color from constants
      primaryColor: vPrimaryColor,

      // Use accent color from constants (colorScheme.secondary)
      colorScheme: const ColorScheme.light(
        primary: vPrimaryColor,
        secondary: vAccentColor,
        surface: vAppLayoutBackground,
      ),

      // Configure background color
      scaffoldBackgroundColor: vAppLayoutBackground,

      // Configure app bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),

      // Configure card theme
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Configure elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Configure outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: vPrimaryColor,
          side: const BorderSide(color: vPrimaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Configure text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: vPrimaryColor,
        ),
      ),

      // Configure text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: vPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: vBodyGrey,
        ),
      ),

      // Configure input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: vPrimaryColor.withAlpha(10),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: vPrimaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        hintStyle: TextStyle(color: vBodyGrey.withAlpha(180)),
      ),

      // Configure tabs
      tabBarTheme: const TabBarTheme(
        labelColor: vPrimaryColor,
        unselectedLabelColor: vBodyGrey,
        indicatorColor: vPrimaryColor,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Configure the system UI overlay settings
  void configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Configure for edge-to-edge display
  void configureEdgeToEdge() {
    UiSettings.hideSystemNavBar();
  }
}

/// Provider for the app theme
final appThemeProvider = Provider<AppTheme>((ref) {
  return AppTheme();
});

/// Provider for the current theme data
final themeDataProvider = Provider<ThemeData>((ref) {
  final appTheme = ref.watch(appThemeProvider);
  return appTheme.lightTheme;
});

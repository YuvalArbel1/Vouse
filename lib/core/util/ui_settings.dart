// lib/core/util/ui_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UiSettings {
  /// Apply true edge-to-edge UI that hides system navigation bar
  static void applyEdgeToEdgeUI() {
    // This is the critical setting that was missing
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [],
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // These settings ensure transparency even if nav bar appears
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  /// For screens that need all UI elements hidden (like fullscreen image)
  static void applyFullImmersiveUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Reset to default edge-to-edge
  static void restoreDefaultUI() {
    applyEdgeToEdgeUI();
  }
}
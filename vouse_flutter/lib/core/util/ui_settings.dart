// lib/core/util/ui_settings.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralizes system UI settings for consistent navigation bar and status bar appearance
class UiSettings {
  /// Hide the system navigation bar but keep the status bar
  static void hideSystemNavBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [], // Only show status bar
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Status bar settings
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,

        // Navigation bar settings (these will apply if it ever shows)
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Hide all system UI (for immersive screens like image preview)
  static void hideAllSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Show both system bars (usually not needed in this app)
  static void showAllSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }
}
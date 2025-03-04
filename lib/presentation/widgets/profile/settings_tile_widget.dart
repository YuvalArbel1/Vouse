// lib/presentation/widgets/profile/settings_tile_widget.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A reusable settings tile widget with an icon, title, and chevron.
///
/// Features:
/// - Consistent settings item with icon, label and chevron
/// - Visual feedback with InkWell ripple effect
/// - Customizable icon and colors
/// - Support for loading state
/// - Special styling for destructive actions
class SettingsTileWidget extends StatelessWidget {
  /// The title text for the settings tile
  final String title;

  /// The icon to display
  final IconData icon;

  /// The color for the icon and optional title styling
  final Color iconColor;

  /// Callback when the tile is tapped
  final VoidCallback onTap;

  /// Whether the tile is in a loading state
  final bool isLoading;

  /// Whether this tile is for a destructive action (like disconnect or logout)
  final bool isDestructive;

  /// Creates a [SettingsTileWidget].
  const SettingsTileWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isLoading = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? Colors.red : vBodyGrey,
                ),
              ),
            ),

            // Chevron icon
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

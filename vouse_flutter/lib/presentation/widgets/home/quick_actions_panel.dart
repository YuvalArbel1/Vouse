// lib/presentation/widgets/home/quick_actions_panel.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

import 'action_button.dart';

/// A panel containing quick action buttons.
///
/// Features:
/// - Title and multiple action buttons
/// - Customizable actions and callbacks
/// - Consistent card-like styling
class QuickActionsPanel extends StatelessWidget {
  /// Callback for the new post action
  final VoidCallback onNewPost;

  /// Callback for the schedule action
  final VoidCallback onSchedule;

  /// Callback for the analytics action
  final VoidCallback onPublishhed;

  /// Callback for the settings action
  final VoidCallback onSettings;

  /// Creates a [QuickActionsPanel] widget.
  const QuickActionsPanel({
    super.key,
    required this.onNewPost,
    required this.onSchedule,
    required this.onPublishhed,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: vBodyGrey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ActionButton(
                label: 'New Post',
                icon: Icons.add_circle_outline,
                color: vPrimaryColor,
                onTap: onNewPost,
              ),
              ActionButton(
                label: 'Schedule',
                icon: Icons.schedule,
                color: vAccentColor,
                onTap: onSchedule,
              ),
              ActionButton(
                label: 'Published',
                icon: Icons.history,
                color: Colors.orange,
                onTap: onPublishhed,
              ),
              ActionButton(
                label: 'Profile',
                icon: Icons.person,
                color: vBodyGrey,
                onTap: onSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
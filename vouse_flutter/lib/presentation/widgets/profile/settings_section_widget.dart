// lib/presentation/widgets/profile/settings_section_widget.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A reusable settings section widget with a title and a card of settings items.
///
/// Features:
/// - Section title with consistent styling
/// - Card container for settings items with rounded corners
/// - Clean white background with subtle shadow
/// - Flexible content via children
class SettingsSectionWidget extends StatelessWidget {
  /// The title of the settings section
  final String title;

  /// The list of widgets to display within the settings card
  final List<Widget> children;

  /// Creates a [SettingsSectionWidget].
  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: vPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),

        // Settings card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
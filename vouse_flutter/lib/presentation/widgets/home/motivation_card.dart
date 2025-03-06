// lib/presentation/widgets/home/motivation_card.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A card displaying a motivational tip.
///
/// Features:
/// - Icon with title and message
/// - Customizable tip content
/// - Consistent card-like styling
class MotivationCard extends StatelessWidget {
  /// The tip to display
  final String tip;

  /// Creates a [MotivationCard] widget.
  const MotivationCard({
    super.key,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vPrimaryColor.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vPrimaryColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: vPrimaryColor,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tip of the day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: vPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: TextStyle(
                    fontSize: 14,
                    color: vBodyGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
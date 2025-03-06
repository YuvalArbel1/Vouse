// lib/presentation/widgets/common/filter_chips.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A horizontal scrolling list of filter chips.
///
/// Features:
/// - Horizontal scrolling for many filter options
/// - Visual indication of selected filter
/// - Optional emoji prefix for each filter
/// - Haptic feedback on selection
class FilterChips extends StatelessWidget {
  /// List of filter options
  final List<String> filters;

  /// Currently active filter
  final String activeFilter;

  /// Callback when a filter is selected
  final Function(String) onFilterChanged;

  /// Whether to include emojis for the filters
  final bool useEmojis;

  /// Creates a [FilterChips] widget.
  const FilterChips({
    super.key,
    required this.filters,
    required this.activeFilter,
    required this.onFilterChanged,
    this.useEmojis = true,
  });

  /// Helper to get emoji for each filter
  String _getFilterEmoji(String filter) {
    if (!useEmojis) return '';

    switch (filter) {
      case 'All Time':
        return '🗓️ ';
      case 'This Month':
        return '📅 ';
      case 'This Week':
        return '📆 ';
      case 'Today':
        return '📌 ';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: filters.map((filter) {
            final isActive = filter == activeFilter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add emoji based on filter
                    Text(_getFilterEmoji(filter)),
                    Text(filter),
                  ],
                ),
                selected: isActive,
                onSelected: (selected) {
                  if (selected) {
                    // Add haptic feedback for better user experience
                    HapticFeedback.selectionClick();
                    onFilterChanged(filter);
                  }
                },
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : vBodyGrey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                selectedColor: vPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isActive ? vPrimaryColor : Colors.grey.withAlpha(100),
                  ),
                ),
                elevation: isActive ? 2 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
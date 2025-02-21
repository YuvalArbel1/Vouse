// lib/presentation/widgets/post/location_tag_widget.dart

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';

/// A small UI row for displaying a chosen location, with a remove icon,
/// a red location pin icon, and the address or name in red text.
///
/// Example usage in a parent widget:
///
///   LocationTagWidget(
///     entity: placeLocationEntity,
///     onRemove: () {
///       // Clear provider, etc.
///     },
///   ),
///
class LocationTagWidget extends StatelessWidget {
  /// The location entity containing lat/long, address, name, etc.
  final PlaceLocationEntity entity;

  /// Called when the user taps the "remove" icon to discard the location.
  final VoidCallback onRemove;

  const LocationTagWidget({
    super.key,
    required this.entity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // If entity has a name, use that; otherwise fallback to address or "Unnamed location"
    final displayText = entity.name?.isNotEmpty == true
        ? entity.name
        : (entity.address ?? 'Unnamed location');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1) Remove icon
        GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 2) Location icon in red
        const Icon(Icons.location_on, color: Colors.red),
        const SizedBox(width: 8),

        // 3) Text for address/name, in red
        Expanded(
          child: Text(
            displayText!,
            style: primaryTextStyle(size: 14, color: Colors.red),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

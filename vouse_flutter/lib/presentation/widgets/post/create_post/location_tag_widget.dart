// lib/presentation/widgets/post/create_post/location_tag_widget.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';

/// A visually appealing location tag widget for post creation.
///
/// Features:
/// - Animated remove action
/// - Twitter-like appearance
/// - Customizable styling based on state (selected/readonly)
/// - Clear visual feedback
class LocationTagWidget extends StatefulWidget {
  /// The location entity containing lat/long, address, name, etc.
  final PlaceLocationEntity entity;

  /// Called when the user taps "remove". Only used if [readOnly] = false.
  final VoidCallback? onRemove;

  /// Whether to show the remove icon.
  final bool readOnly;

  /// Creates a [LocationTagWidget].
  const LocationTagWidget({
    super.key,
    required this.entity,
    this.onRemove,
    this.readOnly = false,
  });

  @override
  State<LocationTagWidget> createState() => _LocationTagWidgetState();
}

class _LocationTagWidgetState extends State<LocationTagWidget> with SingleTickerProviderStateMixin {
  // Animation controller for hover effect
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Track hover state
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If entity has a name, use that; otherwise fallback to address or "Unnamed location"
    final displayText = widget.entity.name?.isNotEmpty == true
        ? widget.entity.name
        : (widget.entity.address ?? 'Unnamed location');

    return MouseRegion(
      onEnter: (_) {
        if (!widget.readOnly) {
          setState(() => _isHovering = true);
          _controller.forward();
        }
      },
      onExit: (_) {
        if (!widget.readOnly) {
          setState(() => _isHovering = false);
          _controller.reverse();
        }
      },
      child: GestureDetector(
        onTap: widget.readOnly ? null : widget.onRemove,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.readOnly ? 1.0 : _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(widget.readOnly ? 15 : 25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withAlpha(widget.readOnly ? 50 : 100),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location icon
                const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),

                // Location text
                Flexible(
                  child: Text(
                    displayText!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Remove icon (only if readOnly == false)
                if (!widget.readOnly) ...[
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    opacity: _isHovering ? 1.0 : 0.7,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _isHovering ? Colors.red.withAlpha(50) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// lib/presentation/widgets/post/post_text.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_text_provider.dart';

// NEW: We'll import the location provider & entity
import '../../providers/post/post_location_provider.dart';
import 'location_tag_widget.dart';

class PostText extends ConsumerStatefulWidget {
  const PostText({super.key});

  @override
  ConsumerState<PostText> createState() => _PostTextState();
}

class _PostTextState extends ConsumerState<PostText> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // read the current post text
    final initValue = ref.read(postTextProvider);
    _controller = TextEditingController(text: initValue);

    // Whenever user types, update the provider
    _controller.addListener(() {
      ref.read(postTextProvider.notifier).state = _controller.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1) Watch for external text changes
    final postText = ref.watch(postTextProvider);

    // 2) If text changed externally (like AI insertion), sync controller
    if (postText != _controller.text) {
      _controller.text = postText;
      _controller.selection = TextSelection.collapsed(offset: postText.length);
    }

    // 3) Also watch the postLocationProvider for the chosen location
    final placeLocation = ref.watch(postLocationProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vAppLayoutBackground,
        borderRadius: radius(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The main text field
          TextField(
            controller: _controller,
            autofocus: false,
            maxLines: 15,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'What’s On Your Mind?',
              hintStyle: secondaryTextStyle(size: 12, color: vBodyWhite),
            ),
          ),

          // If location is chosen, show the new widget
          if (placeLocation != null) ...[
            const SizedBox(height: 16),
            LocationTagWidget(
              entity: placeLocation,
              onRemove: () {
                // Reset the location provider
                ref.read(postLocationProvider.notifier).state = null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

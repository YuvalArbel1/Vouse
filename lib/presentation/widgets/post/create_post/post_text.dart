// lib/presentation/widgets/post/post_text.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/util/colors.dart';
import '../../../../core/util/common.dart';
import '../../../providers/post/post_text_provider.dart';
import '../../../providers/post/post_location_provider.dart';
import 'location_tag_widget.dart';

/// A widget that provides an input area for creating or editing a post.
///
/// This widget consists of a text field for the post content and,
/// if a location is selected, displays a location tag below the text field.
///
/// The content is synchronized with [postTextProvider], and the current
/// location is retrieved from [postLocationProvider].
class PostText extends ConsumerStatefulWidget {
  /// Creates a [PostText] widget.
  const PostText({super.key});

  @override
  ConsumerState<PostText> createState() => _PostTextState();
}

class _PostTextState extends ConsumerState<PostText> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the current text from the provider.
    final initValue = ref.read(postTextProvider);
    _controller = TextEditingController(text: initValue);

    // Listen for changes in the text field and update the provider accordingly.
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
    // Watch for external updates to the post text.
    final postText = ref.watch(postTextProvider);

    // If the external text has changed (e.g., due to AI insertion), sync the controller.
    if (postText != _controller.text) {
      _controller.text = postText;
      _controller.selection = TextSelection.collapsed(offset: postText.length);
    }

    // Watch the post location provider for a selected location.
    final placeLocation = ref.watch(postLocationProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: vouseBoxDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main text field for entering post content.
          TextField(
            controller: _controller,
            autofocus: false,
            maxLines: 13,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'What’s On Your Mind?',
              hintStyle: secondaryTextStyle(size: 12, color: vBodyGrey),
            ),
          ),
          // If a location is selected, display the location tag below the text field.
          if (placeLocation != null) ...[
            const SizedBox(height: 8),
            LocationTagWidget(
              entity: placeLocation,
              onRemove: () {
                // Clear the selected location when the remove icon is tapped.
                ref.read(postLocationProvider.notifier).state = null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

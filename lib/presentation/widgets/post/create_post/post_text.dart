// lib/presentation/widgets/post/create_post/post_text.dart

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
/// The content is synchronized with [postTextProvider], and the current
/// location is retrieved from [postLocationProvider].
///
/// Features:
/// - Twitter-like character counter
/// - Attractive placeholder text
/// - Location tag display
/// - Smooth text input experience
class PostText extends ConsumerStatefulWidget {
  /// Creates a [PostText] widget.
  const PostText({super.key});

  @override
  ConsumerState<PostText> createState() => _PostTextState();
}

class _PostTextState extends ConsumerState<PostText> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  // Maximum character count for a post
  final int _maxCharCount = 280;

  // Whether the character counter should be highlighted (approaching limit)
  bool _isNearLimit = false;

  // Whether the character limit has been exceeded
  bool _isOverLimit = false;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the current text from the provider.
    final initValue = ref.read(postTextProvider);
    _controller = TextEditingController(text: initValue);
    _focusNode = FocusNode();

    // Listen for changes in the text field and update the provider accordingly.
    _controller.addListener(() {
      ref.read(postTextProvider.notifier).state = _controller.text;

      // Update the character counter state
      final remainingChars = _maxCharCount - _controller.text.length;
      setState(() {
        _isNearLimit = remainingChars < 40 && remainingChars >= 0;
        _isOverLimit = remainingChars < 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only watch for external changes to post text
    final postText = ref.watch(postTextProvider);

    // Only watch location when needed (place this in a dedicated Consumer widget)
    final hasLocation =
        ref.watch(postLocationProvider.select((loc) => loc != null));

    // Only sync controller if the external text changes
    if (postText != _controller.text) {
      _controller.text = postText;
      _controller.selection = TextSelection.collapsed(offset: postText.length);

      // Update character counter state
      final remainingChars = _maxCharCount - postText.length;
      _isNearLimit = remainingChars < 40 && remainingChars >= 0;
      _isOverLimit = remainingChars < 0;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: vouseBoxDecoration(
            backgroundColor: Colors.white,
            radius: 16,
            shadowOpacity: 15,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main text field for entering post content.
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: false,
                maxLines: 13,
                maxLength: _maxCharCount + 20,
                // Allow some overflow but show warning
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    _buildCharacterCounter(currentLength),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4, // Better line spacing for readability
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _getRandomPlaceholderText(),
                  hintStyle: secondaryTextStyle(
                      size: 16, color: vBodyGrey.withAlpha(180)),
                  helperStyle: TextStyle(color: vPrimaryColor),
                  counterStyle: TextStyle(color: vPrimaryColor),
                ),
              ),

              // If a location is selected, display the location tag below the text field.
              if (hasLocation)
                Consumer(
                  builder: (context, ref, _) {
                    final location = ref.watch(postLocationProvider);
                    return LocationTagWidget(
                      entity: location!,
                      onRemove: () {
                        ref.read(postLocationProvider.notifier).state = null;
                      },
                    );
                  },
                ),
            ],
          ),
        ),

        // Add tip text for better UX
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '💡 Pro tip: Use hashtags to increase your post visibility',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: vBodyGrey.withAlpha(200),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Builds a Twitter-like character counter
  Widget _buildCharacterCounter(int currentLength) {
    final remaining = _maxCharCount - currentLength;

    Color counterColor = vBodyGrey;
    if (_isOverLimit) {
      counterColor = Colors.red;
    } else if (_isNearLimit) {
      counterColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Show circular progress indicator for visual feedback
          if (currentLength > 0) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: currentLength / _maxCharCount,
                strokeWidth: 2,
                backgroundColor: Colors.grey.withAlpha(40),
                color: _isOverLimit
                    ? Colors.red
                    : _isNearLimit
                        ? Colors.orange
                        : vPrimaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Show remaining characters
          Text(
            remaining.toString(),
            style: TextStyle(
              color: counterColor,
              fontWeight: _isNearLimit || _isOverLimit
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a random placeholder text for the post input
  String _getRandomPlaceholderText() {
    final placeholders = [
      "What's happening? 🌎",
      "Share your thoughts... ✨",
      "Start a conversation... 💬",
      "Write something inspiring... 💫",
      "What's on your mind today? 🤔",
      "Share your story... 📝",
      "Post an update for your followers... 👋",
      "Express yourself here... 🎭",
    ];

    // Use the current second to pick a random placeholder
    final index = DateTime.now().second % placeholders.length;
    return placeholders[index];
  }
}

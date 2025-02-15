// lib/presentation/widgets/post/post_text.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_text_provider.dart';

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
    // Watch for external changes (like AI Insert)
    final postText = ref.watch(postTextProvider);

    // If text changed externally, sync controller
    if (postText != _controller.text) {
      _controller.text = postText;
      _controller.selection =
          TextSelection.collapsed(offset: postText.length);
    }

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
      child: TextField(
        controller: _controller,
        autofocus: false,
        maxLines: 15,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'What’s On Your Mind?',
          hintStyle: secondaryTextStyle(size: 12, color: vBodyWhite),
        ),
      ),
    );
  }
}

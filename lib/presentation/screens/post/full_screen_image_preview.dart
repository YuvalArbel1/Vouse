import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_images_provider.dart';

/// A full-screen page that:
/// - Hides system UI in [initState], restores in [dispose].
/// - Reads images from postImagesProvider in real-time.
/// - "Close" icon => pop just this screen, returning to CreatePostScreen.
/// - "Delete" => remove only the current image from the provider.
///   * If that leaves no images => pop just this screen.
///   * If multiple remain and we're on last index => cycle to 0.
///   * Otherwise stay at same index => next image slides in.
class FullScreenImagePreview extends ConsumerStatefulWidget {
  final int initialIndex;

  const FullScreenImagePreview({
    super.key,
    required this.initialIndex,
  });

  @override
  ConsumerState<FullScreenImagePreview> createState()
  => _FullScreenImagePreviewState();
}

class _FullScreenImagePreviewState
    extends ConsumerState<FullScreenImagePreview> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    // Hide status/nav bars
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {

    super.dispose();
  }

  /// Removes the current image.
  /// If none remain => pop just this FullScreen route, revealing Create Post below.
  /// If we were on last index => cycle to 0.
  /// Otherwise remain at same index => new image slides in from old next.
  void _deleteCurrentImage() {
    final images = ref.read(postImagesProvider);
    if (images.isEmpty) return; // no-op if already empty

    final pathToRemove = images[_currentIndex];
    ref.read(postImagesProvider.notifier).removeImage(pathToRemove);

    final updated = ref.read(postImagesProvider);
    if (updated.isEmpty) {
      // No images left => pop just this route
      Navigator.pop(context);
    } else {
      setState(() {
        if (_currentIndex >= updated.length) {
          // if we were at the last item
          _currentIndex = 0; // cycle to first
        }
        _pageController.jumpToPage(_currentIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(postImagesProvider);

    // If currentIndex >= new length => jump to 0
    if (_currentIndex >= images.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentIndex = 0;
        _pageController.jumpToPage(_currentIndex);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context), // closes ONLY the top route
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkResponse(
              onTap: _deleteCurrentImage,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: vPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemBuilder: (ctx, index) {
          final path = images[index];
          return InteractiveViewer(
            child: Center(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}

// lib/presentation/screens/post/full_screen_image_preview.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_images_provider.dart';

/// A full-screen page that:
/// - Hides system UI overlays in [initState], restores them in [dispose].
/// - Reads images from [postImagesProvider].
/// - Has a "Close" icon to pop back to [CreatePostScreen].
/// - Has a "Delete" icon to remove only the current image from the provider.
///   * If that leaves no images => pop just this route.
///   * If multiple remain and we were on last index => cycle to index 0.
///   * Otherwise, remain at the same index => next image slides into place.
class FullScreenImagePreview extends ConsumerStatefulWidget {
  /// The initial page index in the [PageView].
  final int initialIndex;

  const FullScreenImagePreview({
    super.key,
    required this.initialIndex,
  });

  @override
  ConsumerState<FullScreenImagePreview> createState() =>
      _FullScreenImagePreviewState();
}

class _FullScreenImagePreviewState
    extends ConsumerState<FullScreenImagePreview> {
  /// Controls which page is displayed in the [PageView].
  late final PageController _pageController;

  /// Tracks the currently displayed image index.
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    // Hide status/nav bars for a fully immersive preview.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    // Restore default system overlays when leaving this screen.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  /// Removes the currently displayed image path from the provider.
  /// - If none remain, pop this screen.
  /// - If we were on the last index, jump to 0.
  /// - Otherwise, remain at the same index so the next image slides in.
  void _deleteCurrentImage() {
    final images = ref.read(postImagesProvider);
    if (images.isEmpty) return; // No-op if there's nothing to remove.

    final pathToRemove = images[_currentIndex];
    ref.read(postImagesProvider.notifier).removeImage(pathToRemove);

    final updated = ref.read(postImagesProvider);
    if (updated.isEmpty) {
      // No images left => close the preview entirely.
      Navigator.pop(context);
    } else {
      setState(() {
        // If we were on the last item, cycle to 0.
        if (_currentIndex >= updated.length) {
          _currentIndex = 0;
        }
        _pageController.jumpToPage(_currentIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(postImagesProvider);

    // If our currentIndex is now out of range, jump to 0 in the next frame.
    if (_currentIndex >= images.length && images.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = 0;
          _pageController.jumpToPage(_currentIndex);
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,

      /// A semi-transparent AppBar with close & delete icons.
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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

      /// The PageView builder that displays one image per page.
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

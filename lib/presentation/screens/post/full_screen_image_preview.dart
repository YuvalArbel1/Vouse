// lib/presentation/screens/post/full_screen_image_preview.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_images_provider.dart';

/// A full-screen viewer for images, which can operate in two modes:
///
/// 1) **Default / Provider Mode** (useDirectList = false):
///    - Reads from [postImagesProvider].
///    - Allows deleting from provider state (if allowDeletion = true).
///
/// 2) **Direct List Mode** (useDirectList = true):
///    - Uses [directImages] for display.
///    - Typically hides deletion logic or handle your own approach.
///
class FullScreenImagePreview extends ConsumerStatefulWidget {
  /// The initial page index to display.
  final int initialIndex;

  /// If true, we ignore the provider and use [directImages] instead.
  final bool useDirectList;

  /// A direct list of image paths if [useDirectList] is true.
  /// Otherwise, can be null.
  final List<String>? directImages;

  /// Whether or not to show a delete icon (or do delete logic).
  /// In provider mode, this removes from the provider.
  /// In direct list mode, we remove from [directImages] in memory.
  final bool allowDeletion;

  const FullScreenImagePreview({
    super.key,
    required this.initialIndex,
    this.useDirectList = false,
    this.directImages,
    this.allowDeletion = false,
  });

  @override
  ConsumerState<FullScreenImagePreview> createState() =>
      _FullScreenImagePreviewState();
}

class _FullScreenImagePreviewState
    extends ConsumerState<FullScreenImagePreview> {
  late PageController _pageController;
  late int _currentIndex;

  /// If we’re in direct-list mode, we store images in a local list (mutable).
  List<String> _localImages = [];

  @override
  void initState() {
    super.initState();

    // Hide status/nav bars for a fully immersive preview
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    if (widget.useDirectList) {
      // Copy the directImages into a local list so we can do removals easily
      _localImages = List<String>.from(widget.directImages ?? []);
    }
  }

  @override
  void dispose() {
    if (widget.useDirectList) {
      // Clear the local images list
      _localImages.clear();
    }

    super.dispose();
  }

  /// Called if user taps the delete icon.
  /// Removes the currently displayed image from either the provider or the local list.
  void _handleDelete(List<String> images) {
    if (images.isEmpty) return;

    final pathToRemove = images[_currentIndex];

    if (widget.useDirectList) {
      // Remove from our local images list
      setState(() {
        _localImages.removeAt(_currentIndex);
      });
      if (_localImages.isEmpty) {
        Navigator.pop(context);
      } else {
        if (_currentIndex >= _localImages.length) {
          _currentIndex = _localImages.length - 1;
        }
        _pageController.jumpToPage(_currentIndex);
      }
    } else {
      // Remove from the provider-based list
      ref.read(postImagesProvider.notifier).removeImage(pathToRemove);

      final updated = ref.read(postImagesProvider);
      if (updated.isEmpty) {
        Navigator.pop(context);
      } else {
        if (_currentIndex >= updated.length) {
          _currentIndex = updated.length - 1;
        }
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decide which images we’re actually showing
    final images =
        widget.useDirectList ? _localImages : ref.watch(postImagesProvider);

    // If our currentIndex is out of range, jump to 0
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
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.allowDeletion)
            // Circular container tinted by vPrimaryColor with alpha=200,
            // and the icon tinted by vAccentColor with alpha=220
            InkResponse(
              onTap: () => _handleDelete(images),
              customBorder: const CircleBorder(),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: vPrimaryColor.withAlpha(150),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete,
                  color: vAccentColor.withAlpha(150),
                ),
              ),
            )
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
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

// lib/presentation/providers/post/post_images_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A [StateNotifier] that manages a list of image paths the user selected for a post.
///
/// Restricts the maximum number of images to 4.
class PostImagesNotifier extends StateNotifier<List<String>> {
  /// Initializes with an empty list of images.
  PostImagesNotifier() : super([]);

  /// Adds [path] if the current list has fewer than 4 images.
  void addImage(String path) {
    if (state.length >= 4) return;
    state = [...state, path];
  }

  /// Removes the specified [path] from [state] if it exists.
  void removeImage(String path) {
    state = state.where((p) => p != path).toList();
  }

  /// Clears all selected images.
  void clearAll() {
    state = [];
  }
}

/// Exposes a [PostImagesNotifier] so widgets can observe or modify the current list of selected images.
///
/// Usage in a widget:
/// ```dart
/// final images = ref.watch(postImagesProvider);
/// ```
final postImagesProvider =
    StateNotifierProvider<PostImagesNotifier, List<String>>((ref) {
  return PostImagesNotifier();
});

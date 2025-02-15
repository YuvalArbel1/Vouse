import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple notifier holding 0-4 image paths the user selected.
class PostImagesNotifier extends StateNotifier<List<String>> {
  PostImagesNotifier() : super([]);

  /// Add image if < 4
  void addImage(String path) {
    if (state.length >= 4) return;
    state = [...state, path];
  }

  /// Remove a specific image
  void removeImage(String path) {
    state = state.where((p) => p != path).toList();
  }

  /// Clear them all
  void clearAll() {
    state = [];
  }
}

/// The provider that UI widgets watch for the selected images
final postImagesProvider =
StateNotifierProvider<PostImagesNotifier, List<String>>((ref) {
  return PostImagesNotifier();
});

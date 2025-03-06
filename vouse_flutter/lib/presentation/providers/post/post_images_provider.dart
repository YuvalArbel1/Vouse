// lib/presentation/providers/post/post_images_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';

/// Describes the outcome of adding an image to [PostImagesNotifier].
enum AddImageResult {
  /// The image was successfully added.
  success,
  /// The image was a duplicate (MD5 matched a previously added image).
  duplicate,
  /// The post already had 4 images, so we couldn't add more.
  maxReached,
}

/// A [StateNotifier] that stores ephemeral file paths in [state]
/// and uses MD5-based deduplication to catch the same actual photo
/// even with different ephemeral paths (e.g. recent vs. gallery).
class PostImagesNotifier extends StateNotifier<List<String>> {
  /// A map from ephemeral path -> MD5, so we can remove the correct hash when removing.
  final Map<String, String> _pathToMd5 = {};

  /// A set of known MD5s, used for quick duplicate checks.
  final Set<String> _hashSet = {};

  /// The maximum number of images allowed in a post.
  static const int maxImages = 4;

  PostImagesNotifier() : super([]);

  // ------------------------------------------------------------------------
  // Public methods for adding from different flows
  // ------------------------------------------------------------------------

  /// Attempts to add [ephemeralPath] from the “recent images” row.
  /// Returns [AddImageResult], letting the UI decide whether to show a toast or remove an image.
  Future<AddImageResult> addImageFromRecent(String ephemeralPath) async {
    if (state.length >= maxImages) return AddImageResult.maxReached;

    final md5Str = await _computeMd5(ephemeralPath);
    if (_hashSet.contains(md5Str)) return AddImageResult.duplicate;

    _hashSet.add(md5Str);
    _pathToMd5[ephemeralPath] = md5Str;
    state = [...state, ephemeralPath];

    return AddImageResult.success;
  }

  /// Attempts to add [ephemeralPath] from the system gallery,
  /// also returning an [AddImageResult].
  Future<AddImageResult> addImageFromGallery(String ephemeralPath) async {
    if (state.length >= maxImages) return AddImageResult.maxReached;

    final md5Str = await _computeMd5(ephemeralPath);
    if (_hashSet.contains(md5Str)) return AddImageResult.duplicate;

    _hashSet.add(md5Str);
    _pathToMd5[ephemeralPath] = md5Str;
    state = [...state, ephemeralPath];

    return AddImageResult.success;
  }

  /// Removes an [ephemeralPath] from both [state] and the MD5 sets.
  void removeImage(String ephemeralPath) {
    if (!state.contains(ephemeralPath)) return;

    // Remove path from state
    state = state.where((p) => p != ephemeralPath).toList();

    // Remove the associated MD5 from sets
    final hash = _pathToMd5.remove(ephemeralPath);
    if (hash != null) _hashSet.remove(hash);
  }

  /// Clears everything.
  void clearAll() {
    state = [];
    _pathToMd5.clear();
    _hashSet.clear();
  }

  // ------------------------------------------------------------------------
  // Private helper: compute MD5 from a file
  // ------------------------------------------------------------------------
  Future<String> _computeMd5(String filePath) async {
    final fileBytes = await File(filePath).readAsBytes();
    final digest = md5.convert(fileBytes);
    return digest.toString();
  }
}

/// Exposes a [PostImagesNotifier] so widgets can handle ephemeral paths
/// with MD5-based duplicates. The UI can show toasts based on [AddImageResult].
final postImagesProvider =
StateNotifierProvider<PostImagesNotifier, List<String>>((ref) {
  return PostImagesNotifier();
});

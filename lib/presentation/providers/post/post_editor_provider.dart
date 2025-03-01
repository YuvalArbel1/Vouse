// lib/presentation/providers/post/post_editor_provider.dart
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';
import 'package:vouse_flutter/presentation/providers/post/post_images_provider.dart';

// State class for post editor
class PostEditorState {
  final String text;
  final List<String> imagePaths;
  final PlaceLocationEntity? location;
  final bool hasUnsavedChanges;

  PostEditorState({
    this.text = '',
    this.imagePaths = const [],
    this.location,
    this.hasUnsavedChanges = false,
  });

  bool get hasContent => text.isNotEmpty || imagePaths.isNotEmpty || location != null;

  PostEditorState copyWith({
    String? text,
    List<String>? imagePaths,
    PlaceLocationEntity? location,
    bool? hasUnsavedChanges,
    bool clearLocation = false,
  }) {
    return PostEditorState(
      text: text ?? this.text,
      imagePaths: imagePaths ?? this.imagePaths,
      location: clearLocation ? null : (location ?? this.location),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

// Notifier to manage post editing state
class PostEditorNotifier extends StateNotifier<PostEditorState> {
  final Ref _ref;
  final Set<String> _hashSet = {};
  final Map<String, String> _pathToMd5 = {};
  static const int maxImages = 4;

  PostEditorNotifier(this._ref) : super(PostEditorState());

  // Text methods
  void setText(String text) {
    if (text != state.text) {
      state = state.copyWith(text: text, hasUnsavedChanges: true);
    }
  }

  // Location methods
  void setLocation(PlaceLocationEntity location) {
    state = state.copyWith(location: location, hasUnsavedChanges: true);
  }

  void clearLocation() {
    state = state.copyWith(clearLocation: true, hasUnsavedChanges: true);
  }

  // Image methods
  Future<AddImageResult> addImage(String path) async {
    if (state.imagePaths.length >= maxImages) return AddImageResult.maxReached;

    final md5Str = await _computeMd5(path);
    if (_hashSet.contains(md5Str)) return AddImageResult.duplicate;

    _hashSet.add(md5Str);
    _pathToMd5[path] = md5Str;
    state = state.copyWith(
        imagePaths: [...state.imagePaths, path],
        hasUnsavedChanges: true
    );

    return AddImageResult.success;
  }

  void removeImage(String path) {
    if (!state.imagePaths.contains(path)) return;

    final hash = _pathToMd5.remove(path);
    if (hash != null) _hashSet.remove(hash);

    state = state.copyWith(
        imagePaths: state.imagePaths.where((p) => p != path).toList(),
        hasUnsavedChanges: true
    );
  }

  void clearAll() {
    _hashSet.clear();
    _pathToMd5.clear();
    state = PostEditorState();
  }

  // Private helper methods
  Future<String> _computeMd5(String filePath) async {
    final fileBytes = await File(filePath).readAsBytes();
    final digest = md5.convert(fileBytes);
    return digest.toString();
  }
}

// Main provider
final postEditorProvider = StateNotifierProvider<PostEditorNotifier, PostEditorState>((ref) {
  return PostEditorNotifier(ref);
});

// Legacy providers that delegate to the main provider for backward compatibility
final postTextProvider = Provider<String>((ref) {
  return ref.watch(postEditorProvider).text;
});

final postImagesProvider = Provider<List<String>>((ref) {
  return ref.watch(postEditorProvider).imagePaths;
});

final postLocationProvider = Provider<PlaceLocationEntity?>((ref) {
  return ref.watch(postEditorProvider).location;
});
// lib/presentation/widgets/post/recent_images_row.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../../core/util/colors.dart';
import '../../../providers/post/post_images_provider.dart';

/// A widget that displays:
/// - A camera icon
/// - Up to 4 recent images from the device
/// The user can tap:
///   - if not selected => try to add (with MD5 check),
///   - if selected => remove it (green border gone).
class RecentImagesRow extends ConsumerStatefulWidget {
  const RecentImagesRow({super.key});

  @override
  ConsumerState<RecentImagesRow> createState() => _RecentImagesRowState();
}

class _RecentImagesRowState extends ConsumerState<RecentImagesRow> {
  final ImagePicker _picker = ImagePicker();
  List<File> _recentImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndFetchImages();
    });
  }

  Future<void> _initPermissionsAndFetchImages() async {
    final statusCamera = await Permission.camera.request();
    final statusPhotos = await Permission.photos.request();

    if (statusCamera.isDenied || statusPhotos.isDenied) {
      toast("Need camera & photos permission to access images");
      return;
    }
    await _fetchLast4Images();
  }

  Future<void> _fetchLast4Images() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    if (albums.isEmpty) return;

    final mainAlbum = albums.first;
    final assets = await mainAlbum.getAssetListPaged(page: 0, size: 4);

    final files = <File>[];
    for (final asset in assets) {
      final file = await asset.file;
      if (file != null) files.add(file);
    }

    setState(() => _recentImages = files);
  }

  Future<void> _captureNewImage() async {
    final statusCamera = await Permission.camera.request();
    if (statusCamera.isDenied) {
      toast("Camera permission denied");
      return;
    }
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    _onImageTapped(picked.path);
  }

  /// Called when user taps a "recent" image or camera result.
  /// If it's already selected => remove.
  /// If it's new => add it and interpret the [AddImageResult].
  Future<void> _onImageTapped(String ephemeralPath) async {
    final images = ref.read(postImagesProvider);

    // If already selected => remove
    if (images.contains(ephemeralPath)) {
      ref.read(postImagesProvider.notifier).removeImage(ephemeralPath);
      return;
    }

    // Otherwise attempt to add
    final notifier = ref.read(postImagesProvider.notifier);
    final result = await notifier.addImageFromRecent(ephemeralPath);

    // Show toast based on result
    switch (result) {
      case AddImageResult.duplicate:
        toast("You've already selected this image!");
        break;
      case AddImageResult.maxReached:
        toast("You can't add more than 4 images");
        break;
      case AddImageResult.success:
        // no toast needed, but you can if you want
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagesInPost = ref.watch(postImagesProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildIconContainer(
          child: const Icon(Icons.camera_alt),
          onTap: _captureNewImage,
        ),
        ..._recentImages.map((file) {
          final path = file.path;
          final alreadySelected = imagesInPost.contains(path);
          return _buildIconContainer(
            child: _buildImageThumbnail(file, alreadySelected),
            onTap: () => _onImageTapped(path),
            isSelected: alreadySelected,
          );
        }),
      ],
    );
  }

  /// Container for each item (camera or thumbnail), with optional green border
  Widget _buildIconContainer({
    required Widget child,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 62,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: vAccentColor, width: 1) : null,
        ),
        child: child,
      ),
    );
  }

  /// Adds a partial overlay if selected, plus a green check
  Widget _buildImageThumbnail(File file, bool alreadySelected) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        if (alreadySelected)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(76),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        if (alreadySelected)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: vAccentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

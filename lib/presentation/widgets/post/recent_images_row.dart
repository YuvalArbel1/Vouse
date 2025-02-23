// lib/presentation/widgets/post/recent_images_row.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_images_provider.dart';

/// A row with exactly 2 icons + up to 4 images, all evenly spaced:
///   [ AI icon | Camera icon | (0..4) images ]
/// There's no scroll view, because we only display at most 6 items.
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
    // Request permission & fetch images after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndFetchImages();
    });
  }

  /// Requests camera/photos permission, if granted fetch last 4 images
  Future<void> _initPermissionsAndFetchImages() async {
    final statusCamera = await Permission.camera.request();
    final statusPhotos = await Permission.photos.request();

    if (statusCamera.isDenied || statusPhotos.isDenied) {
      toast("Need camera & photos permission to access images");
      return;
    }

    await _fetchLast4Images();
  }

  /// Query device's album for up to 4 images
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
      if (file != null) {
        files.add(file);
      }
    }

    setState(() => _recentImages = files);
  }

  /// Add image path to postImagesProvider if <4 images
  void _attemptAddImage(String path) {
    final currentImages = ref.read(postImagesProvider);
    if (currentImages.length >= 4) {
      toast("You can't add more than 4 images");
    } else {
      ref.read(postImagesProvider.notifier).addImage(path);
    }
  }

  /// Launch camera & add
  Future<void> _captureNewImage() async {
    final statusCamera = await Permission.camera.request();
    if (statusCamera.isDenied) {
      toast("Camera permission denied");
      return;
    }

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    _attemptAddImage(pickedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    // We'll display at most 6 items: [AI icon, Camera icon, up to 4 images]
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 2) Camera Icon
        buildItemContainer(
          child: Icon(Icons.camera_alt, color: vPrimaryColor),
          onTap: _captureNewImage,
        ),
        // 3) Up to 4 images
        ..._recentImages.map((file) {
          return buildItemContainer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(file, fit: BoxFit.cover),
            ),
            onTap: () => _attemptAddImage(file.path),
          );
        }),

      ],
    );
  }

  /// A helper that returns a 52×62 container for icons or images
  Widget buildItemContainer({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 62,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}

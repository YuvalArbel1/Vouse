// lib/presentation/widgets/post/recent_images_row.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import '../../providers/post/post_images_provider.dart';

/// A widget that displays a row containing two fixed icons and up to four recent images.
///
/// The row is composed of:
/// - A camera icon that launches the camera to capture a new image.
/// - Up to 4 recent images retrieved from the device's photo library.
///
/// Tapping an image or icon attempts to add that image's path to the post (if fewer than 4 images are selected).
class RecentImagesRow extends ConsumerStatefulWidget {
  /// Creates a [RecentImagesRow] widget.
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
    // Request necessary permissions and fetch recent images after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndFetchImages();
    });
  }

  /// Requests camera and photos permissions.
  ///
  /// If permissions are granted, it fetches the last 4 images from the device.
  Future<void> _initPermissionsAndFetchImages() async {
    final statusCamera = await Permission.camera.request();
    final statusPhotos = await Permission.photos.request();

    if (statusCamera.isDenied || statusPhotos.isDenied) {
      toast("Need camera & photos permission to access images");
      return;
    }

    await _fetchLast4Images();
  }

  /// Retrieves up to 4 recent image files from the device's photo library.
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

  /// Attempts to add the image at [path] to the post.
  ///
  /// If there are already 4 images selected, a toast is displayed.
  void _attemptAddImage(String path) {
    final currentImages = ref.read(postImagesProvider);
    if (currentImages.length >= 4) {
      toast("You can't add more than 4 images");
    } else {
      ref.read(postImagesProvider.notifier).addImage(path);
    }
  }

  /// Captures a new image using the device camera and adds it to the post.
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
    // Display up to 6 items: a camera icon plus up to 4 images.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Camera icon.
        buildItemContainer(
          child: Icon(Icons.camera_alt, color: vPrimaryColor),
          onTap: _captureNewImage,
        ),
        // Map over recent images.
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

  /// A helper method that returns a container with fixed dimensions and styling.
  ///
  /// Uses the common [vouseBoxDecoration] with a zero shadow opacity (i.e. no shadow)
  /// and a border radius of 8, preserving the UI look while leveraging shared styles.
  Widget buildItemContainer({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 62,
        decoration: vouseBoxDecoration(
          radius: 8,
          backgroundColor: context.cardColor,
          shadowOpacity: 0, // No shadow for these items.
        ),
        child: child,
      ),
    );
  }
}

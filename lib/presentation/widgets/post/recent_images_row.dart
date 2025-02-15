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

/// Shows a camera icon + last 4 gallery images horizontally.
/// Tapping any image or the camera icon tries to add it to postImagesProvider.
/// If we already have 4, we show a toast and do not add more.
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
    // Ask permissions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndFetchImages();
    });
  }

  /// Request camera + gallery permission. If granted, fetch last 4 images.
  Future<void> _initPermissionsAndFetchImages() async {
    final statusCamera = await Permission.camera.request();
    final statusPhotos = await Permission.photos.request();

    if (statusCamera.isDenied || statusPhotos.isDenied) {
      toast("Need camera & photos permission to access images");
      return;
    }

    await _fetchLast4Images();
  }

  /// Query device's main album for up to 4 recent images
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

  /// Attempt to add a path to the postImagesProvider if <4. Otherwise toast.
  void _attemptAddImage(String path) {
    final currentImages = ref.read(postImagesProvider);
    if (currentImages.length >= 4) {
      toast("You can't add more than 4 images");
    } else {
      ref.read(postImagesProvider.notifier).addImage(path);
    }
  }

  /// Launch camera, add result to provider if any
  Future<void> _captureNewImage() async {
    final statusCamera = await Permission.camera.request();
    if (statusCamera.isDenied) {
      toast("Camera permission denied");
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    _attemptAddImage(pickedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Camera icon
          GestureDetector(
            onTap: _captureNewImage,
            child: Container(
              width: 52,
              height: 62,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.camera_alt, color: vPrimaryColor),
            ),
          ),

          // The last 4 images from device
          ..._recentImages.map((file) {
            return GestureDetector(
              onTap: () => _attemptAddImage(file.path),
              child: Container(
                width: 52,
                height: 62,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(file, fit: BoxFit.cover),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

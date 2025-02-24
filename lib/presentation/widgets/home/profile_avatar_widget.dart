import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/util/colors.dart';

/// A reusable widget displaying a circle avatar that, when tapped,
/// lets the user pick an image from camera or gallery. Returns the
/// chosen file path through [onAvatarChanged].
class ProfileAvatarWidget extends StatefulWidget {
  /// The current avatar file path (if any). If null, shows a default icon.
  final String? initialAvatarPath;

  /// Called whenever the user picks a new image, passing the new file path.
  final ValueChanged<String?> onAvatarChanged;

  /// The size of the avatar circle. Defaults to 110.
  final double size;

  const ProfileAvatarWidget({
    super.key,
    required this.onAvatarChanged,
    this.initialAvatarPath,
    this.size = 110,
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  String? _localAvatarPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Start with whatever parent passed in as the current avatar.
    _localAvatarPath = widget.initialAvatarPath;
  }

  /// Asks for camera/gallery permission (if needed), then shows a bottom sheet
  /// to let the user choose between camera or gallery.
  ///
  /// Checks [mounted] before calling [showModalBottomSheet].
  Future<void> _pickProfileImage() async {
    // 1) Request camera & gallery permissions.
    final statusCamera = await Permission.camera.request();
    final statusPhotos = await Permission.photos.request();
    // (Or Permission.storage on Android, depending on your use case.)

    if (!mounted) return;

    if (statusCamera.isDenied || statusPhotos.isDenied) {
      toast("Need camera & photos permission to set profile image");
      return;
    }

    // 2) Show the bottom sheet to pick camera or gallery.
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a photo"),
                onTap: () async {
                  Navigator.pop(sheetCtx); // Close bottom sheet immediately.
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  // Check if still mounted before updating UI.
                  if (!mounted) return;
                  if (pickedFile != null) {
                    final savedPath = await _saveToPermanentFolder(pickedFile);
                    if (!mounted) return;
                    setState(() => _localAvatarPath = savedPath);
                    widget.onAvatarChanged(savedPath);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Choose from gallery"),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (!mounted) return;
                  if (pickedFile != null) {
                    final savedPath = await _saveToPermanentFolder(pickedFile);
                    if (!mounted) return;
                    setState(() => _localAvatarPath = savedPath);
                    widget.onAvatarChanged(savedPath);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Copies the picked file from a temp/cache directory to a stable app directory.
  Future<String> _saveToPermanentFolder(XFile pickedFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dirPath = docsDir.path;
    final fileName = p.basename(pickedFile.path);
    final newPath = p.join(dirPath, fileName);
    final newFile = await File(pickedFile.path).copy(newPath);
    return newFile.path;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          // The circle background with either an image or a default icon.
          Container(
            margin: const EdgeInsets.only(right: 8),
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              color: vPrimaryColor, // fallback color if no image
              shape: BoxShape.circle,
              image: _localAvatarPath == null
                  ? null
                  : DecorationImage(
                image: FileImage(File(_localAvatarPath!)),
                fit: BoxFit.cover,
              ),
            ),
            child: _localAvatarPath == null
                ? const Icon(Icons.person, color: Colors.white, size: 60)
                : null,
          ),

          // The small edit icon
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.green, // or vAccentColor if you prefer
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

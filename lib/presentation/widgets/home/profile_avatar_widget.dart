import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/util/colors.dart'; // For style or toast if needed

/// A reusable widget displaying a circle avatar that, when tapped,
/// lets the user pick an image from camera or gallery. Returns the
/// chosen file path through [onAvatarChanged].
class ProfileAvatarWidget extends StatefulWidget {
  /// The current avatar file path (if any). If null, we show a default icon.
  final String? initialAvatarPath;

  /// Called whenever the user picks a new image, passing the new file path.
  final ValueChanged<String?> onAvatarChanged;

  /// The size of the circle. Defaults to 110.
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
    // Start with whatever parent passed in as the current avatar
    _localAvatarPath = widget.initialAvatarPath;
  }

  /// Show a bottom sheet letting the user pick camera or gallery.
  Future<void> _pickProfileImage() async {
    // 1) Ask for camera & gallery permission if needed
    final statusCamera = await Permission.camera.request();
    final statusPhotos = await Permission.photos.request();
    // or Permission.storage on Android

    if (statusCamera.isDenied || statusPhotos.isDenied) {
      // You can show a dialog or toast
      toast("Need camera & photos permission to set profile image");
      return;
    }
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
                  Navigator.pop(sheetCtx); // close bottom sheet
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (pickedFile != null) {
                    final savedPath = await _saveToPermanentFolder(pickedFile);
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
                  if (pickedFile != null) {
                    final savedPath = await _saveToPermanentFolder(pickedFile);
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

  /// Copy the picked file from temp/cache to a stable app directory
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
          // The circle background with either an image or default icon
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

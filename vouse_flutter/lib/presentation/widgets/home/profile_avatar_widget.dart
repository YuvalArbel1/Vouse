// lib/presentation/widgets/home/profile_avatar_widget.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// Whether this is part of a hero animation
  final bool useHero;

  /// Hero tag to use for animation
  final String heroTag;

  const ProfileAvatarWidget({
    super.key,
    required this.onAvatarChanged,
    this.initialAvatarPath,
    this.size = 110,
    this.useHero = false,
    this.heroTag = 'profile-avatar',
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  String? _localAvatarPath;
  bool _fileExists = false;
  final ImagePicker _picker = ImagePicker();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Set initial path immediately to avoid flickering
    _localAvatarPath = widget.initialAvatarPath;
    _initializeAvatar();
  }

  @override
  void didUpdateWidget(ProfileAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If initialAvatarPath changes (e.g., from parent widget)
    if (oldWidget.initialAvatarPath != widget.initialAvatarPath) {
      _localAvatarPath = widget.initialAvatarPath;
      _initializeAvatar();
    }
  }

  /// Initialize the avatar by validating the file exists
  Future<void> _initializeAvatar() async {
    if (widget.initialAvatarPath != null) {
      try {
        final file = File(widget.initialAvatarPath!);
        final exists = await file.exists();

        // Only update if mounted to avoid setState on unmounted widget
        if (mounted) {
          setState(() {
            _localAvatarPath = widget.initialAvatarPath;
            _fileExists = exists;
            _isInitialized = true;
          });
        }

        if (!exists) {
          if (kDebugMode) {
            print('Avatar file does not exist at path: ${widget.initialAvatarPath}');
          }
        } else {
          if (kDebugMode) {
            print('Avatar file exists at path: ${widget.initialAvatarPath}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error checking avatar file: $e');
        }
        if (mounted) {
          setState(() {
            _fileExists = false;
            _isInitialized = true;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  /// Asks for camera/gallery permission (if needed), then shows a bottom sheet
  /// to let the user choose between camera or gallery.
  Future<void> _pickProfileImage() async {
    // 1) Request camera & gallery permissions.
    final statusCamera = await Permission.camera.request();
    final statusPhotos = await Permission.photos.request();

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
                  if (!mounted) return;
                  if (pickedFile != null) {
                    _processNewImage(pickedFile);
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
                    _processNewImage(pickedFile);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Process a newly selected image - delete old image if it exists,
  /// save the new one to a permanent location, and update state
  Future<void> _processNewImage(XFile newImage) async {
    try {
      // 1. Delete old image file if it exists
      if (_fileExists && _localAvatarPath != null) {
        try {
          final oldFile = File(_localAvatarPath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
            if (kDebugMode) {
              print('Deleted old avatar at: $_localAvatarPath');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error deleting old avatar: $e');
          }
        }
      }

      // 2. Save the new image
      final savedPath = await _saveToPermanentFolder(newImage);

      // 3. Update state and notify parent
      if (mounted) {
        setState(() {
          _localAvatarPath = savedPath;
          _fileExists = true;
        });
        widget.onAvatarChanged(savedPath);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing new image: $e');
      }
      toast("Failed to update profile image: $e");
    }
  }

  /// Copies the picked file from a temp/cache directory to a stable app directory.
  Future<String> _saveToPermanentFolder(XFile pickedFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dirPath = docsDir.path;

    // Generate a unique filename based on timestamp
    final fileExt = p.extension(pickedFile.path);
    final uniqueFileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}$fileExt';

    final newPath = p.join(dirPath, uniqueFileName);
    final newFile = await File(pickedFile.path).copy(newPath);

    if (kDebugMode) {
      print('Saved new avatar to: ${newFile.path}');
    }
    return newFile.path;
  }

  @override
  Widget build(BuildContext context) {
    // Build the avatar container with image or icon
    Widget avatarContainer = Container(
      margin: const EdgeInsets.only(right: 8),
      height: widget.size,
      width: widget.size,
      decoration: BoxDecoration(
        color: vPrimaryColor.withAlpha(26), // fallback color if no image
        shape: BoxShape.circle,
        border: Border.all(color: vPrimaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: vPrimaryColor.withAlpha(40),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
        image: (_localAvatarPath != null && (_fileExists || !_isInitialized))
            ? DecorationImage(
          image: FileImage(File(_localAvatarPath!)),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: (_localAvatarPath == null || (!_fileExists && _isInitialized))
          ? Icon(Icons.person, color: vPrimaryColor, size: widget.size * 0.5)
          : null,
    );

    // Wrap in hero if needed
    if (widget.useHero) {
      avatarContainer = Hero(
        tag: widget.heroTag,
        child: avatarContainer,
      );
    }

    return GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          // The circle background with either an image or a default icon.
          avatarContainer,

          // The small edit icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: vAccentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
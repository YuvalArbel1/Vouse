// lib/presentation/widgets/post/post_options.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import '../../screens/post/select_location_screen.dart';
import 'ai_text_generation_dialog.dart';
import 'post_option_icon.dart';
import 'recent_images_row.dart';
import '../../providers/post/post_images_provider.dart';

/// A widget that displays the bottom options for the "Create Post" screen.
///
/// This widget includes:
/// 1. A horizontally scrollable row containing the camera option and the most recent 4 images,
///    provided by the [RecentImagesRow] widget.
/// 2. A row of action icons for additional options:
///    - **Gallery**: Opens the device gallery to select an image.
///    - **Location**: Navigates to the location selection screen.
///    - **AI**: Opens an AI text generation dialog.
///
/// The container uses a common shadow style from [vouseBoxDecoration] to maintain consistency.
class PostOptions extends ConsumerStatefulWidget {
  /// Creates a [PostOptions] widget.
  const PostOptions({super.key});

  @override
  ConsumerState<PostOptions> createState() => _PostOptionsState();
}

class _PostOptionsState extends ConsumerState<PostOptions> {
  final ImagePicker _picker = ImagePicker();

  /// Attempts to add a new image to the post.
  ///
  /// If fewer than 4 images are currently selected, the image at the provided [path]
  /// is added; otherwise, a toast message is shown.
  void _attemptAddImage(String path) {
    final currentImages = ref.read(postImagesProvider);
    if (currentImages.length >= 4) {
      toast("You can't add more than 4 images");
    } else {
      ref.read(postImagesProvider.notifier).addImage(path);
    }
  }

  /// Opens the device gallery to allow the user to pick an image.
  ///
  /// If an image is selected, its file path is added via [_attemptAddImage].
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    _attemptAddImage(pickedFile.path);
  }

  /// Handles the AI option press by showing the [AiTextGenerationDialog].
  ///
  /// If the dialog returns generated text, a toast message is displayed.
  void _onAIPressed() async {
    final generatedText = await showDialog<String>(
      context: context,
      builder: (_) => const AiTextGenerationDialog(),
    );

    // If non-empty text is returned, show a confirmation toast.
    if (generatedText != null && generatedText.isNotEmpty) {
      toast("AI text inserted: $generatedText");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false, // Only apply bottom safe area.
      child: Container(
        width: context.width(),
        padding: const EdgeInsets.all(16),
        // Using the common vouseBoxDecoration for shadow, and overriding the borderRadius
        // to apply top-only rounding.
        decoration: vouseBoxDecoration(
          backgroundColor: vAppLayoutBackground,
          shadowOpacity: 20,
          blurRadius: 6,
          offset: const Offset(0, 4),
        ).copyWith(borderRadius: radiusOnly(topRight: 32, topLeft: 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) Recent images row.
            const RecentImagesRow(),
            const SizedBox(height: 16),

            // 2) Row of option icons: Gallery, Location, and AI.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildOptionIcon(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  onTap: _pickFromGallery,
                ),
                buildOptionIcon(
                  icon: Icons.location_on,
                  label: "Location",
                  onTap: () async {
                    final chosenLatLng = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelectLocationScreen(),
                      ),
                    );
                    if (chosenLatLng == null) return;
                    toast(
                        "Location chosen: ${chosenLatLng.latitude},${chosenLatLng.longitude}");
                  },
                ),
                buildOptionIcon(
                  icon: Icons.auto_awesome,
                  label: "AI",
                  onTap: _onAIPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

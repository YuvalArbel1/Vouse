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
/// This includes:
/// 1. [RecentImagesRow] for camera + recent local images.
/// 2. A row of extra icons for:
///   - Gallery
///   - Location
///   - AI text generation
///
/// The container uses a shadow style from [vouseBoxDecoration] with top-only rounding.
class PostOptions extends ConsumerStatefulWidget {
  const PostOptions({super.key});

  @override
  ConsumerState<PostOptions> createState() => _PostOptionsState();
}

class _PostOptionsState extends ConsumerState<PostOptions> {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the system gallery and calls [addImageFromGallery]
  /// to store ephemeral path + MD5 deduping.
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final path = pickedFile.path;
    final images = ref.read(postImagesProvider);

    // If user picks an already selected ephemeral path (less likely from the system UI),
    // we remove it. Typically ephemeral path from gallery is unique each pick.
    // But let's handle the scenario:
    if (images.contains(path)) {
      // remove
      ref.read(postImagesProvider.notifier).removeImage(path);
      return;
    }

    // else attempt to add
    final result =
        await ref.read(postImagesProvider.notifier).addImageFromGallery(path);

    switch (result) {
      case AddImageResult.duplicate:
        toast("You've already selected this image!");
        break;
      case AddImageResult.maxReached:
        toast("You can't add more than 4 images");
        break;
      case AddImageResult.success:
        // no toast needed
        break;
    }
  }

  /// Opens an [AiTextGenerationDialog] for generating post text via AI.
  Future<void> _onAIPressed() async {
    final generatedText = await showDialog<String>(
      context: context,
      builder: (_) => const AiTextGenerationDialog(),
    );

    if (generatedText != null && generatedText.isNotEmpty) {
      toast("AI text inserted: $generatedText");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: context.width(),
        padding: const EdgeInsets.all(16),
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
            // The row with camera + recent images
            const RecentImagesRow(),
            const SizedBox(height: 16),

            // Additional icons: Gallery, Location, AI
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
                      "Location chosen: ${chosenLatLng.latitude},${chosenLatLng.longitude}",
                    );
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

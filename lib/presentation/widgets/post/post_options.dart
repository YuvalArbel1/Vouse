// lib/presentation/widgets/post/post_options.dart

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/util/colors.dart';
import 'ai_text_generation_dialog.dart';
import 'post_option_icon.dart';
import 'recent_images_row.dart';
import '../../providers/post/post_images_provider.dart';

/// The bottom section of "Create Post" screen. Contains:
/// 1) A horizontally scrollable row of camera + last 4 images [RecentImagesRow]
/// 2) Icons for Gallery, Location, AI, etc.
class PostOptions extends ConsumerStatefulWidget {
  const PostOptions({super.key});

  @override
  ConsumerState<PostOptions> createState() => _PostOptionsState();
}

class _PostOptionsState extends ConsumerState<PostOptions> {
  final ImagePicker _picker = ImagePicker();

  /// Attempt to add an image path to the postImagesProvider if < 4
  void _attemptAddImage(String path) {
    final currentImages = ref.read(postImagesProvider);
    if (currentImages.length >= 4) {
      toast("You can't add more than 4 images");
    } else {
      ref.read(postImagesProvider.notifier).addImage(path);
    }
  }

  /// Opens phone gallery for a single image
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    _attemptAddImage(pickedFile.path);
  }

  void _onAIPressed() async {
    // Show the AiTextGenerationDialog and wait for user to Insert or close
    final generatedText = await showDialog<String>(
      context: context,
      builder: (_) => AiTextGenerationDialog(),
    );

    // If user canceled, generatedText == null
    // If user inserted text, we have it in generatedText
    if (generatedText != null && generatedText.isNotEmpty) {
      // For demonstration, just show a toast
      // In real usage, you might update your post text field:
      // myTextController.text += "\n$generatedText";
      toast("AI text inserted: $generatedText");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false, // only care about bottom safe area
      child: Container(
        width: context.width(),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vAppLayoutBackground,
          borderRadius: radiusOnly(topRight: 32, topLeft: 32),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) The horizontally scrollable row for camera + last 4 images
            const RecentImagesRow(),
            const SizedBox(height: 16),

            // 2) The row of icons: Gallery, Location, AI
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
                  onTap: () => toast("Location pressed"),
                ),
                buildOptionIcon(
                  icon: Icons.auto_awesome, // or any AI icon
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

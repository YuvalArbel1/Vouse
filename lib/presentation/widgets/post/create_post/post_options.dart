// lib/presentation/widgets/post/create_post/post_options.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import 'ai_text_generation_dialog.dart';
import 'post_option_icon.dart';
import 'recent_images_row.dart';
import '../../../providers/post/post_images_provider.dart';
import '../../../widgets/navigation/navigation_service.dart';

class PostOptions extends ConsumerStatefulWidget {
  const PostOptions({super.key});

  @override
  ConsumerState<PostOptions> createState() => _PostOptionsState();
}

class _PostOptionsState extends ConsumerState<PostOptions> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  // Animation controller for the options panel
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start panel animation when widget is first built
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Picks an image from the system gallery and calls [addImageFromGallery]
  /// to store ephemeral path + MD5 deduping.
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final path = pickedFile.path;
    final images = ref.read(postImagesProvider);

    // If user picks an already selected ephemeral path, we remove it.
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
    showDialog(
      context: context,
      builder: (_) => const AiTextGenerationDialog(),
    );
  }

  /// Opens the location selection screen using NavigationService
  void _openLocationPicker() {
    ref.read(navigationServiceProvider).navigateToLocationSelection(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: context.width(),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha(240),
                  Colors.white,
                ],
              ),
              borderRadius: radiusOnly(topRight: 32, topLeft: 32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The row with camera + recent images
                const RecentImagesRow(),
                const SizedBox(height: 16),

                // Additional icons: Gallery, Location, AI
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildOptionIcon(
                        icon: Icons.photo_library,
                        label: "Gallery",
                        onTap: _pickFromGallery,
                        tooltipText: "Add from gallery",
                      ),
                      const SizedBox(width: 24),
                      buildOptionIcon(
                        icon: Icons.location_on,
                        label: "Location",
                        onTap: _openLocationPicker,
                        tooltipText: "Add your location",
                      ),
                      const SizedBox(width: 24),
                      buildOptionIcon(
                        icon: Icons.auto_awesome,
                        label: "AI",
                        onTap: _onAIPressed,
                        tooltipText: "Generate text with AI",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
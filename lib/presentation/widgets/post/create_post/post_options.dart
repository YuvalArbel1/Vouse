// lib/presentation/widgets/post/create_post/post_options.dart

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/util/colors.dart';
import 'ai_text_generation_dialog.dart';
import 'post_option_icon.dart';
import 'recent_images_row.dart';
import '../../../providers/post/post_images_provider.dart';
import '../../../widgets/navigation/navigation_service.dart';

/// A widget that displays the bottom options for the "Create Post" screen.
///
/// This includes:
/// 1. [RecentImagesRow] for camera + recent local images.
/// 2. A row of extra icons for:
///   - Gallery
///   - Location
///   - AI text generation
///   - Hashtags
///   - Schedule
///
/// Features:
/// - Improved visual design with gradient background
/// - Animation effects for better UX
/// - Consistent styling with app theme
/// - Tooltips for better accessibility
/// - Navigation service integration
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
    showDialog(
      context: context,
      builder: (_) => const AiTextGenerationDialog(),
    );
  }

  /// Opens the location selection screen using NavigationService
  void _openLocationPicker() {
    ref.read(navigationServiceProvider).navigateToLocationSelection(context);
  }

  /// Shows hashtag suggestions dialog
  void _showHashtagSuggestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: context.height() * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  "🏷️ Trending Hashtags",
                  style: boldTextStyle(size: 18),
                ),
                const SizedBox(height: 12),

                // Hashtag categories
                _buildHashtagCategories(),

                // Hashtag chips
                Expanded(
                  child: _buildHashtagSuggestions(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the hashtag categories bar
  Widget _buildHashtagCategories() {
    final categories = ["Trending", "Business", "Technology", "Lifestyle", "Marketing"];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: index == 0,
              backgroundColor: Colors.grey.withAlpha(30),
              selectedColor: vPrimaryColor.withAlpha(40),
              labelStyle: TextStyle(
                color: index == 0 ? vPrimaryColor : Colors.grey,
                fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) {},
            ),
          );
        },
      ),
    );
  }

  /// Builds the hashtag suggestions
  Widget _buildHashtagSuggestions() {
    final hashtags = [
      "#SocialMedia", "#DigitalMarketing", "#ContentCreation",
      "#GrowthHacking", "#Entrepreneur", "#Success", "#BusinessTips",
      "#Leadership", "#Innovation", "#WorkFromHome", "#RemoteWork",
      "#ProductivityTips", "#Inspiration", "#Motivation", "#Strategy",
      "#SmallBusiness", "#StartupLife", "#Marketing", "#BrandAwareness"
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: hashtags.length,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: vPrimaryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: vPrimaryColor.withAlpha(50)),
          ),
          child: InkWell(
            onTap: () {
              ref.read(navigationServiceProvider).navigateBack(context);
              toast("${hashtags[index]} added to post");
            },
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Text(
                hashtags[index],
                style: TextStyle(
                  color: vPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
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

                // Additional icons: Gallery, Location, AI, Hashtags, Schedule
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildOptionIcon(
                        icon: Icons.photo_library,
                        label: "Gallery",
                        onTap: _pickFromGallery,
                        tooltipText: "Add from gallery",
                      ),
                      const SizedBox(width: 16),
                      buildOptionIcon(
                        icon: Icons.location_on,
                        label: "Location",
                        onTap: _openLocationPicker,
                        tooltipText: "Add your location",
                      ),
                      const SizedBox(width: 16),
                      buildOptionIcon(
                        icon: Icons.auto_awesome,
                        label: "AI",
                        onTap: _onAIPressed,
                        tooltipText: "Generate text with AI",
                        iconColor: vAccentColor,
                      ),
                      const SizedBox(width: 16),
                      buildOptionIcon(
                        icon: Icons.tag,
                        label: "Hashtags",
                        onTap: _showHashtagSuggestions,
                        tooltipText: "Add trending hashtags",
                      ),
                      const SizedBox(width: 16),
                      buildOptionIcon(
                        icon: Icons.schedule,
                        label: "Schedule",
                        onTap: () {
                          toast("Schedule feature coming soon!");
                        },
                        tooltipText: "Schedule your post",
                        isDisabled: true,
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
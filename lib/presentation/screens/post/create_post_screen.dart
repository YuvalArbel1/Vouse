import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_text_provider.dart';
import '../../widgets/post/post_options.dart';
import '../../widgets/post/post_text.dart';
import '../../widgets/post/selected_images_preview.dart';
import '../../widgets/post/schedule_post_bottom_sheet.dart';

/// A screen where the user can create a new post:
///  - Enter text in [PostText]
///  - See & manage selected images in [SelectedImagesPreview]
///  - Use bottom [PostOptions] for picking images or other actions.
///
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  @override
  void initState() {
    super.initState();
    // Remove native splash after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Sets status bar color once the widget is built
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  void _openShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true, // optional
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.7, // or 0.6, whichever height you prefer
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: const SharePostBottomSheet(), // your refactored widget
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Restore status bar color when leaving this screen
    setStatusBarColor(vAppLayoutBackground);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Read the current text from the provider
    final postText = ref.watch(postTextProvider);

    return Scaffold(
      backgroundColor: context.cardColor,

      /// AppBar for "New Post" title & "Post" button
      appBar: AppBar(
        iconTheme: IconThemeData(color: context.iconColor),
        backgroundColor: context.cardColor,
        title: Text('New Post', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        actions: [
          AppButton(
            shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
            text: 'Post',
            textStyle: secondaryTextStyle(color: Colors.white, size: 10),
            onTap: () {
              // 1) If user typed no text, show toast
              if (postText.trim().isEmpty) {
                toast('Write some text first!');
                return;
              }
              // 2) Otherwise, open the scheduling bottom sheet
              _openShareBottomSheet(context);
            },
            elevation: 0,
            color: vPrimaryColor,
            width: 50,
            padding: EdgeInsets.zero,
          ).paddingAll(16),
        ],
      ),

      /// A Stack so we can pin [PostOptions] at the bottom
      body: SizedBox(
        height: context.height(),
        child: Stack(
          children: [
            /// We can use a Column so content is scrolled if needed
            SingleChildScrollView(
              child: Column(
                children: [
                  // Text input area for "What’s on your mind?"
                  const PostText(),

                  // The preview of selected images (0-4).
                  // This will auto-update if user picks new images.
                  const SelectedImagesPreview(),

                  // Some space so the user sees everything above the pinned bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),

            /// The bottom bar with icons (camera row, location, AI, etc.)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: const PostOptions(),
            ),
          ],
        ),
      ),
    );
  }
}

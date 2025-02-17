import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../widgets/post/post_options.dart';
import '../../widgets/post/post_text.dart';
import '../../widgets/post/selected_images_preview.dart';

/// A screen where the user can create a new post:
///  - Enter text in [PostText]
///  - See & manage selected images in [SelectedImagesPreview]
///  - Use bottom [PostOptions] for picking images or other actions.
///
/// [FlutterNativeSplash.remove()] is called after the first frame,
/// so the user doesn't see the splash forever. Also updates
/// statusBar color to align with app theme.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
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

  @override
  void dispose() {
    // Restore status bar color when leaving this screen
    setStatusBarColor(vAppLayoutBackground);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // For now, does nothing. In future, gather post data & save
              // e.g., read text from PostText's controller, read images from postImagesProvider
            },
            elevation: 0,
            color: vPrimaryColor,
            width: 50,
            padding: EdgeInsets.all(0),
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

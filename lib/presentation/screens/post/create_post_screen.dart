import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:uuid/uuid.dart';

import '../../../core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/image_utils.dart';
import '../../../domain/entities/locaal db/post_entity.dart';
import '../../../domain/usecases/post/save_post_usecase.dart';
import '../../providers/post/post_images_provider.dart';
import '../../providers/post/post_local_providers.dart';
import '../../providers/post/post_location_provider.dart';
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

    // Hide status/nav bars
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );

    // Sets status bar color once the widget is built
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  @override
  void dispose() {
    // Restore status bar color when leaving this screen
    setStatusBarColor(vAppLayoutBackground);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  /// Shows a confirmation dialog to ensure the user really wants to clear everything.
  /// Returns `true` if user pressed "Yes," or `false`/`null` if canceled.
  Future<bool> _confirmClearPost() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Clear Post?', style: boldTextStyle()),
          content: Text(
            'Are you sure you want to clear all text, images, and location? '
            'This is irreversible.',
            style: primaryTextStyle(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  /// Called when user presses the "Clear" button.
  /// We show a dialog. If user confirms, we reset all post-related providers.
  Future<void> _onClearPressed() async {
    final shouldClear = await _confirmClearPost();
    if (!shouldClear) return;

    // Clear providers: text, images, location
    ref.read(postTextProvider.notifier).state = '';
    ref.read(postImagesProvider.notifier).clearAll();
    ref.read(postLocationProvider.notifier).state = null;

    toast('Post content cleared.');
  }

  Future<String?> _showDraftTitleDialog() async {
    final titleController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter Draft Title', style: boldTextStyle()),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: 'E.g. My Awesome Draft',
              // match the style from your post text's placeholder
              hintStyle: secondaryTextStyle(size: 12, color: vBodyGrey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  toast('Please enter a draft title.');
                  return;
                }
                Navigator.pop(ctx, title);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDraftPressed() async {
    // 1) Check if user typed anything
    final text = ref.read(postTextProvider).trim();
    if (text.isEmpty) {
      toast('Write some words first!');
      return;
    }

    // 2) Grab the current user from FirebaseAuth
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toast('No logged-in user found!');
      return;
    }

    // 3) Prompt user for a title
    final draftTitle = await _showDraftTitleDialog();
    if (draftTitle == null) {
      // user canceled
      return;
    }

    // 4) Move local images from temp to a stable path
    final images = ref.read(postImagesProvider);
    final localPaths = await ImageUtils.moveImagesToPermanentFolder(images);

    // 5) Read location if user picked one
    final loc = ref.read(postLocationProvider);
    double? lat;
    double? lng;
    String? addr;
    if (loc != null) {
      lat = loc.latitude;
      lng = loc.longitude;
      addr = loc.address;
    }

    // 6) Build the PostEntity for a DRAFT
    final postEntity = PostEntity(
      postIdLocal: const Uuid().v4(),
      // random local ID
      postIdX: null,
      // not published to X yet
      content: text,
      title: draftTitle,
      createdAt: DateTime.now(),
      updatedAt: null,
      scheduledAt: null,
      // draft => no scheduled time
      visibility: null,
      // or 'everyone' if you prefer a default
      localImagePaths: localPaths,
      cloudImageUrls: [],
      locationLat: lat,
      locationLng: lng,
      locationAddress: addr,
    );

    // 7) Save it via your local DB usecase
    final saveUC = ref.read(savePostUseCaseProvider);

    final result = await saveUC.call(
      params: SavePostParams(
        postEntity,
        user.uid, // pass real user ID
      ),
    );

    // 8) Check result
    if (result is DataSuccess) {
      // Optionally clear the text & images
      ref.read(postTextProvider.notifier).state = '';
      ref.read(postImagesProvider.notifier).clearAll();
      ref.read(postLocationProvider.notifier).state = null;
      Navigator.pop(context);
    } else if (result is DataFailed) {
      toast("Error saving draft: ${result.error?.error}");
    }
  }

  void _openShareBottomSheet(BuildContext context) {
    // 1) Read the user's typed text
    final currentText = ref.read(postTextProvider).trim();

    // 2) If empty => show toast and return
    if (currentText.isEmpty) {
      toast('Please enter some text first!');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      enableDrag: true,
      isDismissible: true,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.8,
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
            child: const SharePostBottomSheet(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cardColor,

      /// AppBar for "New Post" title & "Post" button
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // We'll supply our own arrow
        backgroundColor: context.cardColor,
        elevation: 0,
        centerTitle: true,

        // Enough room for arrow + spacing + "Clear" button
        leadingWidth: 120,

        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back arrow
            IconButton(
              icon: Icon(Icons.arrow_back, color: context.iconColor),
              onPressed: () => Navigator.pop(context),
              // You can tweak these to reduce or expand spacing
              padding: const EdgeInsets.all(0),
              visualDensity: const VisualDensity(horizontal: -4),
            ),
            const SizedBox(width: 8), // bigger gap from arrow to Clear

            // "Clear" with an outline + flexible so it won't overflow
            Flexible(
              child: AppButton(
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: radius(4),
                  side: BorderSide(color: vAccentColor),
                ),
                text: 'Clear',
                textStyle: secondaryTextStyle(color: vAccentColor, size: 10),
                onTap: _onClearPressed,
                // define your logic
                elevation: 0,
                color: Colors.transparent,
                // Enough width to look nice but flexible to shrink on small screens
                width: 50,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),

        title: Text('New Post', style: boldTextStyle(size: 20)),

        actions: [
          // "Draft"
          AppButton(
            shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
            text: 'Draft',
            textStyle: secondaryTextStyle(color: Colors.white, size: 10),
            onTap: _onDraftPressed,
            // define your logic
            elevation: 0,
            color: vAccentColor.withAlpha(220),
            width: 50,
            padding: EdgeInsets.zero,
          ).paddingAll(4),

          // "Post"
          AppButton(
            shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
            text: 'Post',
            textStyle: secondaryTextStyle(color: Colors.white, size: 10),
            onTap: () => _openShareBottomSheet(context),
            elevation: 0,
            color: vPrimaryColor.withAlpha(220),
            width: 50,
            padding: EdgeInsets.zero,
            margin: EdgeInsets.only(right: 13),
          ).paddingAll(4),
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

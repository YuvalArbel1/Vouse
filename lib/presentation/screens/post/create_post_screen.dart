// lib/presentation/screens/post/create_post_screen.dart

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
import '../../../domain/entities/local_db/post_entity.dart';
import '../../../domain/usecases/post/save_post_usecase.dart';
import '../../providers/local_db/local_post_providers.dart';
import '../../providers/post/post_images_provider.dart';
import '../../providers/post/post_location_provider.dart';
import '../../providers/post/post_refresh_provider.dart';
import '../../providers/post/post_text_provider.dart';
import '../../providers/home/home_content_provider.dart';
import '../../widgets/post/create_post/post_options.dart';
import '../../widgets/post/create_post/post_text.dart';
import '../../widgets/post/create_post/selected_images_preview.dart';
import '../../widgets/post/create_post/schedule_post_bottom_sheet.dart';
import '../../providers/navigation/navigation_service.dart';
import '../../widgets/common/loading/full_screen_loading.dart';

/// A screen where the user can create a new post:
/// - Enter text in [PostText]
/// - View and manage selected images via [SelectedImagesPreview]
/// - Pick images, location, or AI text from [PostOptions]
///
/// The user can also save a draft or share the post.
///
/// Features:
/// - Enhanced UI with meaningful animations
/// - Twitter-like interface components
/// - Clear user feedback with toasts
/// - Autosave for preventing lost work
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  /// Tracks whether content is being processed
  bool _isProcessing = false;

  /// Animation controller for the screen
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// Indicates if there are unsaved changes
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();

    // Set up animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();

    // Add a focus listener for navigation returns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Using Flutter's focus system to detect when screen gets focus
      SystemChannels.lifecycle.setMessageHandler((msg) {
        if (msg == AppLifecycleState.resumed.toString()) {
          _setupChangeListeners(); // Your existing refresh method
        }
        return Future.value(msg);
      });
    });
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Once the widget is built, set the status bar color to match the card theme
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  void _setupChangeListeners() {
    // Listen to changes in the post content providers to track unsaved changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(postTextProvider, (_, __) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      });

      ref.listen(postImagesProvider, (_, __) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      });

      ref.listen(postLocationProvider, (_, __) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      });
    });
  }

  @override
  void dispose() {
    // Restore the status bar color
    setStatusBarColor(vAppLayoutBackground);
    _animationController.dispose();
    super.dispose();
  }

  /// Shows a confirmation dialog to ensure the user really wants to clear post data.
  /// Returns `true` if the user pressed "Yes."
  Future<bool> _confirmClearPost() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Clear Post?', style: boldTextStyle()),
          content: Text(
            'Are you sure you want to clear all text, images, and location? This is irreversible.',
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

  /// Called when the user taps the "Clear" button.
  /// Prompts the user, and if confirmed, clears the text, images, and location providers.
  Future<void> _onClearPressed() async {
    final shouldClear = await _confirmClearPost();
    if (!shouldClear) return;

    ref.read(postTextProvider.notifier).state = '';
    ref.read(postImagesProvider.notifier).clearAll();
    ref.read(postLocationProvider.notifier).state = null;

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      toast('Post content cleared');
    }
  }

  /// Prompts the user to enter a draft title using a dialog.
  /// Returns the provided title, or null if canceled.
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
              child: const Text('Save Draft'),
            ),
          ],
        );
      },
    );
  }

  /// Handles saving the current post as a draft:
  /// - Ensures there's text
  /// - Retrieves the current Firebase user
  /// - Asks for a draft title
  /// - Moves images to a stable path
  /// - Builds and saves a draft [PostEntity]
  /// - Clears the post content and closes the screen if successful
  Future<void> _onDraftPressed() async {
    final text = ref.read(postTextProvider).trim();
    if (text.isEmpty) {
      toast('Write some words first!');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toast('No logged-in user found!');
      return;
    }

    final draftTitle = await _showDraftTitleDialog();
    if (!mounted) return; // Check if still mounted after dialog
    if (draftTitle == null) return; // user canceled

    setState(() => _isProcessing = true);

    try {
      // Move images to permanent folder
      final images = ref.read(postImagesProvider);
      final localPaths = await ImageUtils.moveImagesToPermanentFolder(images);

      if (!mounted) return;

      final loc = ref.read(postLocationProvider);
      double? lat;
      double? lng;
      String? addr;
      if (loc != null) {
        lat = loc.latitude;
        lng = loc.longitude;
        addr = loc.address;
      }

      final postEntity = PostEntity(
        postIdLocal: const Uuid().v4(),
        postIdX: null,
        content: text,
        title: draftTitle,
        createdAt: DateTime.now(),
        updatedAt: null,
        scheduledAt: null,
        visibility: null,
        localImagePaths: localPaths,
        cloudImageUrls: [],
        locationLat: lat,
        locationLng: lng,
        locationAddress: addr,
      );

      final saveUC = ref.read(savePostUseCaseProvider);
      final result = await saveUC.call(
        params: SavePostParams(postEntity, user.uid),
      );

      if (!mounted) return;

      if (result is DataSuccess) {
        // Trigger refresh for all relevant providers
        ref.read(postRefreshProvider.notifier).refreshDrafts();
        ref.read(postRefreshProvider.notifier).refreshAll();

        // Explicitly refresh home content
        await ref.read(homeContentProvider.notifier).refreshHomeContent();

        // Clear everything
        ref.read(postTextProvider.notifier).state = '';
        ref.read(postImagesProvider.notifier).clearAll();
        ref.read(postLocationProvider.notifier).state = null;

        setState(() {
          _hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text("Draft \"$draftTitle\" saved successfully"),
              ],
            ),
            backgroundColor: vAccentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        ref.read(navigationServiceProvider).navigateBack(context);
      } else if (result is DataFailed) {
        toast("Error saving draft: ${result.error?.error}");
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Opens the bottom sheet to share or schedule the post, if there's text.
  void _openShareBottomSheet() {
    final currentText = ref.read(postTextProvider).trim();
    if (currentText.isEmpty) {
      toast('Please enter some text first!');
      return;
    }

    if (!mounted) return;

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
                  color: Colors.black.withAlpha(40),
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

  /// Show unsaved changes confirmation dialog
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Discard Changes?', style: boldTextStyle()),
        content: Text(
          'You have unsaved changes. Are you sure you want to leave without saving?',
          style: primaryTextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          ref.read(navigationServiceProvider).navigateBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: context.cardColor,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildContent(),
            ),

            // Loading overlay
            if (_isProcessing)
              const BlockingSpinnerOverlay(
                isVisible: true,
                message: "Processing...",
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the app bar without a progress indicator.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: context.cardColor,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 120,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: context.iconColor),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                ref.read(navigationServiceProvider).navigateBack(context);
              }
            },
            padding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: AppButton(
              shapeBorder: RoundedRectangleBorder(
                borderRadius: radius(4),
                side: BorderSide(color: vAccentColor),
              ),
              text: 'Clear',
              textStyle: secondaryTextStyle(color: vAccentColor, size: 10),
              onTap: _onClearPressed,
              elevation: 0,
              color: Colors.transparent,
              width: 50,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      title: Text('New Post', style: boldTextStyle(size: 20)),
      actions: [
        AppButton(
          shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
          text: 'Draft',
          textStyle: secondaryTextStyle(color: Colors.white, size: 10),
          onTap: _onDraftPressed,
          elevation: 0,
          color: vAccentColor.withAlpha(220),
          width: 50,
          padding: EdgeInsets.zero,
        ).paddingAll(4),
        AppButton(
          shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
          text: 'Post',
          textStyle: secondaryTextStyle(color: Colors.white, size: 10),
          onTap: _openShareBottomSheet,
          elevation: 0,
          color: vPrimaryColor.withAlpha(220),
          width: 50,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.only(right: 13),
        ).paddingAll(4),
      ],
    );
  }

  /// Builds the main content of the screen.
  Widget _buildContent() {
    return SafeArea(
      child: SizedBox(
        height: context.height(),
        child: Stack(
          children: [
            // Scrollable main content with extra padding at the bottom
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const PostText(),
                  const SelectedImagesPreview(),
                  SizedBox(height: context.height() * 0.15),
                ],
              ),
            ),
            // Pinned bottom bar
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: PostOptions(),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/presentation/screens/post/create_post_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:uuid/uuid.dart';

import '../../../core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/image_utils.dart';
import '../../../domain/entities/google_maps/place_location_entity.dart';
import '../../../domain/entities/local_db/post_entity.dart';
import '../../../domain/entities/secure_db/x_auth_tokens.dart';
import '../../../domain/usecases/post/save_post_usecase.dart';
import '../../providers/auth/x/twitter_connection_provider.dart';
import '../../providers/auth/x/x_auth_providers.dart';
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
  /// The draft post to edit (if any)
  final PostEntity? draftToEdit;
  final PostEntity? scheduledPostToEdit;

  /// Creates a new post creation screen.
  const CreatePostScreen({
    super.key,
    this.draftToEdit,
    this.scheduledPostToEdit,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

/// The state for the [CreatePostScreen].
///
/// Handles user interactions, provides feedback, and manages state transitions
/// throughout the post creation process.
class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  /// Tracks whether content is being processed (saving, uploading, etc.).
  bool _isProcessing = false;

  /// Whether we're editing an existing draft
  bool _isEditing = false;

  /// The draft being edited
  PostEntity? _editingDraft;

  /// Whether we're editing a scheduled post
  bool _isEditingScheduledPost = false;



  /// Animation controller for the screen transition effects.
  late AnimationController _animationController;

  /// Animation for fading in the screen content.
  late Animation<double> _fadeAnimation;

  /// Text controller for draft title input
  final TextEditingController _titleController = TextEditingController();

  /// Initial values for comparison to detect changes
  String _initialPostText = '';
  List<String> _initialImagePaths = [];
  PlaceLocationEntity? _initialLocation;

  @override
  void initState() {
    super.initState();
    _initializeScreen();

    // Set up animation controller for smooth transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();

    // Store initial values for change detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Load post data AFTER the widget tree is built
      if (widget.scheduledPostToEdit != null) {
        _loadScheduledPostForEditing();
      } else {
        _loadDraftIfEditing();
      }
      _captureInitialValues();
    });
  }

  /// Initializes the screen by removing splash screen and setting status bar color.
  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FlutterNativeSplash.remove();
    });

    // Once the widget is built, set the status bar color to match the card theme
    afterBuildCreated(() {
      if (!mounted) return;
      setStatusBarColor(context.cardColor);
    });
  }

  // Loads data for a scheduled post being edited
  void _loadScheduledPostForEditing() {
    final scheduledPost = widget.scheduledPostToEdit;
    if (scheduledPost != null) {
      try {
        // Set the post text
        ref.read(postTextProvider.notifier).state = scheduledPost.content;

        // Load existing images
        for (final path in scheduledPost.localImagePaths) {
          ref.read(postImagesProvider.notifier).addImageFromGallery(path);
        }

        // Load location if available
        if (scheduledPost.locationLat != null &&
            scheduledPost.locationLng != null) {
          final location = PlaceLocationEntity(
            latitude: scheduledPost.locationLat!,
            longitude: scheduledPost.locationLng!,
            address: scheduledPost.locationAddress,
          );
          ref.read(postLocationProvider.notifier).state = location;
        }

        // Set state to track that we're editing a scheduled post
        setState(() {
          _titleController.text = scheduledPost.title;
          _isEditingScheduledPost = true;
        });

        // Capture initial values after loading the post
        _captureInitialValues();
      } catch (e) {
        toast("Error loading scheduled post: $e");
      }
    }
  }

  /// Captures the initial state of the post content for change detection
  void _captureInitialValues() {
    _initialPostText = ref.read(postTextProvider);
    _initialImagePaths = List.from(ref.read(postImagesProvider));
    _initialLocation = ref.read(postLocationProvider);
  }

  /// Checks if there are unsaved changes by comparing current values with initial values
  bool _checkForUnsavedChanges() {
    // If editing a draft, compare with the original content
    if (_isEditing && _editingDraft != null) {
      final currentText = ref.read(postTextProvider);
      final currentLocation = ref.read(postLocationProvider);
      final currentImages = ref.read(postImagesProvider);

      return currentText != _editingDraft!.content ||
          currentLocation?.latitude != _editingDraft!.locationLat ||
          currentLocation?.longitude != _editingDraft!.locationLng ||
          currentImages.length != _editingDraft!.localImagePaths.length;
    }

    // For a new post, check if there's any content
    final currentText = ref.read(postTextProvider).trim();
    final currentImages = ref.read(postImagesProvider);
    final currentLocation = ref.read(postLocationProvider);

    // Compare with initial values
    final textChanged = currentText != _initialPostText.trim();
    final imagesChanged = currentImages.length != _initialImagePaths.length;
    final locationChanged = currentLocation != _initialLocation;

    return textChanged || imagesChanged || locationChanged;
  }

  @override
  void dispose() {
    // Restore the status bar color to default
    setStatusBarColor(vAppLayoutBackground);

    // Dispose animation resources
    _animationController.dispose();

    super.dispose();
  }

  /// Shows a confirmation dialog to ensure the user really wants to clear post data.
  ///
  /// Returns `true` if the user confirms, `false` otherwise.
  Future<bool> _confirmClearPost() async {
    if (!_checkForUnsavedChanges()) return true;

    final BuildContext currentContext = context;
    final result = await showDialog<bool>(
      context: currentContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text(_isEditing ? 'Edit Draft' : 'New Post',
              style: boldTextStyle(size: 20)),
          content: Text(
            'Are you sure you want to clear all text, images, and location? This is irreversible.',
            style: primaryTextStyle(),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  ref.read(navigationServiceProvider).navigateBack(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(navigationServiceProvider).navigateBack(context),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Handles the "Clear" button press.
  ///
  /// Prompts for confirmation, then clears all post content if confirmed.
  Future<void> _onClearPressed() async {
    final shouldClear = await _confirmClearPost();
    if (!shouldClear || !mounted) return;

    ref.read(postTextProvider.notifier).state = '';
    ref.read(postImagesProvider.notifier).clearAll();
    ref.read(postLocationProvider.notifier).state = null;

    // Capture new initial values after clearing
    _captureInitialValues();

    toast('Post content cleared');
  }

  /// Shows a dialog to prompt the user for a draft title.
  ///
  /// Returns the entered title, or null if the dialog was canceled.
  Future<String?> _showDraftTitleDialog() async {
    final BuildContext currentContext = context;

    return showDialog<String>(
      context: currentContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter Draft Title', style: boldTextStyle()),
          content: TextField(
            controller: _titleController,
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
                final title = _titleController.text.trim();
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

  /// Loads draft data if we're editing an existing draft
  void _loadDraftIfEditing() {
    final draftToEdit = widget.draftToEdit;
    if (draftToEdit != null) {
      try {
        // Set the post text
        ref.read(postTextProvider.notifier).state = draftToEdit.content;

        // Load existing images
        for (final path in draftToEdit.localImagePaths) {
          ref.read(postImagesProvider.notifier).addImageFromGallery(path);
        }

        // Load location if available
        if (draftToEdit.locationLat != null &&
            draftToEdit.locationLng != null) {
          final location = PlaceLocationEntity(
            latitude: draftToEdit.locationLat!,
            longitude: draftToEdit.locationLng!,
            address: draftToEdit.locationAddress,
          );
          ref.read(postLocationProvider.notifier).state = location;
        }

        // Set state to track that we're editing
        setState(() {
          _titleController.text = draftToEdit.title;
          _editingDraft = draftToEdit;
          _isEditing = true;
        });

        // Capture initial values after loading the draft
        _captureInitialValues();
      } catch (e) {
        toast("Error loading draft: $e");
      }
    }
  }

  /// Helper method to clear all post-related providers
  void _clearAllProviders() {
    ref.read(postTextProvider.notifier).state = '';
    ref.read(postImagesProvider.notifier).clearAll();
    ref.read(postLocationProvider.notifier).state = null;
  }

  /// Handles saving the current post as a draft.
  ///
  /// The flow:
  /// 1. Validates text content
  /// 2. Gets the current user
  /// 3. Prompts for a draft title
  /// 4. Moves images to permanent storage
  /// 5. Creates and saves a draft PostEntity
  /// 6. Refreshes providers and gives feedback
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

    // If editing, use the existing title, otherwise prompt for a new one
    String? draftTitle;
    if (_isEditing) {
      draftTitle = _titleController.text.trim();
      if (draftTitle.isEmpty) {
        toast('Draft title cannot be empty');
        return;
      }
    } else {
      draftTitle = await _showDraftTitleDialog();
      if (!mounted) return; // Check if still mounted after dialog
      if (draftTitle == null) return; // user canceled
    }

    setState(() => _isProcessing = true);

    try {
      // Move ALL images to permanent folder, including existing ones
      final images = ref.read(postImagesProvider);
      final localPaths = await ImageUtils.moveImagesToPermanentFolder(images);

      if (!mounted) return;

      // Extract location data if present
      final loc = ref.read(postLocationProvider);
      double? lat;
      double? lng;
      String? addr;
      if (loc != null) {
        lat = loc.latitude;
        lng = loc.longitude;
        addr = loc.address;
      }

      // Create or update the post entity
      final postEntity = PostEntity(
        postIdLocal: _editingDraft?.postIdLocal ?? const Uuid().v4(),
        postIdX: _editingDraft?.postIdX,
        content: text,
        title: draftTitle,
        createdAt: _editingDraft?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        // Always update the updatedAt time
        scheduledAt: null,
        visibility: _editingDraft?.visibility,
        localImagePaths: localPaths,
        // Use the newly moved image paths
        cloudImageUrls: _editingDraft?.cloudImageUrls ?? [],
        locationLat: lat,
        locationLng: lng,
        locationAddress: addr,
      );

      // Save the draft post
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

        if (!mounted) return;

        // Clear providers using the helper method
        _clearAllProviders();

        setState(() {
          _isEditing = false;
          _editingDraft = null;
          _titleController.clear();
        });

        // Update initial values after saving
        _captureInitialValues();

        // Show success message
        final BuildContext currentContext = context;
        if (context.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(_isEditing
                      ? "Draft updated successfully"
                      : "Draft \"$draftTitle\" saved successfully"),
                ],
              ),
              backgroundColor: vAccentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Use the new navigateAfterPostSave method instead of navigateBack
          ref.read(navigationServiceProvider).navigateAfterPostSave(
                currentContext,
                _isEditing,
              );
        }
      } else if (result is DataFailed) {
        toast("Error saving draft: ${result.error?.error}");
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Opens the bottom sheet to share or schedule the post.
  ///
  /// First verifies the user is connected to X (Twitter),
  /// otherwise shows a dialog prompting them to connect.
  void _openShareBottomSheet() async {
    final currentText = ref.watch(postTextProvider).trim();
    if (currentText.isEmpty) {
      toast('Please enter some text first!');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Always force refresh connection status before checking
      final isConnected = await ref
          .read(twitterConnectionProvider.notifier)
          .checkConnectionStatus(forceCheck: true);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (!isConnected) {
        // Show dialog to prompt X connection
        final shouldConnect = await _showConnectXDialog();
        if (!shouldConnect || !mounted) return;

        // User wants to connect, initiate X connection
        await _connectToX();
        return; // _connectToX will call _openShareBottomSheet again if successful
      }

      // If we reach here, X is connected, open the share bottom sheet
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
              child: SchedulePostBottomSheet(
                editingDraft: _isEditing ? _editingDraft : null,
                editingScheduledPost:
                    _isEditingScheduledPost ? widget.scheduledPostToEdit : null,
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Error checking Twitter connection: $e");
      toast("Error verifying Twitter connection: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Shows a dialog prompting the user to connect their X account.
  ///
  /// Returns true if the user wants to connect, false otherwise.
  Future<bool> _showConnectXDialog() async {
    final BuildContext currentContext = context;

    return await showDialog<bool>(
          context: currentContext,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.link, color: vAccentColor),
                const SizedBox(width: 10),
                Text('Connect to X', style: boldTextStyle()),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: vAccentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.public,
                        size: 48,
                        color: vAccentColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connect your X account',
                        style: boldTextStyle(size: 16, color: vBodyGrey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'To schedule and post to X (Twitter), you need to connect your account first.',
                        style: primaryTextStyle(color: vBodyGrey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Later', style: TextStyle(color: vBodyGrey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: vAccentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Connect Now'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Initiates Twitter OAuth sign-in flow, retrieves tokens, then stores them securely.
  /// Initiates Twitter OAuth sign-in flow, retrieves tokens, then stores them securely.
  Future<void> _connectToX() async {
    setState(() => _isProcessing = true);

    try {
      // Directly use the TwitterConnectionProvider for consistent state management

      // First get the tokens via OAuth flow
      final result = await ref.read(signInToXUseCaseProvider).call();

      if (!mounted) return;

      if (result is DataSuccess<XAuthTokens> && result.data != null) {
        final tokens = result.data!;

        // Connect using our centralized provider
        final connected = await ref
            .read(twitterConnectionProvider.notifier)
            .connectTwitter(tokens);

        if (!mounted) return;

        // Force refresh status to ensure UI consistency
        await ref
            .read(twitterConnectionProvider.notifier)
            .checkConnectionStatus(forceCheck: true);

        if (connected) {
          toast("Twitter account connected successfully");

          // Continue with share dialog
          if (mounted) {
            _openShareBottomSheet();
          }
        } else {
          toast("Failed to connect Twitter account");
        }
      } else if (result is DataFailed) {
        toast("Twitter authentication failed: ${result.error?.error}");
      }
    } catch (e) {
      debugPrint("CreatePostScreen: Error connecting to X: $e");
      toast("Error connecting to X: $e");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Shows a dialog for confirming exit with unsaved changes.
  ///
  /// Returns true if it's safe to pop the screen, false otherwise.
  /// If user confirms discarding changes, it clears all post content.
  Future<bool> _onWillPop() async {
    // Only check for changes on demand when actually needed
    if (!_checkForUnsavedChanges()) return true;

    final BuildContext currentContext = context;
    final result = await showDialog<bool>(
      context: currentContext,
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

    // If user confirms discarding changes, clear all content
    if (result == true) {
      // Clear all post content
      ref.read(postTextProvider.notifier).state = '';
      ref.read(postImagesProvider.notifier).clearAll();
      ref.read(postLocationProvider.notifier).state = null;

      // Reset state
      setState(() {
        _titleController.clear();
        if (!_isEditing) {
          // Only capture new values if not editing to avoid confusion
          _captureInitialValues();
        }
      });
    }

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
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

  /// Builds the app bar with navigation, clear, draft and post buttons.
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
              if (shouldPop && context.mounted) {
                final BuildContext currentContext = context;
                ref
                    .read(navigationServiceProvider)
                    .navigateBack(currentContext);
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

  /// Builds the main content area with the text input, image previews, and options.
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

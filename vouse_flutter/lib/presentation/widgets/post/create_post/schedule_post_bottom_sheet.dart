// lib/presentation/widgets/post/create_post/schedule_post_bottom_sheet.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../../core/util/colors.dart';
import '../../../../core/util/common.dart';
import '../../../../core/util/image_utils.dart';
import '../../../../domain/entities/local_db/post_entity.dart';
import '../../../providers/auth/x/twitter_connection_provider.dart';
import '../../../providers/post/post_scheduler_provider.dart';
import '../../../providers/post/post_text_provider.dart';
import '../../../providers/post/post_images_provider.dart';
import '../../../providers/post/post_location_provider.dart';
import '../../../providers/navigation/navigation_service.dart';
import 'location_tag_widget.dart';
import 'selected_images_preview.dart';
import 'schedule_ai_dialog.dart';

/// An updated bottom sheet that allows the user to schedule a post for a future date/time,
/// using our new providers for server integration.
class SchedulePostBottomSheet extends ConsumerStatefulWidget {
  /// The draft post being edited (if any)
  final PostEntity? editingDraft;

  /// Creates a [SchedulePostBottomSheet].
  const SchedulePostBottomSheet({
    super.key,
    this.editingDraft,
  });

  @override
  ConsumerState<SchedulePostBottomSheet> createState() =>
      _SchedulePostBottomSheetState();
}

class _SchedulePostBottomSheetState
    extends ConsumerState<SchedulePostBottomSheet> {
  /// Controller for the post title.
  final TextEditingController _titleController = TextEditingController();

  /// The chosen scheduled date/time.
  DateTime? _scheduledDateTime;

  /// Whether the scheduling process is in progress.
  bool _isScheduling = false;

  /// Example "who can reply?" options.
  final List<Map<String, dynamic>> _replyOptions = [
    {'label': 'Everyone', 'icon': Icons.public},
    {'label': 'Verified accounts', 'icon': Icons.verified},
    {'label': 'Accounts you follow', 'icon': Icons.group},
  ];
  String _selectedReplyOption = 'Everyone';

  @override
  void initState() {
    super.initState();
    // Initialize with existing draft title if available
    if (widget.editingDraft != null) {
      _titleController.text = widget.editingDraft!.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// Truncates the [text] to [limit] characters, appending "..." if needed.
  String _truncateText(String text, int limit) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  /// Displays the full post text in a scrollable dialog.
  void _showFullTextDialog(String fullText) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title:
              Text('Post Content', style: boldTextStyle(color: vPrimaryColor)),
          content: SingleChildScrollView(
            child: Text(fullText, style: primaryTextStyle()),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () =>
                  ref.read(navigationServiceProvider).navigateBack(context),
              child: Text('Close', style: TextStyle(color: vPrimaryColor)),
            ),
          ],
        );
      },
    );
  }

  /// Sets the scheduled time to right now (immediately)
  void _scheduleNow() {
    final now = DateTime.now();
    setState(() {
      _scheduledDateTime = now;
    });
    toast('Post will be published immediately');
  }

  /// Lets the user pick a date/time within the next 7 days.
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final oneWeekLater = now.add(const Duration(days: 7));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: oneWeekLater,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: vPrimaryColor,
              onPrimary: Colors.white,
              onSurface: vBodyGrey,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: vPrimaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || pickedDate == null) return;

    // Calculate minimum time (if today, must be at least 5 minutes from now)
    final isToday = pickedDate.year == now.year &&
        pickedDate.month == now.month &&
        pickedDate.day == now.day;

    TimeOfDay initialTime = TimeOfDay.now();
    if (isToday) {
      // Add 5 minutes to current time
      final minutes = initialTime.minute + 5;
      initialTime = TimeOfDay(
          hour: initialTime.hour + (minutes ~/ 60), minute: minutes % 60);
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: vPrimaryColor,
              onPrimary: Colors.white,
              onSurface: vBodyGrey,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: vPrimaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || pickedTime == null) return;

    // Create the datetime
    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _scheduledDateTime = scheduledDateTime;
    });
  }

  /// Opens the AI dialog that can predict the best time to post.
  Future<void> _openAIDialog() async {
    final bestTime = await showDialog<DateTime?>(
      context: context,
      builder: (_) => const ScheduleAiDialog(),
    );
    if (mounted && bestTime != null) {
      setState(() => _scheduledDateTime = bestTime);
    }
  }

  /// Helper method to clear all post-related providers
  void _clearAllProviders() {
    ref.read(postTextProvider.notifier).state = '';
    ref.read(postImagesProvider.notifier).clearAll();
    ref.read(postLocationProvider.notifier).state = null;
  }

  /// Handles scheduling the post using the new post scheduler provider.
  Future<void> _onSchedulePressed() async {
    if (_isScheduling) return;

    setState(() => _isScheduling = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        toast('No logged-in user found!');
        return;
      }

      final title = _titleController.text.trim();
      if (title.isEmpty) {
        toast('Please enter a post title!');
        return;
      }

      if (_scheduledDateTime == null) {
        toast('Please pick a date & time first!');
        return;
      }

      final scheduledDate = _scheduledDateTime!;

      final text = ref.read(postTextProvider).trim();
      if (text.isEmpty) {
        toast('Write some words first!');
        return;
      }

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

      // Create post entity, using existing ID if editing
      final postEntity = PostEntity(
        postIdLocal: widget.editingDraft?.postIdLocal ?? const Uuid().v4(),
        postIdX: widget.editingDraft?.postIdX,
        content: text,
        title: title,
        createdAt: widget.editingDraft?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        scheduledAt: scheduledDate,
        visibility: _selectedReplyOption,
        localImagePaths: localPaths,
        cloudImageUrls: widget.editingDraft?.cloudImageUrls ?? [],
        locationLat: lat,
        locationLng: lng,
        locationAddress: addr,
      );

      // Use the scheduler provider to handle both server and local saving
      final success =
          await ref.read(postSchedulerProvider.notifier).schedulePost(
                post: postEntity,
                userId: user.uid,
              );

      if (!mounted) return;

      if (success) {
        // Show success message
        final schedulerState = ref.read(postSchedulerProvider);
        String message =
            'Post scheduled for ${DateFormat('MMM d, h:mm a').format(scheduledDate)}';

        if (schedulerState.state == SchedulingState.localOnly) {
          message += ' (local only)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: vAccentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        _clearAllProviders();

        // Reset the scheduler state
        ref.read(postSchedulerProvider.notifier).reset();

        if (mounted) {
          ref.read(navigationServiceProvider).navigateAfterPostSave(
                context,
                widget.editingDraft != null,
              );
        }
      } else {
        final schedulerState = ref.read(postSchedulerProvider);
        toast(
            "Error scheduling post: ${schedulerState.errorMessage ?? 'Unknown error'}");
      }
    } catch (e) {
      toast("Error scheduling post: $e");
    } finally {
      if (mounted) {
        setState(() => _isScheduling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postText = ref.watch(postTextProvider);
    final location = ref.watch(postLocationProvider);
    final snippet = _truncateText(postText, 30);
    final images = ref.watch(postImagesProvider);

    // Check Twitter connection status using the TwitterConnectionProvider directly
    final twitterConnectionState = ref.watch(twitterConnectionProvider);
    final isConnected = twitterConnectionState.connectionState ==
        TwitterConnectionState.connected;

    // If not connected, show a message
    if (!isConnected) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Icon(
                Icons.error_outline,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(
                'Twitter Account Not Connected',
                style: boldTextStyle(size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'You need to connect your Twitter account before you can schedule posts.',
                style: secondaryTextStyle(size: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to profile screen to connect Twitter
                  ref
                      .read(navigationServiceProvider)
                      .navigateToProfile(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Go to Profile to Connect'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          // Add Column with GestureDetector for drag-to-dismiss
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Draggable grab bar
              GestureDetector(
                onVerticalDragEnd: (details) {
                  // Check if the drag was upward or downward
                  if (details.primaryVelocity! > 0) {
                    // If the drag was downward, close the bottom sheet
                    ref.read(navigationServiceProvider).navigateBack(context);
                  }
                },
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 16, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // Rest of content in a scrollable container
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.schedule, color: vPrimaryColor, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            "Schedule Your Post",
                            style:
                                boldTextStyle(size: 20, color: vPrimaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Post Title input using elegant decoration
                      Container(
                        width: context.width(),
                        padding: const EdgeInsets.all(16),
                        decoration: vouseBoxDecoration(
                          backgroundColor: Colors.white,
                          radius: 16,
                          shadowOpacity: 15,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Post Title",
                              style:
                                  boldTextStyle(size: 14, color: vPrimaryColor),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: "Give your post a catchy title",
                                hintStyle: secondaryTextStyle(
                                    size: 14, color: vBodyGrey.withAlpha(180)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: vPrimaryColor.withAlpha(50)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: vPrimaryColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: vPrimaryColor.withAlpha(50)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Post snippet + location container
                      Container(
                        width: context.width(),
                        padding: const EdgeInsets.all(16),
                        decoration: vouseBoxDecoration(
                          backgroundColor: Colors.white,
                          radius: 16,
                          shadowOpacity: 15,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Post Content",
                              style:
                                  boldTextStyle(size: 14, color: vPrimaryColor),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                if (postText.isNotEmpty) {
                                  _showFullTextDialog(postText);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: vPrimaryColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: vPrimaryColor.withAlpha(40)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        snippet.isEmpty
                                            ? "No content yet"
                                            : snippet,
                                        style: primaryTextStyle(
                                          color: snippet.isEmpty
                                              ? vBodyGrey.withAlpha(150)
                                              : vBodyGrey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (postText.length > 30) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.more_horiz,
                                        color: vPrimaryColor,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (location != null) ...[
                              const SizedBox(height: 12),
                              LocationTagWidget(
                                entity: location,
                                onRemove: () {
                                  ref
                                      .read(postLocationProvider.notifier)
                                      .state = null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // "Who can reply?" container
                      Container(
                        width: context.width(),
                        padding: const EdgeInsets.all(16),
                        decoration: vouseBoxDecoration(
                          backgroundColor: Colors.white,
                          radius: 16,
                          shadowOpacity: 15,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Who can reply?",
                              style:
                                  boldTextStyle(size: 14, color: vPrimaryColor),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: vPrimaryColor.withAlpha(50)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedReplyOption,
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: vPrimaryColor,
                                  style: primaryTextStyle(),
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: vPrimaryColor),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedReplyOption =
                                          value ?? 'Everyone';
                                    });
                                  },
                                  items: _replyOptions.map((option) {
                                    return DropdownMenuItem<String>(
                                      value: option['label'],
                                      child: Row(
                                        children: [
                                          Icon(option['icon'],
                                              color: vPrimaryColor, size: 20),
                                          const SizedBox(width: 12),
                                          Text(option['label'],
                                              style: primaryTextStyle()),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selected images preview
                      if (images.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Selected Images (${images.length})",
                          style: boldTextStyle(size: 14, color: vPrimaryColor),
                        ),
                        const SizedBox(height: 8),
                        const SelectedImagesPreview(),
                      ],

                      const SizedBox(height: 24),

                      // Schedule options section
                      Container(
                        width: context.width(),
                        padding: const EdgeInsets.all(16),
                        decoration: vouseBoxDecoration(
                          backgroundColor: Colors.white,
                          radius: 16,
                          shadowOpacity: 15,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "When to Post",
                              style:
                                  boldTextStyle(size: 14, color: vPrimaryColor),
                            ),
                            const SizedBox(height: 16),

                            // Scheduling options in a row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Pick date button
                                ElevatedButton.icon(
                                  onPressed: _pickDateTime,
                                  icon: const Icon(Icons.calendar_today,
                                      size: 20, color: Colors.white),
                                  label: const Text("Pick Date"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: vPrimaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),

                                // Now button
                                ElevatedButton.icon(
                                  onPressed: _scheduleNow,
                                  icon: const Icon(Icons.bolt,
                                      size: 20, color: Colors.white),
                                  label: const Text("Now!"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: vPrimaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),

                                // AI suggestion button
                                ElevatedButton.icon(
                                  onPressed: _openAIDialog,
                                  icon: const Icon(Icons.auto_awesome,
                                      size: 20, color: Colors.white),
                                  label: const Text("AI"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: vPrimaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Display selected date/time
                            if (_scheduledDateTime != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: vPrimaryColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: vPrimaryColor.withAlpha(50)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.event, color: vPrimaryColor),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Scheduled for: ${DateFormat('EEEE, MMM d, y • h:mm a').format(_scheduledDateTime!)}",
                                        style: primaryTextStyle(
                                            color: vPrimaryColor),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close,
                                          color: vBodyGrey, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _scheduledDateTime = null;
                                        });
                                      },
                                      tooltip: "Clear date",
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // "Schedule Post" button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              vPrimaryColor,
                              vPrimaryColor.withAlpha(220)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: vPrimaryColor.withAlpha(100),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _onSchedulePressed,
                          icon: const Icon(
                            Icons.schedule,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Schedule Post",
                            style: boldTextStyle(color: Colors.white, size: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      // Bottom padding for safety
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Spinner overlay while scheduling
          BlockingSpinnerOverlay(isVisible: _isScheduling),
        ],
      ),
    );
  }
}

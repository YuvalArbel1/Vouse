import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:uuid/uuid.dart';

import '../../../core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import '../../../core/util/image_utils.dart';
import '../../../domain/entities/locaal db/post_entity.dart';
import '../../../domain/usecases/post/save_post_with_upload_usecase.dart';
import '../../providers/post/post_text_provider.dart';
import '../../providers/post/post_images_provider.dart';
import '../../providers/post/post_location_provider.dart';
import '../../providers/post/save_post_with_upload_provider.dart';
import '../../widgets/post/location_tag_widget.dart';
import '../../widgets/post/selected_images_preview.dart';
import 'schedule_ai_dialog.dart';

class SharePostBottomSheet extends ConsumerStatefulWidget {
  const SharePostBottomSheet({super.key});

  @override
  ConsumerState<SharePostBottomSheet> createState() =>
      _SharePostBottomSheetState();
}

class _SharePostBottomSheetState extends ConsumerState<SharePostBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _scheduledDateTime;
  bool _isScheduling = false;

  // Example who-can-reply options
  final List<Map<String, dynamic>> _replyOptions = [
    {'label': 'Everyone', 'icon': Icons.public},
    {'label': 'Verified accounts', 'icon': Icons.verified},
    {'label': 'Accounts you follow', 'icon': Icons.group},
  ];
  String _selectedReplyOption = 'Everyone';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// Utility method to truncate text for UI preview
  String _truncateText(String text, int limit) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  /// Show the user's full typed text in a scrollable dialog
  void _showFullTextDialog(String fullText) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Text(fullText, style: primaryTextStyle()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Let user pick date/time within next 7 days
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final oneWeekLater = now.add(const Duration(days: 7));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: oneWeekLater,
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      _scheduledDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _onSchedulePressed() async {
    // 1) If already scheduling, bail out
    if (_isScheduling) return;

    // 2) Mark scheduling = true, so we show a spinner overlay
    setState(() => _isScheduling = true);

    try {
      // 3) Grab user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        toast('No logged-in user found!');
        return;
      }

      // 4) Title must not be empty
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        toast('Please enter a post title!');
        return;
      }

      // 5) Must pick a date/time
      if (_scheduledDateTime == null) {
        toast('Please pick a date & time first!');
        return;
      }
      final scheduledDate = _scheduledDateTime!;

      // 6) The main post text
      final text = ref.read(postTextProvider).trim();
      if (text.isEmpty) {
        toast('Write some words first!');
        return;
      }

      // 7) Move images to permanent folder
      final images = ref.read(postImagesProvider);
      final localPaths = await ImageUtils.moveImagesToPermanentFolder(images);

      // 8) Build location
      final loc = ref.read(postLocationProvider);
      double? lat;
      double? lng;
      String? addr;
      if (loc != null) {
        lat = loc.latitude;
        lng = loc.longitude;
        addr = loc.address;
      }

      // 9) Create the post entity
      final postEntity = PostEntity(
        postIdLocal: const Uuid().v4(),
        postIdX: null,
        content: text,
        title: title,
        createdAt: DateTime.now(),
        updatedAt: null,
        scheduledAt: scheduledDate,
        visibility: _selectedReplyOption,
        // "Everyone" or the dropdown choice
        localImagePaths: localPaths,
        cloudImageUrls: [],
        locationLat: lat,
        locationLng: lng,
        locationAddress: addr,
      );

      // 10) Convert these localPaths to actual Files for upload
      final localFiles = localPaths.map((p) => File(p)).toList();

      // 11) Use the "save + upload" use case
      final savePostWithUploadUC = ref.read(savePostWithUploadUseCaseProvider);
      final result = await savePostWithUploadUC.call(
        params: SavePostWithUploadParams(
          userUid: user.uid,
          postEntity: postEntity,
          localImageFiles: localFiles,
        ),
      );

      // 12) Check result
      if (result is DataSuccess) {
        toast('Post scheduled successfully!');
        // Optionally clear everything
        ref.read(postTextProvider.notifier).state = '';
        ref.read(postImagesProvider.notifier).clearAll();
        ref.read(postLocationProvider.notifier).state = null;

        // Dismiss the bottom sheet
        Navigator.pop(context);
      } else if (result is DataFailed) {
        toast("Error saving scheduled post: ${result.error?.error}");
      }
    } finally {
      // 13) Turn off spinner
      setState(() => _isScheduling = false);
    }
  }

  /// Possibly open your AI text generation dialog
  Future<void> _openAIDialog() async {
    final bestTime = await showDialog<DateTime?>(
      context: context,
      builder: (_) => const ScheduleAiDialog(),
    );
    if (bestTime != null) {
      setState(() => _scheduledDateTime = bestTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postText = ref.watch(postTextProvider);
    final location = ref.watch(postLocationProvider);
    final snippet = _truncateText(postText, 30);

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// The small "grab bar" at the top of the sheet
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),

                /// Post Title input
                Container(
                  width: context.width(),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: vAppLayoutBackground,
                    borderRadius: radius(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "Give a title to your amazing post!",
                      hintStyle: secondaryTextStyle(size: 12, color: vBodyGrey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// Post snippet + location container
                Container(
                  width: context.width(),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: vAppLayoutBackground,
                    borderRadius: radius(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Truncated snippet of main text
                      GestureDetector(
                        onTap: () {
                          if (postText.length > 30) {
                            _showFullTextDialog(postText);
                          }
                        },
                        child: TextField(
                          enabled: false,
                          controller: TextEditingController(text: snippet),
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: "What's on your mind?",
                            border: InputBorder.none,
                          ),
                          style: primaryTextStyle(),
                        ),
                      ),
                      if (location != null) ...[
                        const SizedBox(height: 8),
                        LocationTagWidget(
                          entity: location,
                          onRemove: () {
                            ref.read(postLocationProvider.notifier).state =
                                null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                /// "Who can reply?" container
                Container(
                  width: context.width(),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: vAppLayoutBackground,
                    borderRadius: radius(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedReplyOption,
                      dropdownColor: vAppLayoutBackground,
                      iconEnabledColor: vPrimaryColor,
                      style: primaryTextStyle(),
                      onChanged: (value) {
                        setState(() {
                          _selectedReplyOption = value ?? 'Everyone';
                        });
                      },
                      items: _replyOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['label'],
                          child: Row(
                            children: [
                              Icon(option['icon'], color: vPrimaryColor),
                              const SizedBox(width: 8),
                              Text(option['label'], style: primaryTextStyle()),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// Images
                const SelectedImagesPreview(),
                const SizedBox(height: 16),

                /// Row: pick date/time & AI
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.calendar_today,
                          size: 16, color: Colors.white),
                      label: const Text("Pick Date"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vPrimaryColor.withAlpha(204),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: _openAIDialog,
                      icon: const Icon(Icons.auto_awesome),
                      color: vPrimaryColor,
                      tooltip: "Generate AI text",
                    ),
                  ],
                ),
                if (_scheduledDateTime != null) ...[
                  const SizedBox(height: 8),
                  Text("Scheduled for: $_scheduledDateTime",
                      style: primaryTextStyle(color: vPrimaryColor)),
                ],
                const SizedBox(height: 16),

                /// "Schedule Post" final button
                ElevatedButton(
                  onPressed: _onSchedulePressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(context.width(), 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: vPrimaryColor.withAlpha(204),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Schedule Post"),
                ),
              ],
            ),
          ),
          BlockingSpinnerOverlay(isVisible: _isScheduling),
        ],
      ),
    );
  }
}

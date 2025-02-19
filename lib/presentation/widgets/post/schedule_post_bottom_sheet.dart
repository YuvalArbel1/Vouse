import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_text_provider.dart';
import '../../providers/post/post_images_provider.dart';
import '../../providers/post/post_location_provider.dart';
import '../../widgets/post/selected_images_preview.dart';
import '../../widgets/post/location_tag_widget.dart';
import '../../widgets/post/ai_text_generation_dialog.dart';

class SharePostBottomSheet extends ConsumerStatefulWidget {
  const SharePostBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<SharePostBottomSheet> createState() =>
      _SharePostBottomSheetState();
}

class _SharePostBottomSheetState extends ConsumerState<SharePostBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _scheduledDateTime;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// Limit displayed text to 30 chars + '...'
  String _truncateText(String text, int limit) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  /// Show the full text in a dialog
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

  /// Pick date/time
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final oneWeekLater = now.add(const Duration(days: 7));

    // Pick Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: oneWeekLater,
    );
    if (pickedDate == null) return;

    // Pick Time
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

  /// Schedule post
  void _onSchedulePressed() {
    final title = _titleController.text.trim();
    final postBody = ref.read(postTextProvider);
    final date = _scheduledDateTime;

    // TODO: Implement scheduling logic
    Navigator.pop(context);
    toast('Post scheduled: $title at $date');
  }

  /// Open AI text generation dialog
  Future<void> _openAIDialog() async {
    await showDialog<String>(
      context: context,
      builder: (_) => const AiTextGenerationDialog(),
    );
    // AiTextNotifier updates postTextProvider automatically
  }

  @override
  Widget build(BuildContext context) {
    final postText = ref.watch(postTextProvider);
    final location = ref.watch(postLocationProvider);
    final snippet = _truncateText(postText, 30);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Grab Bar
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),

            /// Post Title container
            Container(
              width: context.width(),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: vAppLayoutBackground,
                borderRadius: radius(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: "Post Title (optional)",
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
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        ref.read(postLocationProvider.notifier).state = null;
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Selected Images
            const SelectedImagesPreview(),
            const SizedBox(height: 16),

            /// Row with Pick Date & AI in center
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text("Pick Date"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vPrimaryColor.withOpacity(0.8),
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

            // If date is chosen, show text below
            if (_scheduledDateTime != null) ...[
              const SizedBox(height: 8),
              Text(
                "Scheduled for: $_scheduledDateTime",
                style: primaryTextStyle(color: vPrimaryColor),
              ),
            ],

            const SizedBox(height: 16),

            /// Schedule Post button with semi-transparent color
            ElevatedButton(
              onPressed: _onSchedulePressed,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(context.width(), 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: vPrimaryColor.withOpacity(0.8), // <== OPACITY
                foregroundColor: Colors.white,
              ),
              child: const Text("Schedule Post"),
            ),
          ],
        ),
      ),
    );
  }
}

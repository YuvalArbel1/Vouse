import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/presentation/widgets/post/schedule_ai_dialog.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_text_provider.dart';
import '../../providers/post/post_location_provider.dart';
import '../../widgets/post/selected_images_preview.dart';
import '../../widgets/post/location_tag_widget.dart';

class SharePostBottomSheet extends ConsumerStatefulWidget {
  const SharePostBottomSheet({super.key});

  @override
  ConsumerState<SharePostBottomSheet> createState() =>
      _SharePostBottomSheetState();
}

class _SharePostBottomSheetState extends ConsumerState<SharePostBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _scheduledDateTime;

  /// Dropdown options for "Who can reply?"
  final List<Map<String, dynamic>> _replyOptions = [
    {'label': 'Everyone', 'icon': Icons.public},
    {'label': 'Verified accounts', 'icon': Icons.verified},
    {'label': 'Accounts you follow', 'icon': Icons.group},
  ];

  /// Holds the currently selected reply option
  String _selectedReplyOption = 'Everyone';

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

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: oneWeekLater,
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) return;

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
    final date = _scheduledDateTime;

    // If you have real scheduling logic, call it here
    Navigator.pop(context);
    toast('Post scheduled: $title at $date');
  }

  /// Open AI text generation dialog
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
                    color: Colors.black.withAlpha(20),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _titleController,
                style: secondaryTextStyle(size: 12, color: vBodyWhite),
                decoration: InputDecoration(
                  hintText: "Give a title to your amazing post!",
                  hintStyle: secondaryTextStyle(size: 12, color: vBodyWhite),
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

            /// Who can reply container (NEW)
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
              Text(
                "Scheduled for: $_scheduledDateTime",
                style: primaryTextStyle(color: vPrimaryColor),
              ),
            ],

            const SizedBox(height: 16),

            /// Schedule Post button
            ElevatedButton(
              onPressed: _onSchedulePressed,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(context.width(), 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: vPrimaryColor.withAlpha(204), // ~0.8
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../providers/ai/ai_text_notifier.dart';
import '../../providers/post/post_text_provider.dart';

/// A dialog that dims the background & integrates with AiTextNotifier
/// for real-time streaming text from Vertex AI.
/// The user:
/// - Types a prompt (up to 350 chars)
/// - Taps "Generate" => partial text is streamed
/// - "Regenerate" clears the text & restarts
/// - "Insert" sends final text back to parent
class AiTextGenerationDialog extends ConsumerStatefulWidget {
  const AiTextGenerationDialog({super.key});

  @override
  ConsumerState<AiTextGenerationDialog> createState() =>
      _AiTextGenerationDialogState();
}

class _AiTextGenerationDialogState
    extends ConsumerState<AiTextGenerationDialog> {
  final TextEditingController _promptController = TextEditingController();

  void _onGeneratePressed() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      toast("Please enter a prompt first!");
      return;
    }
    ref
        .read(aiTextNotifierProvider.notifier)
        .generateText(prompt, maxChars: 350);
  }

  void _onRegeneratePressed() {
    _promptController.clear();
    ref.read(aiTextNotifierProvider.notifier).resetState();
  }

  void _onInsertPressed() {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      toast("No AI text to insert!");
      return;
    }
    // 1) Update the postTextProvider so the main text field sees it
    ref.read(postTextProvider.notifier).state = text;

    // 2) Close only the dialog
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final aiState = ref.watch(aiTextNotifierProvider);
    final partialText = aiState.partialText;
    final isGenerating = aiState.isGenerating;
    final error = aiState.error;

    // If partial text changed => sync it into the text field
    if (partialText.isNotEmpty && partialText != _promptController.text) {
      _promptController.text = partialText;
      _promptController.selection = TextSelection.fromPosition(
        TextPosition(offset: partialText.length),
      );
    }

    return Container(
      width: context.width() * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // wrap content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("PostAI - Generate Text", style: boldTextStyle(size: 18)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Shorter label
            Text(
              "Describe your dream social media post:",
              style: secondaryTextStyle(size: 14),
            ),
            const SizedBox(height: 8),

            // Prompt text field
            AppTextField(
              controller: _promptController,
              textFieldType: TextFieldType.MULTILINE,
              maxLength: 350,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                filled: true,
                fillColor: vPrimaryColor.withOpacity(0.06),
                // Use a smaller style for the hint
                hintStyle: secondaryTextStyle(size: 13, color: Colors.grey),
                hintText:
                    "Try to be fully explanatory—use your imagination to create a viral post!",
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(width: 0, style: BorderStyle.none),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Show error if any
            if (error != null)
              Text("Error: $error",
                  style: primaryTextStyle(color: Colors.redAccent)),

            // If generating => spinner
            if (isGenerating) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 8),
                  Text("Generating AI text...", style: primaryTextStyle()),
                ],
              ),
            ] else
              _buildButtonRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(BuildContext context) {
    final currentText = _promptController.text.trim();
    if (currentText.isEmpty) {
      // If empty => "Generate"
      return AppButton(
        color: vPrimaryColor,
        text: "Generate",
        textColor: Colors.white,
        width: context.width(),
        shapeBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: _onGeneratePressed,
      );
    } else {
      // "Regenerate" & "Insert"
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppButton(
            color: Colors.green,
            text: "Regenerate",
            textColor: Colors.white,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: _onRegeneratePressed,
          ),
          AppButton(
            color: vPrimaryColor,
            text: "Insert",
            textColor: Colors.white,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: _onInsertPressed,
          ),
        ],
      );
    }
  }
}

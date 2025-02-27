// lib/presentation/widgets/post/ai_text_generation_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/util/colors.dart';
import '../../../providers/ai/ai_text_notifier.dart';
import '../../../providers/post/post_text_provider.dart';

/// A dialog widget that enables AI-based text generation for social media posts.
///
/// This dialog allows the user to:
/// 1. Enter a prompt describing the desired post content.
/// 2. Adjust creativity and length parameters.
/// 3. Generate AI text and optionally insert it into the current post.
///
/// The AI text is provided by [AiTextNotifier]. The generated text is stored in
/// [partialText], which is mirrored into [_promptController].
class AiTextGenerationDialog extends ConsumerStatefulWidget {
  /// Creates an [AiTextGenerationDialog].
  const AiTextGenerationDialog({super.key});

  @override
  ConsumerState<AiTextGenerationDialog> createState() =>
      _AiTextGenerationDialogState();
}

/// State class for [AiTextGenerationDialog].
///
/// Handles user interactions, manages the [TextEditingController] for the prompt,
/// and updates UI based on the AI generation state from [AiTextNotifier].
class _AiTextGenerationDialogState
    extends ConsumerState<AiTextGenerationDialog> {
  /// The controller for the prompt text field.
  final TextEditingController _promptController = TextEditingController();

  /// Ranges from 0..10, indicating how creative the AI output should be (0 = low, 10 = high).
  int _creativityInt = 5;

  /// Desired maximum length of the AI output, in characters (20..280).
  int _lengthInt = 150;

  /// Tracks whether the user has already generated text. Used to show "Regenerate" vs "Generate."
  bool _hasGenerated = false;

  /// Hides the keyboard, validates the prompt, and triggers AI text generation via [AiTextNotifier].
  ///
  /// Also sets [_hasGenerated] to `true` to switch the UI to "Regenerate & Insert."
  void _onGeneratePressed() {
    // Hide the keyboard.
    FocusScope.of(context).unfocus();

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      toast("Please enter a prompt first!");
      return;
    }

    setState(() => _hasGenerated = true);

    final temperature = _creativityInt / 10.0;
    final desiredChars = _lengthInt;

    // Generate AI text via the notifier.
    ref.read(aiTextNotifierProvider.notifier).generateText(prompt,
        desiredChars: desiredChars, temperature: temperature);
  }

  /// Resets the state to allow a new AI text generation.
  ///
  /// Clears the prompt, resets the AI state, and sets [_hasGenerated] to `false`.
  void _onRegeneratePressed() {
    _promptController.clear();
    ref.read(aiTextNotifierProvider.notifier).resetState();
    setState(() => _hasGenerated = false);
  }

  /// Inserts the current AI-generated text into [postTextProvider], if any.
  ///
  /// Closes the dialog after clearing the prompt and resetting the AI state.
  void _onInsertPressed() {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      toast("No AI text to insert!");
      return;
    }
    ref.read(postTextProvider.notifier).state = text;
    _promptController.clear();
    ref.read(aiTextNotifierProvider.notifier).resetState();
    Navigator.pop(context);
  }

  /// Returns a short descriptor for the current creativity value.
  ///
  /// - 0..3 => "(Low)"
  /// - 4..6 => "(Moderate)"
  /// - 7..10 => "(High)"
  String _describeCreativity(int val) {
    if (val <= 3) return "(Low)";
    if (val <= 6) return "(Moderate)";
    return "(High)";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  /// Builds the main dialog content with prompt input, sliders, and action buttons.
  ///
  /// This method reads the AI generation state from [AiTextNotifier] to display
  /// partial text, errors, or a loading indicator.
  Widget _buildDialogContent(BuildContext context) {
    final aiState = ref.watch(aiTextNotifierProvider);
    final partialText = aiState.partialText;
    final isGenerating = aiState.isGenerating;
    final error = aiState.error;

    // Update the prompt text if new partial text is provided by the AI.
    if (partialText.isNotEmpty && partialText != _promptController.text) {
      _promptController.text = partialText;
      _promptController.selection =
          TextSelection.fromPosition(TextPosition(offset: partialText.length));
    }

    return Container(
      width: context.width() * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            Text(
              "Describe your dream social media post:",
              style: secondaryTextStyle(size: 14),
            ),
            const SizedBox(height: 8),

            // Prompt text
            AppTextField(
              controller: _promptController,
              textFieldType: TextFieldType.MULTILINE,
              maxLength: 350,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                filled: true,
                fillColor: vPrimaryColor.withAlpha(15),
                hintStyle: secondaryTextStyle(size: 13, color: Colors.grey),
                hintText: "Try to be fully explanatory—use your imagination...",
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Creativity slider
            Text(
              "Creativity: $_creativityInt ${_describeCreativity(_creativityInt)}",
              style: secondaryTextStyle(),
            ),
            Slider(
              value: _creativityInt.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: "$_creativityInt",
              onChanged: (val) {
                setState(() {
                  _creativityInt = val.toInt();
                });
              },
            ),
            const SizedBox(height: 12),

            // Length slider
            Text("Desired Length: $_lengthInt chars",
                style: secondaryTextStyle()),
            Slider(
              value: _lengthInt.toDouble(),
              min: 20,
              max: 280,
              divisions: 260,
              label: "$_lengthInt",
              onChanged: (val) {
                setState(() {
                  _lengthInt = val.toInt();
                });
              },
            ),
            Text(
              "You can pick a short 20-char post or up to 280 chars.",
              style: secondaryTextStyle(size: 12),
            ),
            const SizedBox(height: 12),

            // Error or generating state
            if (error != null)
              Text(
                "Error: $error",
                style: primaryTextStyle(color: Colors.redAccent),
              ),

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

  /// Builds the row of action buttons, switching between "Generate" and
  /// "Regenerate / Insert" states based on [_hasGenerated].
  Widget _buildButtonRow(BuildContext context) {
    if (!_hasGenerated) {
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

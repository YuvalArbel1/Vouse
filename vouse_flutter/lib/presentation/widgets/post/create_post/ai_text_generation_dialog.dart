// lib/presentation/widgets/post/create_post/ai_text_generation_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:math' as math;

import '../../../../core/util/colors.dart';
import '../../../providers/ai/ai_text_notifier.dart';
import '../../../providers/post/post_text_provider.dart';
import '../../../providers/navigation/navigation_service.dart';

/// A dialog widget that enables AI-based text generation for social media posts.
///
/// This dialog allows the user to:
/// 1. Enter a prompt describing the desired post content.
/// 2. Select a content category to adapt the generation style.
/// 3. Adjust creativity and length parameters with enhanced controls.
/// 4. Generate AI text and optionally insert it into the current post.
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
class _AiTextGenerationDialogState extends ConsumerState<AiTextGenerationDialog>
    with SingleTickerProviderStateMixin {
  /// The controller for the prompt text field.
  final TextEditingController _promptController = TextEditingController();

  /// Animation controller for the loading indicator
  late AnimationController _animationController;

  /// Animation for the loading indicator
  late Animation<double> _animation;

  /// Ranges from 0..10, indicating how creative the AI output should be (0 = low, 10 = high).
  int _creativityInt = 5;

  /// Desired maximum length of the AI output, in characters (20..280).
  int _lengthInt = 150;

  /// The raw slider value for non-linear length mapping
  double _lengthSliderValue = 150;

  /// Tracks whether the user has already generated text. Used to show "Regenerate" vs "Generate."
  bool _hasGenerated = false;

  /// Selected prompt category (helps show examples and tailor generation)
  String _selectedCategory = 'General';

  /// List of prompt categories
  final List<String> _promptCategories = [
    'General',
    'Business',
    'Personal',
    'Promotional',
    'Announcement',
    'Question',
  ];

  @override
  void initState() {
    super.initState();

    // Set up animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Converts slider value to character count using a non-linear mapping
  /// to provide better precision for shorter posts.
  ///
  /// Ensures the full slider range (20-280) is utilized properly, with:
  /// - Minimum slider position (20) = 20 characters
  /// - Maximum slider position (280) = 280 characters
  /// - Values in between follow a non-linear curve for better control
  int _sliderValueToCharCount(double value) {
    // Define the slider and output ranges
    const double minSlider = 20.0;
    const double maxSlider = 280.0;
    const double minChars = 20.0;
    const double maxChars = 280.0;

    // Normalize value to 0-1 range
    final normalizedValue = (value - minSlider) / (maxSlider - minSlider);

    // Apply non-linear transformation (power curve)
    // Using power of 2 gives more precision for shorter text
    final curve = math.pow(normalizedValue, 2.0);

    // Convert back to character range
    final result = minChars + (curve * (maxChars - minChars));

    return result.round().clamp(minChars.toInt(), maxChars.toInt());
  }

  /// Hides the keyboard, validates the prompt, and triggers AI text generation via [AiTextNotifier].
  ///
  /// Also sets [_hasGenerated] to `true` to switch the UI to "Regenerate & Insert."
  /// Uses the selected category to tailor the generation.
  void _onGeneratePressed() {
    // Hide the keyboard.
    FocusScope.of(context).unfocus();

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      toast("Please enter a prompt first!");
      return;
    }

    // Create an enhanced prompt with category-specific guidance
    final enhancedPrompt = _getEnhancedPromptForCategory(_selectedCategory, prompt, _lengthInt);

    setState(() => _hasGenerated = true);

    final temperature = _creativityInt / 10.0;
    final desiredChars = _lengthInt;

    // Generate AI text via the notifier with the enhanced prompt
    ref.read(aiTextNotifierProvider.notifier).generateText(
      enhancedPrompt,
      desiredChars: desiredChars,
      temperature: temperature,
      category: _selectedCategory, // Pass category for optimization
    );
  }

  /// Creates a category-specific enhanced prompt with tailored instructions
  /// to guide the AI in generating appropriate content for each category.
  String _getEnhancedPromptForCategory(String category, String prompt, int length) {
    switch (category) {
      case 'Business':
        return """
Category: Business
Write a professional business update under $length characters.
Use formal language, focus on value proposition, include a clear call-to-action.
Avoid hyperbole and maintain a professional tone.

User request: $prompt
""";
      case 'Personal':
        return """
Category: Personal
Write a conversational personal post under $length characters.
Use first-person perspective, show personality, be authentic and relatable.
Include personal insights or feelings.

User request: $prompt
""";
      case 'Promotional':
        return """
Category: Promotional
Write a persuasive promotional post under $length characters.
Highlight benefits, create urgency, include a compelling call-to-action.
Use powerful, engaging language that inspires action.

User request: $prompt
""";
      case 'Announcement':
        return """
Category: Announcement
Write a clear announcement post under $length characters.
Include key details (what, when, where if applicable).
Be concise but informative, maintain appropriate tone for the announcement type.

User request: $prompt
""";
      case 'Question':
        return """
Category: Question
Write an engaging question post under $length characters.
Make it thought-provoking, designed to encourage responses.
Keep it open-ended where appropriate to maximize engagement.

User request: $prompt
""";
      case 'General':
      default:
        return """
Category: General
Write an engaging social media post under $length characters.
Balance information and engagement, use conversational tone.
Include appropriate hashtags or emojis if they enhance the message.

User request: $prompt
""";
    }
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
    ref.read(navigationServiceProvider).navigateBack(context);
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

  /// Returns a sample prompt based on the selected category
  String _getSamplePrompt() {
    switch (_selectedCategory) {
      case 'Business':
        return "Write a professional update about our new product launch next Tuesday. Mention improved features and benefits for customers.";
      case 'Personal':
        return "Share an inspiring story about overcoming a challenge at work and the lessons learned.";
      case 'Promotional':
        return "Create a promotional post about our summer sale with 30% off all items - emphasize limited time and exclusivity.";
      case 'Announcement':
        return "Announce our upcoming webinar on digital marketing trends happening next Thursday at 2 PM EST.";
      case 'Question':
        return "Ask an engaging question about people's favorite productivity tools that gets followers sharing their experiences.";
      case 'General':
      default:
        return "Write a thoughtful post about the importance of work-life balance and tips to achieve it.";
    }
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
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: vPrimaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(" AI Post Generator",
                        style: boldTextStyle(size: 18, color: vPrimaryColor)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      ref.read(navigationServiceProvider).navigateBack(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Prompt category selector
            Container(
              height: 50,
              padding: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _promptCategories.length,
                itemBuilder: (context, index) {
                  final category = _promptCategories[index];
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                      backgroundColor: Colors.grey.withAlpha(30),
                      selectedColor: vPrimaryColor.withAlpha(40),
                      labelStyle: TextStyle(
                        color: isSelected ? vPrimaryColor : Colors.grey,
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),

            Text(
              "Describe your ideal post in detail:",
              style: secondaryTextStyle(size: 14),
            ),
            const SizedBox(height: 8),

            // Helper text with example
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: vPrimaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: vPrimaryColor.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: vPrimaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Example: ${_getSamplePrompt()}",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: vBodyGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Prompt text
            AppTextField(
              controller: _promptController,
              textFieldType: TextFieldType.MULTILINE,
              maxLength: 350,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                filled: true,
                fillColor: vPrimaryColor.withAlpha(15),
                hintStyle: secondaryTextStyle(size: 13, color: Colors.grey),
                hintText: "Describe what you'd like to post about...",
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Creativity slider
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: vPrimaryColor.withAlpha(180),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Creativity: $_creativityInt ${_describeCreativity(_creativityInt)}",
                  style: secondaryTextStyle(),
                ),
              ],
            ),
            Slider(
              value: _creativityInt.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: vPrimaryColor,
              label: "$_creativityInt",
              onChanged: (val) {
                setState(() {
                  _creativityInt = val.toInt();
                });
              },
            ),
            const SizedBox(height: 8),

            // Length slider with non-linear mapping
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: vPrimaryColor.withAlpha(180),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Length: $_lengthInt characters",
                  style: secondaryTextStyle(),
                ),
              ],
            ),
            Slider(
              value: _lengthSliderValue,
              min: 20,
              max: 280,
              divisions: 26,
              activeColor: vPrimaryColor,
              label: "$_lengthInt",
              onChanged: (val) {
                final charCount = _sliderValueToCharCount(val);
                setState(() {
                  _lengthSliderValue = val;
                  _lengthInt = charCount;
                });
              },
            ),
            // Show character count visually
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: LinearProgressIndicator(
                value: _lengthInt / 280,
                backgroundColor: Colors.grey.withAlpha(30),
                color: _lengthInt > 240 ? Colors.orange : vPrimaryColor,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              "Twitter max length is 280 characters. Aim for 70-140 for best engagement.",
              style: secondaryTextStyle(size: 12),
            ),
            const SizedBox(height: 12),

            // Display error if any with improved styling
            if (error != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Error: $error",
                        style: primaryTextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),

            if (isGenerating) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    // Animated loading indicator
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: const [
                                vPrimaryColor,
                                Colors.transparent,
                              ],
                              stops: const [0.5, 1.0],
                              transform:
                              GradientRotation(_animation.value * 6.28),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: vPrimaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "AI is creating your ${_selectedCategory.toLowerCase()} post...",
                      style: primaryTextStyle(color: vPrimaryColor),
                    ),
                  ],
                ),
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
      return Container(
        margin: const EdgeInsets.only(top: 16),
        width: context.width(),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: Text("Generate", style: boldTextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: vPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _onGeneratePressed,
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Try Again"),
            style: OutlinedButton.styleFrom(
              foregroundColor: vPrimaryColor,
              side: const BorderSide(color: vPrimaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _onRegeneratePressed,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text("Use This Text"),
            style: ElevatedButton.styleFrom(
              backgroundColor: vAccentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _onInsertPressed,
          ),
        ],
      );
    }
  }
}
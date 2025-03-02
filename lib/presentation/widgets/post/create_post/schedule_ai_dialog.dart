// lib/presentation/widgets/post/create_post/schedule_ai_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/util/colors.dart';
import '../../../../core/util/common.dart';
import '../../../../domain/usecases/ai/predict_best_time_usecase.dart';
import '../../../providers/ai/ai_schedule_providers.dart';
import '../../../providers/post/post_location_provider.dart';
import '../../../../domain/entities/google_maps/place_location_entity.dart';
import '../../../screens/post/select_location_screen.dart';
import '../../../providers/navigation/navigation_service.dart';

/// A dialog that helps predict the best time to post, optionally including location or post text.
///
/// Users can:
/// - Enter a brief meta description (up to 50 characters).
/// - Toggle whether to include location and/or post text context.
/// - Click "Predict" to get an AI-suggested date/time.
/// - Accept ("Use") or close the suggestion.
class ScheduleAiDialog extends ConsumerStatefulWidget {
  /// Creates a [ScheduleAiDialog].
  const ScheduleAiDialog({super.key});

  @override
  ConsumerState<ScheduleAiDialog> createState() => _ScheduleAiDialogState();
}

class _ScheduleAiDialogState extends ConsumerState<ScheduleAiDialog>
    with SingleTickerProviderStateMixin {
  /// Controller for the meta text input.
  final TextEditingController _metaController = TextEditingController();

  /// Animation controller for loading effects
  late AnimationController _animationController;

  /// Animation for the loading indicator
  late Animation<double> _animation;

  /// Contextual toggles (by index):
  ///   0 -> "Add location"
  ///   1 -> "Add post text"
  final List<String> _contextOptions = [
    "Add location",
    "Add post text",
  ];

  /// Selected category for the meta prompt
  String _selectedCategory = 'General';

  /// List of meta prompt categories
  final List<String> _categories = [
    'General',
    'Business',
    'Personal',
    'Social',
  ];

  /// Tracks which context options are selected (by index).
  final Set<int> _selectedIndices = {};

  /// Indicates whether AI prediction is in progress.
  bool _isPredicting = false;

  /// Indicates whether a prediction has been successfully made.
  bool _hasPredicted = false;

  /// Holds an error message if AI prediction fails.
  String? _errorMessage;

  /// The AI-predicted date/time (if any).
  DateTime? _predictedDateTime;

  /// A temporary location chosen by the user for the AI context.
  /// Will be applied if "Use" is tapped.
  PlaceLocationEntity? _aiLocation;

  @override
  void initState() {
    super.initState();

    // Set up animation controller for loading effects
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
    _metaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Hides the keyboard and calls the AI prediction use case.
  ///
  /// The result is stored in [_predictedDateTime]. If an error occurs, [_errorMessage] is set.
  Future<void> _onPredictPressed() async {
    FocusScope.of(context).unfocus();
    final meta = _metaController.text.trim();
    if (meta.isEmpty) {
      toast("Please provide some meta data first!");
      return;
    }

    setState(() {
      _isPredicting = true;
      _hasPredicted = false;
      _errorMessage = null;
      _predictedDateTime = null;
    });

    try {
      final useCase = ref.read(predictBestTimeOneShotUseCaseProvider);
      final bool addLoc = _selectedIndices.contains(0);
      final bool addTxt = _selectedIndices.contains(1);

      final rawResult = await useCase.call(
        params: PredictBestTimeOneShotParams(
          meta: meta,
          addLocation: addLoc,
          addPostText: addTxt,
          temperature: 0.3,
        ),
      );

      final dt = _tryParseDateTime(rawResult);

      setState(() {
        _isPredicting = false;
        _hasPredicted = true;
        _predictedDateTime = dt;
      });
    } catch (e) {
      setState(() {
        _isPredicting = false;
        _hasPredicted = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Returns an example prompt based on the selected category
  String _getExampleForCategory() {
    switch (_selectedCategory) {
      case 'Business':
        return "Professional product update for business audience";
      case 'Personal':
        return "Casual life update for friends and family";
      case 'Social':
        return "Trending topic discussion for maximum engagement";
      case 'General':
      default:
        return "General post about current activities";
    }
  }

  /// Parses a date/time from a raw AI string formatted as "YYYY-MM-DD HH:mm".
  ///
  /// Returns a [DateTime] or `null` if parsing fails.
  DateTime? _tryParseDateTime(String raw) {
    try {
      final firstLine = raw.split('\n').first.trim();
      final isoString = firstLine.replaceFirst(' ', 'T');
      return DateTime.parse(isoString);
    } catch (_) {
      return null;
    }
  }

  /// Discards the AI suggestion and closes the dialog.
  void _onClosePressed() {
    ref.read(navigationServiceProvider).navigateBack(context);
  }

  /// Accepts the AI suggestion, applies any chosen location, and returns the predicted date/time.
  void _onUsePressed() {
    if (_aiLocation != null && _selectedIndices.contains(0)) {
      ref.read(postLocationProvider.notifier).state = _aiLocation;
    }
    Navigator.pop(context, _predictedDateTime);
  }

  /// Opens the [SelectLocationScreen] for the user to choose a new location.
  Future<void> _chooseNewLocation() async {
    final newLoc = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const SelectLocationScreen()),
    );
    if (newLoc == null) return;

    final locEntity = PlaceLocationEntity(
      latitude: newLoc.latitude,
      longitude: newLoc.longitude,
      address: null,
      name: null,
    );
    setState(() => _aiLocation = locEntity);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  /// Builds the main dialog content including meta input, toggles, and action buttons.
  Widget _buildDialogContent(BuildContext context) {
    return Container(
      width: context.width() * 0.9,
      padding: const EdgeInsets.all(16),
      // Use the common container decoration for consistency.
      decoration: vouseBoxDecoration(
        backgroundColor: context.cardColor,
        radius: 16,
        shadowOpacity: 60,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and close button with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: vPrimaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text("ScheduleAI - Best Time",
                        style: boldTextStyle(size: 18, color: vPrimaryColor)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Category selector similar to the AI text dialog
            Container(
              height: 50,
              padding: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
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
              "Describe your post type in a few words:",
              style: secondaryTextStyle(size: 14),
            ),
            const SizedBox(height: 8),

            // Example suggestion box
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
                      "Example: ${_getExampleForCategory()}",
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

            // Meta prompt input with improved styling
            AppTextField(
              controller: _metaController,
              maxLength: 50,
              textFieldType: TextFieldType.MULTILINE,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: vPrimaryColor.withAlpha(15),
                hintStyle: secondaryTextStyle(size: 13, color: Colors.grey),
                hintText: "Describe your post briefly...",
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Toggles row with improved styling
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Additional context:",
                  style: secondaryTextStyle(size: 14),
                ),
                const SizedBox(height: 8),
                _buildToggleRow(),
              ],
            ),
            const SizedBox(height: 16),

            // Display error if any with improved styling
            if (_errorMessage != null)
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
                        "Error: $_errorMessage",
                        style: primaryTextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),

            // Display loading spinner with animation, prediction result, or show "Predict" button.
            if (_isPredicting) ...[
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
                                  Icons.schedule,
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
                      "AI is finding the best time...",
                      style: primaryTextStyle(color: vPrimaryColor),
                    ),
                  ],
                ),
              ),
            ] else if (_hasPredicted) ...[
              const SizedBox(height: 16),
              // Result container with improved styling
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: vPrimaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: vPrimaryColor.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _predictedDateTime == null
                              ? Icons.error_outline
                              : Icons.check_circle,
                          color: _predictedDateTime == null
                              ? Colors.red
                              : vAccentColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _predictedDateTime == null
                                ? "No optimal time found!"
                                : "AI suggests:",
                            style: boldTextStyle(
                              color: _predictedDateTime == null
                                  ? Colors.red
                                  : vPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_predictedDateTime != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _predictedDateTime!
                                .toLocal()
                                .toString()
                                .substring(0, 16),
                            style: boldTextStyle(size: 18, color: vAccentColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons with improved styling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Close"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: vPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      side: const BorderSide(color: vPrimaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _onClosePressed,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Use This Time"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vAccentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _predictedDateTime == null ? null : _onUsePressed,
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 20),
              // Predict button with improved styling
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [vPrimaryColor, vPrimaryColor.withAlpha(220)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: vPrimaryColor.withAlpha(50),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text("Find Best Time",
                      style: boldTextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _onPredictPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a row of toggle buttons based on [_contextOptions] with improved styling.
  Widget _buildToggleRow() {
    return Row(
      children: List.generate(_contextOptions.length, (index) {
        final label = _contextOptions[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index > 0 ? 12 : 0),
            child: _buildToggleButton(index, label),
          ),
        );
      }),
    );
  }

  /// Builds an individual toggle button with the given [index] and [label].
  ///
  /// If "Add location" is toggled on and there's no existing location in [postLocationProvider],
  /// prompts the user to pick a new location or reuse the existing one.
  Widget _buildToggleButton(int index, String label) {
    final isSelected = _selectedIndices.contains(index);
    final IconData iconData =
        index == 0 ? Icons.location_on : Icons.text_fields;

    return GestureDetector(
      onTap: () async {
        if (label == "Add location" && !isSelected) {
          final mainLoc = ref.read(postLocationProvider);
          if (mainLoc == null) {
            await _chooseNewLocation();
          } else {
            final result = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Location already chosen"),
                content: const Text(
                    "Do you want to use the existing location or choose a new one?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, "useExisting"),
                    child: const Text("Use Existing"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, "chooseNew"),
                    child: const Text("Choose New"),
                  ),
                ],
              ),
            );
            if (result == "useExisting") {
              setState(() => _aiLocation = mainLoc);
            } else if (result == "chooseNew") {
              await _chooseNewLocation();
            }
          }
        }

        setState(() {
          if (isSelected) {
            _selectedIndices.remove(index);
            if (index == 0) _aiLocation = null;
          } else {
            _selectedIndices.add(index);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? vPrimaryColor : vPrimaryColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: vPrimaryColor.withAlpha(40),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 16,
              color: isSelected ? Colors.white : vPrimaryColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: isSelected
                    ? boldTextStyle(color: Colors.white, size: 12)
                    : primaryTextStyle(color: vPrimaryColor, size: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

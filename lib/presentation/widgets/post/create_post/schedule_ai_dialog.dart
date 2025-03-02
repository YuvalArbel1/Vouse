// lib/presentation/widgets/post/schedule_ai_dialog.dart

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

class _ScheduleAiDialogState extends ConsumerState<ScheduleAiDialog> {
  /// Controller for the meta text input.
  final TextEditingController _metaController = TextEditingController();

  /// Contextual toggles (by index):
  ///   0 -> "Add location"
  ///   1 -> "Add post text"
  final List<String> _contextOptions = [
    "Add location",
    "Add post text",
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
  void dispose() {
    _metaController.dispose();
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
            // Title and close button.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ScheduleAI - Predict Post Time",
                    style: boldTextStyle(size: 16)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Provide up to 50 characters describing your post. "
              "Optionally include location or post text. We'll suggest the best time to post.",
              style: secondaryTextStyle(size: 14),
            ),
            const SizedBox(height: 12),
            // Meta prompt input.
            AppTextField(
              controller: _metaController,
              maxLength: 50,
              textFieldType: TextFieldType.MULTILINE,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: vPrimaryColor.withAlpha(20),
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
            // Toggles row.
            _buildToggleRow(),
            const SizedBox(height: 16),
            // Display error if any.
            if (_errorMessage != null)
              Text(
                "Error: $_errorMessage",
                style: primaryTextStyle(color: Colors.redAccent),
              ),
            // Display loading spinner or prediction result, or show "Predict" button.
            if (_isPredicting) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 8),
                  Text("Predicting best date/time...",
                      style: primaryTextStyle()),
                ],
              ),
            ] else if (_hasPredicted) ...[
              const SizedBox(height: 8),
              Text(
                _predictedDateTime == null
                    ? "No date/time found!"
                    : "AI suggests: $_predictedDateTime",
                style: primaryTextStyle(color: vPrimaryColor),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton(
                    color: vAccentColor.withAlpha(240),
                    text: "Close",
                    textColor: Colors.white,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: _onClosePressed,
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    color: vPrimaryColor.withAlpha(240),
                    text: "Use",
                    textColor: Colors.white,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: _onUsePressed,
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              AppButton(
                color: vPrimaryColor,
                text: "Predict",
                textColor: Colors.white,
                width: context.width(),
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: _onPredictPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a row of toggle buttons based on [_contextOptions].
  Widget _buildToggleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_contextOptions.length, (index) {
        final label = _contextOptions[index];
        return Padding(
          padding: EdgeInsets.only(left: index > 0 ? 12 : 0),
          child: _buildToggleButton(index, label),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? vPrimaryColor.withAlpha(240)
              : vPrimaryColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: isSelected
              ? boldTextStyle(color: Colors.white)
              : primaryTextStyle(color: vPrimaryColor),
        ),
      ),
    );
  }
}

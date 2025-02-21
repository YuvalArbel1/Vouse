import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../../domain/usecases/ai/predict_best_time_usecase.dart';
import '../../providers/ai/ai_schedule_providers.dart';
import '../../providers/post/post_location_provider.dart';
import '../../../domain/entities/google_maps/place_location_entity.dart';
import '../../screens/post/select_location_screen.dart';

class ScheduleAiDialog extends ConsumerStatefulWidget {
  const ScheduleAiDialog({super.key});

  @override
  ConsumerState<ScheduleAiDialog> createState() => _ScheduleAiDialogState();
}

class _ScheduleAiDialogState extends ConsumerState<ScheduleAiDialog> {
  final TextEditingController _metaController = TextEditingController();

  final List<String> _contextOptions = [
    "Add location",
    "Add post text",
  ];
  final Set<int> _selectedIndices = {};

  bool _isPredicting = false;
  bool _hasPredicted = false;
  String? _errorMessage;
  DateTime? _predictedDateTime;

  PlaceLocationEntity? _aiLocation; // local location if user picks new

  @override
  void dispose() {
    _metaController.dispose();
    super.dispose();
  }

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
          temperature: 0.3, // or whatever you want
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

  /// Handle newlines or disclaimers; parse "YYYY-MM-DD HH:mm" => DateTime
  DateTime? _tryParseDateTime(String raw) {
    try {
      final firstLine = raw.split('\n').first.trim();
      final isoString = firstLine.replaceFirst(' ', 'T');
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  /// If user wants to discard the AI suggestion, simply close the dialog
  void _onClosePressed() {
    Navigator.pop(context); // No result returned
  }

  /// If user is satisfied => apply location, return the final date/time
  void _onUsePressed() {

    Navigator.pop(context, _predictedDateTime);
  }

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

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      width: context.width() * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
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
            /// Title + close
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

            // Meta prompt
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

            // Toggles row
            _buildToggleRow(),
            const SizedBox(height: 16),

            // Error if any
            if (_errorMessage != null)
              Text("Error: $_errorMessage",
                  style: primaryTextStyle(color: Colors.redAccent)),

            // If predicting => spinner
            if (_isPredicting) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 8),
                  Text("Predicting best date/time...", style: primaryTextStyle()),
                ],
              ),
            ]
            // If result is in
            else if (_hasPredicted) ...[
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
                  // Replaced "Regenerate" => "Close"
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
            ]
            // Otherwise => "Predict"
            else ...[
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

  Widget _buildToggleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton(0, "Add location"),
        const SizedBox(width: 12),
        _buildToggleButton(1, "Add post text"),
      ],
    );
  }

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
          color: isSelected ? vPrimaryColor.withAlpha(240) : vPrimaryColor.withAlpha(20),
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

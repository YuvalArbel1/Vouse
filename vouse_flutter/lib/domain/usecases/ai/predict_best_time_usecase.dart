// lib/domain/usecases/ai/predict_best_time_usecase.dart

import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_schedule_repository.dart';

/// Parameters for predicting the best time to post on X (Twitter).
class PredictBestTimeOneShotParams {
  /// A prompt or description providing context for the AI.
  final String meta;

  /// Whether to include location in the AI prompt.
  final bool addLocation;

  /// Whether to include current post text in the AI prompt.
  final bool addPostText;

  /// Controls AI creativity, from 0.0 to 1.0.
  final double temperature;

  /// Creates parameters with defaults for toggles and a default [temperature].
  PredictBestTimeOneShotParams({
    required this.meta,
    this.addLocation = false,
    this.addPostText = false,
    this.temperature = 0.5,
  });
}

/// A [UseCase] that returns a single date/time string for optimal post scheduling.
///
/// Relies on [AiScheduleRepository] to generate a best post time from the AI model.
class PredictBestTimeOneShotUseCase
    extends UseCase<String, PredictBestTimeOneShotParams> {
  final AiScheduleRepository _repo;

  PredictBestTimeOneShotUseCase(this._repo);

  @override
  Future<String> call({PredictBestTimeOneShotParams? params}) {
    final p = params!;
    return _repo.predictBestTimeOneShot(
      metaPrompt: p.meta,
      addLocation: p.addLocation,
      addPostText: p.addPostText,
      temperature: p.temperature,
    );
  }
}

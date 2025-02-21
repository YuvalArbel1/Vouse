// domain/usecases/ai/predict_best_time_one_shot_usecase.dart

import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_schedule_repository.dart';

class PredictBestTimeOneShotParams {
  final String meta;
  final bool addLocation;
  final bool addPostText;
  final double temperature;

  PredictBestTimeOneShotParams({
    required this.meta,
    this.addLocation = false,
    this.addPostText = false,
    this.temperature = 0.5,
  });
}

class PredictBestTimeOneShotUseCase extends UseCase<String, PredictBestTimeOneShotParams> {
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

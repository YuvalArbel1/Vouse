// lib/domain/usecases/ai/generate_text_usecase.dart

import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';

/// Holds the user's prompt, desired character length, and temperature.
class GenerateTextParams {
  final String prompt;
  final int desiredChars;   // e.g., 20..280
  final double temperature; // 0..1
  // Optionally keep maxChars if needed.

  GenerateTextParams(
      this.prompt, {
        this.desiredChars = 150,
        this.temperature = 0.5,
      });
}

/// A use case that returns a Stream<String> of partial text.
class GenerateTextUseCase extends UseCase<Stream<String>, GenerateTextParams> {
  final AiTextRepository _repo;

  GenerateTextUseCase(this._repo);

  @override
  Future<Stream<String>> call({GenerateTextParams? params}) async {
    final p = params!;
    return _repo.generateTextStream(
      prompt: p.prompt,
      desiredChars: p.desiredChars,
      temperature: p.temperature,
    );
  }
}

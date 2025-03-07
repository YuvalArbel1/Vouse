// lib/domain/usecases/ai/generate_text_usecase.dart

import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';

/// Holds the user's [prompt], approximate [desiredChars], a [temperature]
/// value controlling creativity (0.0 => deterministic, 1.0 => highly creative),
/// and the content [category] for category-aware text generation.
class GenerateTextParams {
  final String prompt;
  final int desiredChars;
  final double temperature;
  final String category; // Added category parameter

  /// Creates parameters for generating text, with a default
  /// [desiredChars] of 150, [temperature] of 0.5, and [category] of 'General'.
  GenerateTextParams(
    this.prompt, {
    this.desiredChars = 150,
    this.temperature = 0.5,
    this.category = 'General',
  });
}

/// A [UseCase] that returns a `Stream<String>` of partial AI-generated text.
///
/// Uses [AiTextRepository] to produce text in real-time based on [GenerateTextParams].
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
      category: p.category,
    );
  }
}

// lib/domain/usecases/ai/generate_text_usecase.dart

import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';

class GenerateTextParams {
  final String prompt;
  final int maxChars;

  GenerateTextParams(this.prompt, {this.maxChars = 350});
}

class GenerateTextUseCase extends UseCase<Stream<String>, GenerateTextParams> {
  final AiTextRepository _repo;

  GenerateTextUseCase(this._repo);

  @override
  Future<Stream<String>> call({GenerateTextParams? params}) async {
    final p = params!;
    return _repo.generateTextStream(
      prompt: p.prompt,
      maxChars: p.maxChars,
    );
  }
}

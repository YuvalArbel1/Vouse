// lib/domain/repository/ai/ai_text_repository.dart

abstract class AiTextRepository {
  /// Streams partial text from Vertex AI with the given [prompt],
  /// approximate [desiredChars], and [temperature].
  Stream<String> generateTextStream({
    required String prompt,
    required int desiredChars,
    required double temperature,
  });
}

// lib/domain/repository/ai/ai_text_repository.dart

abstract class AiTextRepository {
  /// Streams partial text from Vertex AI for the given prompt.
  /// The final text aims to stay under 350 chars.
  Stream<String> generateTextStream({
    required String prompt,
    int maxChars = 350,
  });
}

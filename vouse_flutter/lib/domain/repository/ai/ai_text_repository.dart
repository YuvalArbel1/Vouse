// lib/domain/repository/ai/ai_text_repository.dart

/// Describes a contract for AI-driven text generation,
/// streaming partial outputs as they're produced.
abstract class AiTextRepository {
  /// Streams incremental text based on [prompt], aiming for [desiredChars]
  /// characters of output, influenced by [temperature] for creativity,
  /// and adjusted for content [category].
  ///
  /// Returns a continuous [Stream] of partial text updates.
  Stream<String> generateTextStream({
    required String prompt,
    required int desiredChars,
    required double temperature,
    String category = 'General',
  });
}
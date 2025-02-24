// lib/domain/repository/ai/ai_schedule_repository.dart

/// Describes a contract for predicting the best time to post on X (Twitter).
abstract class AiScheduleRepository {
  /// Predicts a single date/time string within the next 7 days,
  /// based on [metaPrompt] and optionally adding location/post text context.
  ///
  /// - [addLocation] indicates whether to incorporate location data.
  /// - [addPostText] indicates whether to incorporate the current post text.
  /// - [temperature] controls the AI's creativity.
  ///
  /// Returns an ISO8601-style timestamp string: "YYYY-MM-DD HH:mm".
  Future<String> predictBestTimeOneShot({
    required String metaPrompt,
    required bool addLocation,
    required bool addPostText,
    required double temperature,
  });
}

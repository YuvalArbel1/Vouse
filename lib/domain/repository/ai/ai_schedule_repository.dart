// domain/repository/ai/ai_schedule_repository.dart
abstract class AiScheduleRepository {
  /// Returns a single date/time string from the model.
  Future<String> predictBestTimeOneShot({
    required String metaPrompt,
    required bool addLocation,
    required bool addPostText,
    required double temperature,
  });
}

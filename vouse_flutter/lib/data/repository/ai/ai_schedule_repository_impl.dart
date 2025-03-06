// lib/data/repository/ai/ai_schedule_repository_impl.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/data/clients/vertex_ai/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_schedule_repository.dart';
import 'package:vouse_flutter/presentation/providers/post/post_location_provider.dart';
import 'package:vouse_flutter/presentation/providers/post/post_text_provider.dart';
import 'package:intl/intl.dart';

/// An implementation of [AiScheduleRepository] that determines the best time
/// to post on X (Twitter) using a Vertex AI model.
///
/// Leverages the current [postLocationProvider] and [postTextProvider] for optional
/// location and text context, and formats a prompt to predict a single date/time
/// within the next 7 days.
class AiScheduleRepositoryImpl implements AiScheduleRepository {
  final FirebaseVertexAiClient _client;
  final Ref _ref;

  /// Requires a [FirebaseVertexAiClient] for AI calls and a [Ref] to read
  /// location/text providers.
  AiScheduleRepositoryImpl(this._client, this._ref);

  @override
  Future<String> predictBestTimeOneShot({
    required String metaPrompt,
    required bool addLocation,
    required bool addPostText,
    required double temperature,
  }) async {
    // 1) Potentially read location & text from providers
    final location = _ref.read(postLocationProvider);
    final postText = _ref.read(postTextProvider).trim();

    // 2) Compute date/time bounds: now & one week from now
    final now = DateTime.now();
    final oneWeekLater = now.add(const Duration(days: 7));

    // 3) Format them
    final nowStr = _formatForAi(now);
    final endStr = _formatForAi(oneWeekLater);

    // 4) Build the AI prompt
    final sb = StringBuffer();
    sb.writeln(
        "You are an AI returning only one date/time between now and 7 days "
        "from now for best X engagement base on network traffic and X users metrics.");
    sb.writeln(
        "Today's date/time is $nowStr. The latest possible date/time is $endStr.");
    sb.writeln(
        "You must pick a final date/time strictly between $nowStr and $endStr, "
        "in 'YYYY-MM-DD HH:mm' (24-hour) format. No disclaimers.\n");

    sb.writeln("Meta / Context: $metaPrompt");

    if (addLocation && location != null) {
      final lat = location.latitude.toStringAsFixed(5);
      final lng = location.longitude.toStringAsFixed(5);
      sb.writeln("Location lat=$lat, lng=$lng.");
      if (location.address != null && location.address!.isNotEmpty) {
        sb.writeln("Address: ${location.address}");
      }
    }

    if (addPostText && postText.isNotEmpty) {
      sb.writeln("Post text: $postText");
    }

    final finalPrompt = sb.toString();

    // 5) Call Vertex AI with the built prompt
    return _client.predictOneShot(
      prompt: finalPrompt,
      maxOutputTokens: 60,
      temperature: temperature,
    );
  }

  /// Formats [dt] in "YYYY-MM-DD HH:mm" for the AI prompt.
  String _formatForAi(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }
}

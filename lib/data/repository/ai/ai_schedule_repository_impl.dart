// data/repository/ai/ai_schedule_repository_impl.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/data/clients/vertex_ai/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_schedule_repository.dart';
import 'package:vouse_flutter/presentation/providers/post/post_location_provider.dart';
import 'package:vouse_flutter/presentation/providers/post/post_text_provider.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';

class AiScheduleRepositoryImpl implements AiScheduleRepository {
  final FirebaseVertexAiClient _client;
  final Ref _ref;

  AiScheduleRepositoryImpl(this._client, this._ref);

  @override
  Future<String> predictBestTimeOneShot({
    required String metaPrompt,
    required bool addLocation,
    required bool addPostText,
    required double temperature,
  }) async {
    // 1) Check toggles & read providers
    final location = _ref.read(postLocationProvider);
    final postText = _ref.read(postTextProvider).trim();

    // 2) Build a short prompt
    // You instruct AI: "Output only one date/time in 'YYYY-MM-DD HH:mm' within 7 days."
    final sb = StringBuffer();
    sb.writeln("You are an AI returning only one date/time within the next 7 days for best Twitter engagement.");
    sb.writeln("Format: 'YYYY-MM-DD HH:mm' (24-hour). No disclaimers.\n");
    sb.writeln("Context: $metaPrompt");

    if (addLocation && location != null) {
      sb.writeln("Location lat=${location.latitude}, lng=${location.longitude}, Location addres=${location.address}.");
    }
    if (addPostText && postText.isNotEmpty) {
      sb.writeln("Post text: $postText");
    }

    final finalPrompt = sb.toString();

    // 3) One-shot call
    final result = await _client.predictOneShot(
      prompt: finalPrompt,
      maxOutputTokens: 40, // enough for short date/time
      temperature: temperature,
    );
    return result;
  }
}

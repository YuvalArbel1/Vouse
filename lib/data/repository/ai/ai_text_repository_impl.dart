// lib/data/repository/ai/ai_text_repository_impl.dart

import 'dart:async';
import 'package:vouse_flutter/data/clients/vertex_ai/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';

class AiTextRepositoryImpl implements AiTextRepository {
  final FirebaseVertexAiClient _client;

  AiTextRepositoryImpl(this._client);

  @override
  Stream<String> generateTextStream({
    required String prompt,
    required int desiredChars,
    required double temperature,
  }) {
    // Convert desiredChars => approximate tokens
    final approxTokens = (desiredChars / 4).round();
    // e.g. ±20%
    final minTokens = (approxTokens * 0.8).round();
    final maxTokens = (approxTokens * 1.2).round();

    // But keep a floor/ceiling so it never goes below 1 or above 280, etc.
    final finalMin = minTokens.clamp(1, 280);
    final finalMax = maxTokens.clamp(1, 280);

    return _client.generateTextStream(
      prompt: prompt,
      minTokens: finalMin,
      maxTokens: finalMax,
      temperature: temperature,
    );
  }
}

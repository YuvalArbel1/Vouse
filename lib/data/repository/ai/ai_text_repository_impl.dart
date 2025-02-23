// lib/data/repository/ai/ai_text_repository_impl.dart

import 'dart:async';
import 'package:vouse_flutter/data/clients/vertex_ai/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';

/// Implements [AiTextRepository] by calling a [FirebaseVertexAiClient].
///
/// Converts [desiredChars] to approximate token bounds for the AI generation.
class AiTextRepositoryImpl implements AiTextRepository {
  final FirebaseVertexAiClient _client;

  /// Requires a [FirebaseVertexAiClient] to generate text via Vertex AI.
  AiTextRepositoryImpl(this._client);

  @override
  Stream<String> generateTextStream({
    required String prompt,
    required int desiredChars,
    required double temperature,
  }) {
    // Approximate tokens from desired character count (~4 chars per token).
    final approxTokens = (desiredChars / 4).round();

    // Provide ±20% leeway around approxTokens.
    final minTokens = (approxTokens * 0.8).round();
    final maxTokens = (approxTokens * 1.2).round();

    // Ensure tokens are at least 1 and at most 280.
    final finalMin = minTokens.clamp(1, 280);
    final finalMax = maxTokens.clamp(1, 280);

    // Call the client stream method with the computed bounds.
    return _client.generateTextStream(
      prompt: prompt,
      minTokens: finalMin,
      maxTokens: finalMax,
      temperature: temperature,
    );
  }
}

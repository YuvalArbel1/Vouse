// lib/data/repository/ai/ai_text_repository_impl.dart

import 'dart:async';
import 'package:vouse_flutter/data/clients/vertex_ai/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';

/// Implements [AiTextRepository] by calling a [FirebaseVertexAiClient].
///
/// Converts [desiredChars] to approximate token bounds for the AI generation,
/// with category-aware adjustments for better output quality.
class AiTextRepositoryImpl implements AiTextRepository {
  final FirebaseVertexAiClient _client;

  /// Requires a [FirebaseVertexAiClient] to generate text via Vertex AI.
  AiTextRepositoryImpl(this._client);

  @override
  Stream<String> generateTextStream({
    required String prompt,
    required int desiredChars,
    required double temperature,
    String category = 'General', // New parameter with default value
  }) {
    // Set max chars to 280 for Twitter limit
    final maxChars = 280;

    // If desired chars is more than Twitter limit, cap it
    final targetChars = desiredChars > maxChars ? maxChars : desiredChars;

    // Category-aware token ratio
    final tokenRatio = _getTokenRatio(category);

    // Approximate tokens with category-specific ratio
    final approxTokens = (targetChars / tokenRatio).round();

    // Provide more flexibility with wider token range
    final minTokens = (approxTokens * 0.7).round();
    final maxTokens = (approxTokens * 1.3).round();

    // Ensure tokens are reasonable (1-100)
    final finalMin = minTokens.clamp(1, 100);
    final finalMax = maxTokens.clamp(1, 100);

    // Call the client stream method with the computed bounds
    return _client.generateTextStream(
      prompt: prompt,
      minTokens: finalMin,
      maxTokens: finalMax,
      temperature: temperature,
    );
  }

  /// Returns a token-to-character ratio specific to the content category.
  ///
  /// Different content types typically have different word lengths and
  /// vocabulary distributions, affecting the average characters per token.
  ///
  /// - Business text: Longer words, more formal vocabulary (4.5 chars/token)
  /// - Promotional: Marketing terms, calls to action (4.2 chars/token)
  /// - Questions: Shorter words, interrogatives (3.5 chars/token)
  /// - Others: Standard conversational text (4.0 chars/token)
  double _getTokenRatio(String category) {
    switch (category) {
      case 'Business':
        return 4.5; // Business text often has longer words
      case 'Promotional':
        return 4.2; // Promotional content has medium-length specialized terms
      case 'Question':
        return 3.5; // Questions tend to have shorter words
      default:
        return 4.0; // Default ratio for general content
    }
  }
}
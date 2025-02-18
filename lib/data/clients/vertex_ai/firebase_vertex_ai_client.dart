// lib/data/clients/vertex_ai/firebase_vertex_ai_client.dart

import 'dart:async';
import 'package:firebase_vertexai/firebase_vertexai.dart';

/// A client that configures a generative model with a systemInstruction.
/// We embed token constraints in the user prompt for min length,
/// and use `maxOutputTokens` for the upper bound.
class FirebaseVertexAiClient {
  final String modelId;
  final Content systemInstruction;

  /// We store the model in a generic variable instead of a specific class
  late final dynamic _model;

  FirebaseVertexAiClient({
    this.modelId = 'gemini-2.0-flash',
    required this.systemInstruction,
  }) {
    // Initialize the generative model once with system instructions
    _model = FirebaseVertexAI.instance.generativeModel(
      model: modelId,
      systemInstruction: systemInstruction,
    );
  }

  /// Streams partial text, specifying approximate min tokens in the user prompt,
  /// and using maxOutputTokens for the upper bound.
  /// Temperature for creativity.
  Stream<String> generateTextStream({
    required String prompt,
    required int minTokens,
    required int maxTokens,
    required double temperature,
  }) async* {
    // Combine the user prompt with a note about minTokens
    // (since the plugin doesn't have minOutputTokens).
    final userPrompt = """
Write a social media post under $maxTokens tokens (~${maxTokens * 4} chars), 
but at least $minTokens tokens (~${minTokens * 4} chars). 
Only final text, no disclaimers.

$prompt
""";

    // We pass this userPrompt in addition to the system instruction
    // that's already part of `_model`.
    final promptList = [Content.text(userPrompt)];

    final responseStream = _model.generateContentStream(
      promptList,
      generationConfig: GenerationConfig(
        maxOutputTokens: maxTokens,
        temperature: temperature,
        // topK, topP, presencePenalty, frequencyPenalty, etc. if needed
      ),
    );

    final buffer = StringBuffer();
    await for (final chunk in responseStream) {
      buffer.write(chunk.text);
      yield buffer.toString();
    }
  }
}

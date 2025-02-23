// lib/data/clients/vertex_ai/firebase_vertex_ai_client.dart

import 'dart:async';
import 'package:firebase_vertexai/firebase_vertexai.dart';

/// Configures a generative Vertex AI model with a system instruction
/// and provides methods for streaming or one-shot text generation.
class FirebaseVertexAiClient {
  final String modelId;
  final Content systemInstruction;
  late final dynamic _model;

  /// Creates a client that uses [modelId] and [systemInstruction] for Vertex AI.
  /// Defaults to model 'gemini-2.0-flash'.
  FirebaseVertexAiClient({
    this.modelId = 'gemini-2.0-flash',
    required this.systemInstruction,
  }) {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: modelId,
      systemInstruction: systemInstruction,
    );
  }

  /// Streams partial text from the model, merging [prompt] with token constraints.
  ///
  /// - [minTokens] roughly sets a lower bound by embedding it in the user prompt.
  /// - [maxTokens] is used in [GenerationConfig].
  /// - [temperature] controls creativity.
  ///
  /// Yields incremental text chunks until the stream finishes.
  Stream<String> generateTextStream({
    required String prompt,
    required int minTokens,
    required int maxTokens,
    required double temperature,
  }) async* {
    final userPrompt = """
Write a social media post under $maxTokens tokens (~${maxTokens * 4} chars), 
but at least $minTokens tokens (~${minTokens * 4} chars). 
Only final text, no disclaimers.

$prompt
""";

    final promptList = [Content.text(userPrompt)];

    final responseStream = _model.generateContentStream(
      promptList,
      generationConfig: GenerationConfig(
        maxOutputTokens: maxTokens,
        temperature: temperature,
      ),
    );

    final buffer = StringBuffer();
    await for (final chunk in responseStream) {
      buffer.write(chunk.text);
      yield buffer.toString();
    }
  }

  /// Generates text in one shot, returning the entire result as a [String].
  Future<String> predictOneShot({
    required String prompt,
    required int maxOutputTokens,
    required double temperature,
  }) async {
    final promptList = [Content.text(prompt)];
    final response = await _model.generateContent(
      promptList,
      generationConfig: GenerationConfig(
        maxOutputTokens: maxOutputTokens,
        temperature: temperature,
      ),
    );
    return response.text;
  }
}

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
  /// Defaults to model 'gemini-2.0-flash' with improved system instructions
  /// for social media post generation.
  FirebaseVertexAiClient({
    this.modelId = 'gemini-2.0-flash',
    Content? systemInstruction,
  }) : systemInstruction = systemInstruction ?? Content.system(
      "You are an AI that writes concise, engaging social media posts. "
          "Adapt your tone to match the category (professional for Business, "
          "casual for Personal, etc). Strictly respect character limits. "
          "Return only the post text without explanations or disclaimers. "
          "For best engagement, include emotion, clarity, and where appropriate, "
          "a subtle call to action."
  ) {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: modelId,
      systemInstruction: this.systemInstruction,
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
Write a social media post between $minTokens and $maxTokens tokens (~${minTokens * 4} to ${maxTokens * 4} chars).
IMPORTANT: Your response MUST be under 280 characters (Twitter limit).
Only final text, no disclaimers.

Here are examples of good posts in different styles:
- Business: "Just launched our new productivity suite with advanced AI features. Save 3 hours daily on routine tasks. Early adopters get 20% off. #ProductivityRevolution"
- Personal: "Hiked Mt. Rainier today! The view from the summit was absolutely breathtaking. Nothing beats that feeling of accomplishment mixed with nature's beauty. #MountainLife"
- Question: "What's one productivity hack that completely changed your workflow? Mine is time-blocking my calendar the night before. Game changer!"

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
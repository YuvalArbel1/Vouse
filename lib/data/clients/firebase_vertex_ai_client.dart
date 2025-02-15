// lib/data/clients/firebase_vertex_ai_client.dart

import 'dart:async';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class FirebaseVertexAiClient {
  final String modelId;

  /// The user can specify e.g. 'gemini-2.0-flash'
  FirebaseVertexAiClient({this.modelId = 'gemini-2.0-flash'});

  /// Streams partial text, using model.generateContentStream(...).
  /// We pass a prompt that explicitly requests <300 chars,
  /// plus an approximate token limit.
  Stream<String> generateTextStream({
    required String prompt,
    required int maxChars,
    int approximateTokens = 70, // ~70 tokens ~ 300 chars
  }) async* {
    final model = FirebaseVertexAI.instance.generativeModel(
      model: modelId,
    );

    // 1) We embed instructions in the prompt:
    //    "Write a short social media post (under 300 chars)."
    final instructionPrompt = """
Write a social media post under $maxChars characters, with no extra disclaimers or chain-of-thought. 
Only the final text. 
$prompt
""";

    final promptList = [Content.text(instructionPrompt)];

    // 2) Call generateContentStream with 'maxOutputTokens'
    final responseStream = model.generateContentStream(
      promptList,
      generationConfig: GenerationConfig(
        maxOutputTokens: approximateTokens,
        temperature: 0.7,
      ),

    );

    // 3) If you truly never want to forcibly cut partial text,
    //    you can skip the runtime check.
    //    If you do want a final safety net, keep this:
    final buffer = StringBuffer();
    await for (final chunk in responseStream) {
      buffer.write(chunk.text);

      // Optional final cutoff:
      // If you REALLY never want more than maxChars, uncomment below.
      /*
      if (buffer.length >= maxChars) {
        final truncated = buffer.toString().substring(0, maxChars);
        yield truncated;
        break;
      } else {
        yield buffer.toString();
      }
      */

      // If skipping cutoff, just yield partial each time:
      yield buffer.toString();
    }
  }
}

// lib/data/repository/ai/ai_text_repository_impl.dart

import 'dart:async';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';
import 'package:vouse_flutter/data/clients/firebase_vertex_ai_client.dart';

class AiTextRepositoryImpl implements AiTextRepository {
  final FirebaseVertexAiClient _client;

  AiTextRepositoryImpl(this._client);

  @override
  Stream<String> generateTextStream({
    required String prompt,
    int maxChars = 350,
  }) {
    return _client.generateTextStream(
      prompt: prompt,
      maxChars: maxChars,
      approximateTokens: 70,
    );
  }
}

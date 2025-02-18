// lib/presentation/providers/ai/ai_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:vouse_flutter/data/clients/vertex_ai/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/data/repository/ai/ai_text_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';

import '../../../domain/usecases/ai/generate_text_with_ai_usecase.dart';

/// Provide the Vertex AI client with a system instruction
final vertexAiClientProvider = Provider<FirebaseVertexAiClient>((ref) {
  return FirebaseVertexAiClient(
    modelId: 'gemini-2.0-flash',
    systemInstruction: Content.system(
        "You are an AI that writes short social media posts. "
            "Avoid chain-of-thought. If the user sets length constraints, follow them."
    ),
  );
});

/// Provide AiTextRepository
final aiTextRepositoryProvider = Provider<AiTextRepository>((ref) {
  return AiTextRepositoryImpl(ref.watch(vertexAiClientProvider));
});

/// Provide the UseCase
final generateTextUseCaseProvider = Provider<GenerateTextUseCase>((ref) {
  final repo = ref.watch(aiTextRepositoryProvider);
  return GenerateTextUseCase(repo);
});

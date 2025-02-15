// lib/presentation/providers/ai_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:vouse_flutter/data/clients/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/data/repository/ai/ai_text_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_text_repository.dart';

import '../../../domain/usecases/ai/generate_text_with_ai_usecase.dart';

/// Provide the Vertex AI Client
final vertexAiClientProvider = Provider<FirebaseVertexAiClient>((ref) {
  return FirebaseVertexAiClient(
    modelId: 'gemini-2.0-flash',
  );
});

/// Provide the AiTextRepository
final aiTextRepositoryProvider = Provider<AiTextRepository>((ref) {
  final client = ref.watch(vertexAiClientProvider);
  return AiTextRepositoryImpl(client);
});

/// Provide the UseCase
final generateTextUseCaseProvider = Provider<GenerateTextUseCase>((ref) {
  final repo = ref.watch(aiTextRepositoryProvider);
  return GenerateTextUseCase(repo);
});

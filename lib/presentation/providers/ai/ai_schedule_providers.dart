// presentation/providers/ai/ai_schedule_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:vouse_flutter/data/clients/vertex_ai/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/data/repository/ai/ai_schedule_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_schedule_repository.dart';

import '../../../domain/usecases/ai/predict_best_time_usecase.dart';

// 1) Provide the Vertex AI client with a system instruction that
//    encourages short date/time output only
final scheduleVertexAiClientProvider = Provider<FirebaseVertexAiClient>((ref) {
  return FirebaseVertexAiClient(
    modelId: 'gemini-2.0-flash',
    systemInstruction: Content.system(
        "You are an AI that strictly returns final answers in date/time format."
    ),
  );
});

// 2) Provide AiScheduleRepository
final aiScheduleRepositoryProvider = Provider<AiScheduleRepository>((ref) {
  final client = ref.watch(scheduleVertexAiClientProvider);
  return AiScheduleRepositoryImpl(client, ref);
});

// 3) Provide the one-shot use case
final predictBestTimeOneShotUseCaseProvider = Provider<PredictBestTimeOneShotUseCase>((ref) {
  final repo = ref.watch(aiScheduleRepositoryProvider);
  return PredictBestTimeOneShotUseCase(repo);
});

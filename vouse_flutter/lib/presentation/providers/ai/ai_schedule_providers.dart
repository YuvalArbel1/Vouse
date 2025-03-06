// lib/presentation/providers/ai/ai_schedule_providers.dart

import 'package:riverpod/riverpod.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:vouse_flutter/data/clients/vertex_ai/firebase_vertex_ai_client.dart';
import 'package:vouse_flutter/data/repository/ai/ai_schedule_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/ai/ai_schedule_repository.dart';
import '../../../domain/usecases/ai/predict_best_time_usecase.dart';

/// Provides a [FirebaseVertexAiClient] specialized for returning date/time format answers.
final scheduleVertexAiClientProvider = Provider<FirebaseVertexAiClient>((ref) {
  return FirebaseVertexAiClient(
    modelId: 'gemini-2.0-flash',
    systemInstruction: Content.system(
      "You are an AI that strictly returns final answers in date/time format.",
    ),
  );
});

/// Provides an [AiScheduleRepository] that predicts the best time to post
/// by calling [scheduleVertexAiClientProvider].
final aiScheduleRepositoryProvider = Provider<AiScheduleRepository>((ref) {
  final client = ref.watch(scheduleVertexAiClientProvider);
  return AiScheduleRepositoryImpl(client, ref);
});

/// Provides a [PredictBestTimeOneShotUseCase] for obtaining a single recommended post time.
final predictBestTimeOneShotUseCaseProvider =
    Provider<PredictBestTimeOneShotUseCase>((ref) {
  final repo = ref.watch(aiScheduleRepositoryProvider);
  return PredictBestTimeOneShotUseCase(repo);
});

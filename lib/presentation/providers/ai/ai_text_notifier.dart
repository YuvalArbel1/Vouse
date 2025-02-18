// lib/presentation/providers/ai/ai_text_notifier.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/usecases/ai/generate_text_with_ai_usecase.dart';
import 'ai_providers.dart';

class AiTextState {
  final String partialText;
  final bool isGenerating;
  final String? error;

  AiTextState({this.partialText = '', this.isGenerating = false, this.error});

  AiTextState copyWith({
    String? partialText,
    bool? isGenerating,
    String? error,
  }) {
    return AiTextState(
      partialText: partialText ?? this.partialText,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class AiTextNotifier extends StateNotifier<AiTextState> {
  final GenerateTextUseCase _useCase;
  StreamSubscription<String>? _sub;

  AiTextNotifier(this._useCase) : super(AiTextState());

  /// Called when the user hits "Generate"
  Future<void> generateText(String prompt, {
    int desiredChars = 150,
    double temperature = 0.5,
  }) async {
    await _sub?.cancel();
    state = AiTextState(partialText: '', isGenerating: true);

    try {
      final stream = await _useCase.call(
        params: GenerateTextParams(
          prompt,
          desiredChars: desiredChars,
          temperature: temperature,
        ),
      );

      _sub = stream.listen(
            (updated) {
          state = state.copyWith(partialText: updated, isGenerating: true);
        },
        onDone: () {
          state = state.copyWith(isGenerating: false);
        },
        onError: (e, st) {
          state = AiTextState(partialText: '', isGenerating: false, error: e.toString());
        },
      );
    } catch (e) {
      state = AiTextState(partialText: '', isGenerating: false, error: e.toString());
    }
  }

  /// Reset AI text
  Future<void> resetState() async {
    await _sub?.cancel();
    state = AiTextState(partialText: '', isGenerating: false, error: null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Provide the Notifier
final aiTextNotifierProvider =
StateNotifierProvider<AiTextNotifier, AiTextState>((ref) {
  final useCase = ref.watch(generateTextUseCaseProvider);
  return AiTextNotifier(useCase);
});

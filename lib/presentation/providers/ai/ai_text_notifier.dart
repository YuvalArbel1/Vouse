// lib/presentation/providers/ai_text_notifier.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/usecases/ai/generate_text_with_ai_usecase.dart';
import 'ai_providers.dart';

class AiTextState {
  final String partialText;
  final bool isGenerating;
  final String? error;

  AiTextState({
    this.partialText = '',
    this.isGenerating = false,
    this.error,
  });
}

class AiTextNotifier extends StateNotifier<AiTextState> {
  final GenerateTextUseCase _useCase;
  StreamSubscription<String>? _sub;

  AiTextNotifier(this._useCase) : super(AiTextState());

  Future<void> generateText(String prompt, {int maxChars = 350}) async {
    // cancel old sub
    await _sub?.cancel();
    // set to generating
    state = AiTextState(partialText: '', isGenerating: true, error: null);

    try {
      final stream = await _useCase.call(
        params: GenerateTextParams(prompt, maxChars: maxChars),
      );

      _sub = stream.listen(
            (updatedSoFar) {
          state = AiTextState(
            partialText: updatedSoFar,
            isGenerating: true,
          );
        },
        onDone: () {
          state = AiTextState(
            partialText: state.partialText,
            isGenerating: false,
          );
        },
        onError: (e, st) {
          state = AiTextState(
            partialText: '',
            isGenerating: false,
            error: e.toString(),
          );
        },
      );
    } catch (e) {
      state = AiTextState(
        partialText: '',
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Cancels streaming, resets
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

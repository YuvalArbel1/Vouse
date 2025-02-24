// lib/presentation/providers/ai/ai_text_notifier.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/usecases/ai/generate_text_with_ai_usecase.dart';
import 'ai_providers.dart';

/// Represents the current state of AI text generation.
class AiTextState {
  /// The progressively generated text.
  final String partialText;

  /// Indicates whether the AI generation is ongoing.
  final bool isGenerating;

  /// Holds any error message if generation fails.
  final String? error;

  /// Creates an [AiTextState] with optional [partialText], [isGenerating], and [error].
  AiTextState({
    this.partialText = '',
    this.isGenerating = false,
    this.error,
  });

  /// Returns a new [AiTextState] with any non-null fields replaced.
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

/// A [StateNotifier] that manages AI text generation via [GenerateTextUseCase].
class AiTextNotifier extends StateNotifier<AiTextState> {
  final GenerateTextUseCase _useCase;
  StreamSubscription<String>? _sub;

  /// Initializes the notifier with a reference to [GenerateTextUseCase].
  AiTextNotifier(this._useCase) : super(AiTextState());

  /// Invokes the AI text stream, updating [state] as partial text arrives.
  ///
  /// Cancels any existing subscription first, then sets [isGenerating] = true.
  /// On completion or error, updates [state] accordingly.
  Future<void> generateText(
    String prompt, {
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

  /// Resets the AI text generation to initial idle state.
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

/// Provides a singleton [AiTextNotifier] linked to the [GenerateTextUseCase].
final aiTextNotifierProvider =
    StateNotifierProvider<AiTextNotifier, AiTextState>((ref) {
  final useCase = ref.watch(generateTextUseCaseProvider);
  return AiTextNotifier(useCase);
});

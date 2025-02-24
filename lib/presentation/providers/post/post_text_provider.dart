// lib/presentation/providers/post/post_text_provider.dart

import 'package:riverpod/riverpod.dart';

/// A simple [StateProvider] that holds the user's current post text.
///
/// Default value is an empty string, representing no text typed yet.
/// ```
final postTextProvider = StateProvider<String>((ref) => '');

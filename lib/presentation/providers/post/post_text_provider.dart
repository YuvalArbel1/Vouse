// lib/presentation/providers/post/post_text_provider.dart

import 'package:riverpod/riverpod.dart';

/// A simple StateProvider that holds the user's current post text.
/// Default is empty string.
final postTextProvider = StateProvider<String>((ref) => '');

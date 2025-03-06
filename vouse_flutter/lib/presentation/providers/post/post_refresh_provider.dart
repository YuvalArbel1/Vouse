// lib/presentation/providers/post/post_refresh_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PostRefreshEvent { draft, scheduled, posted, all }

class PostRefreshNotifier extends StateNotifier<DateTime> {
  PostRefreshNotifier() : super(DateTime.now());

  bool _isRefreshing = false;

  void refreshDrafts() => _refreshType(PostRefreshEvent.draft);

  void refreshScheduled() => _refreshType(PostRefreshEvent.scheduled);

  void refreshPosted() => _refreshType(PostRefreshEvent.posted);

  void refreshAll() => _refreshType(PostRefreshEvent.all);

  void _refreshType(PostRefreshEvent type) {
    if (_isRefreshing) return;
    _isRefreshing = true;

    // Use Future.microtask to ensure we're not blocking the UI thread
    Future.microtask(() {
      state = DateTime.now();
      _isRefreshing = false;
    });
  }
}

// Provider that exposes the notifier
final postRefreshProvider =
    StateNotifierProvider<PostRefreshNotifier, DateTime>((ref) {
  return PostRefreshNotifier();
});

// Event-specific providers that depend on the main provider
final draftRefreshProvider = Provider<DateTime>((ref) {
  return ref.watch(postRefreshProvider);
});

final scheduledRefreshProvider = Provider<DateTime>((ref) {
  return ref.watch(postRefreshProvider);
});

final postedRefreshProvider = Provider<DateTime>((ref) {
  return ref.watch(postRefreshProvider);
});

// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import '../../../core/resources/data_state.dart';
import '../../providers/auth/firebase/firebase_auth_notifier.dart';
import '../../providers/home/home_posts_providers.dart';
import '../post/create_post_screen.dart';

import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_card.dart';

/// A Home screen that displays three horizontal rows of posts:
/// - Drafts
/// - Scheduled
/// - Posted
///
/// Includes an AppBar with refresh and logout buttons, plus a FAB for creating new posts.
/// The screen automatically refreshes when returning from the Create Post screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Remove the native splash screen after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  /// Refreshes all post data by invalidating the providers.
  /// This forces Riverpod to re-fetch the data from the repositories.
  void _refreshData() {
    ref.invalidate(draftPostsProvider);
    ref.invalidate(scheduledPostsProvider);
    ref.invalidate(postedPostsProvider);
  }

  /// Navigates to the Create Post screen and refreshes data when returning.
  ///
  /// This ensures that any newly created drafts or scheduled posts will
  /// immediately appear in the UI when the user returns to this screen.
  Future<void> _navigateToCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );

    // Refresh data when we return from create post screen
    _refreshData();
  }

  /// Handles the logout process.
  /// Uses [firebaseAuthNotifierProvider] to sign out. If successful, navigates to [SignInScreen].
  Future<void> _handleLogout() async {
    // Sign out asynchronously.
    await ref.read(firebaseAuthNotifierProvider.notifier).signOut();
    if (!mounted) return;

    final authState = ref.read(firebaseAuthNotifierProvider);
    if (authState is DataSuccess<void>) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
      );
    } else if (authState is DataFailed<void>) {
      final errorMsg = authState.error?.error ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $errorMsg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the providers for real-time updates
    final draftsAsync = ref.watch(draftPostsProvider);
    final scheduledAsync = ref.watch(scheduledPostsProvider);
    final postedAsync = ref.watch(postedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          // Add refresh button to manually refresh the data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh posts',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Required for RefreshIndicator to work
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Drafts', style: boldTextStyle(size: 18)),
              const SizedBox(height: 8),
              // Show drafts in a horizontal row
              draftsAsync.when(
                data: (drafts) => _buildPostsRow(drafts),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Error loading drafts: $err'),
              ),
              const SizedBox(height: 32),

              Text('Scheduled', style: boldTextStyle(size: 18)),
              const SizedBox(height: 8),
              // Show scheduled in a horizontal row
              scheduledAsync.when(
                data: (scheduled) => _buildPostsRow(scheduled),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Error loading scheduled: $err'),
              ),

              const SizedBox(height: 32),
              Text('Posted', style: boldTextStyle(size: 18)),
              const SizedBox(height: 8),
              // Show posted posts in a horizontal row
              postedAsync.when(
                data: (posted) => _buildPostsRow(posted),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Error loading posted: $err'),
              ),
            ],
          ),
        ),
      ),
      // Button to create new post
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Builds a horizontally scrolling row of [PostCard]s.
  /// If empty => show a quick "No posts found" text.
  Widget _buildPostsRow(List<PostEntity> posts) {
    if (posts.isEmpty) {
      return const Text('No posts found.');
    }

    return SizedBox(
      height: 350,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        itemBuilder: (ctx, index) {
          final p = posts[index];
          return PostCard(post: p); // each card is 320x400
        },
      ),
    );
  }
}
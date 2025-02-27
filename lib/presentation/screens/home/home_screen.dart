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

// Import the new providers
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_card.dart';

/// A sample Home screen that displays two horizontal "rows" of posts:
/// - Drafts
/// - Scheduled
///
/// Also includes an AppBar with a "Logout" button and a FAB for creating new posts.
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
    // Watch the new providers
    final draftsAsync = ref.watch(draftPostsProvider);
    final scheduledAsync = ref.watch(scheduledPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
          ],
        ),
      ),
      // Button to create new post
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
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

    // We know each card is 400 in height, let's give a bit of extra headroom
    // or exact 400 is also fine. We'll pick 420 to have some margin
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

// lib/presentation/screens/post_history/post_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/post_card.dart';

/// Screen that shows a history of user's posted content
class PostHistoryScreen extends ConsumerWidget {
  const PostHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch posted posts provider
    final postedPostsAsync = ref.watch(postedPostsProvider);

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      appBar: AppBar(
        title: const Text('Your Posts', style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold
        )),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/vouse_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show only posted posts in this screen
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: vPrimaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Published Posts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Build post grid with proper AsyncValue handling
                  _buildPostsGrid(context, postedPostsAsync),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a grid of post cards
  Widget _buildPostsGrid(BuildContext context, AsyncValue<List<PostEntity>> asyncPosts) {
    // Handle loading state
    if (asyncPosts.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Handle error state
    if (asyncPosts.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('Error: ${asyncPosts.error}'),
        ),
      );
    }

    // Extract data (this is safe now after checking for loading and error states)
    final posts = asyncPosts.value ?? [];

    // Handle empty state
    if (posts.isEmpty) {
      return _buildEmptyState();
    }

    // Build grid of posts
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: posts.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
        },
      ),
    );
  }

  /// Builds an empty state widget
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.post_add,
            size: 48,
            color: Colors.grey.withAlpha(128),
          ),
          const SizedBox(height: 16),
          const Text(
            'No published posts yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your published posts will appear here',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
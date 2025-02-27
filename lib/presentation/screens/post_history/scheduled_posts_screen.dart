// lib/presentation/screens/post_history/scheduled_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/post_card.dart';

/// Screen showing upcoming scheduled posts and drafts
class ScheduledPostsScreen extends ConsumerWidget {
  const ScheduledPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both scheduled and draft posts
    final scheduledPostsAsync = ref.watch(scheduledPostsProvider);
    final draftPostsAsync = ref.watch(draftPostsProvider);

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      appBar: AppBar(
        title: const Text('Upcoming & Drafts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  // Scheduled Posts Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: vAccentColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Scheduled Posts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vAccentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPostsList(context, scheduledPostsAsync, isScheduled: true),

                  const SizedBox(height: 24),

                  // Drafts Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note, color: vPrimaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Drafts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPostsList(context, draftPostsAsync, isScheduled: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a post list with proper handling of AsyncValue
  Widget _buildPostsList(BuildContext context, AsyncValue<List<PostEntity>> asyncPosts, {required bool isScheduled}) {
    if (asyncPosts.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (asyncPosts.hasError) {
      return Center(child: Text('Error: ${asyncPosts.error}'));
    }

    // Extract the data (it's safe now because we checked for loading and error states)
    final posts = asyncPosts.value ?? [];

    if (posts.isEmpty) {
      return _buildEmptyState(isScheduled ? 'No scheduled posts yet' : 'No drafts yet');
    }

    // For scheduled posts, show timeline
    if (isScheduled) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: posts.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final post = posts[index];
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: vAccentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                      if (index < posts.length - 1)
                        Container(
                          width: 2,
                          height: 100,
                          color: vAccentColor.withAlpha(77),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Post card and scheduled time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.scheduledAt != null
                              ? 'Scheduled for: ${_formatDateTime(post.scheduledAt!)}'
                              : 'No schedule set',
                          style: const TextStyle(
                            color: vAccentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 300,
                          child: PostCard(post: post),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      );
    }
    // For drafts, simple list
    else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: posts.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 300,
              child: PostCard(post: post),
            ),
          );
        },
      );
    }
  }

  /// Builds an empty state indicator
  Widget _buildEmptyState(String message) {
    return Container(
      height: 150,
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
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey.withAlpha(128),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Formats a DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final time = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }
}
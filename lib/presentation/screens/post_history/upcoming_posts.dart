// lib/presentation/screens/post_history/upcoming_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/presentation/widgets/common/empty_state.dart';
import 'package:vouse_flutter/presentation/widgets/common/loading_states.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/draft_card.dart';

import '../../widgets/post/timeline/timeline_item.dart';

/// A modern, visually appealing screen showing upcoming scheduled posts and drafts
/// with tab navigation, animated transitions, and contextual actions.
class UpcomingPostsScreen extends ConsumerStatefulWidget {
  const UpcomingPostsScreen({super.key});

  @override
  ConsumerState<UpcomingPostsScreen> createState() =>
      _UpcomingPostsScreenState();
}

class _UpcomingPostsScreenState extends ConsumerState<UpcomingPostsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Start initial animation
    _animationController.forward();
  }

  /// Handles tab change events to restart animations
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Refreshes both scheduled and draft posts
  Future<void> _refreshPosts() async {
    setState(() => _isRefreshing = true);

    // Invalidate providers to force refresh
    ref.invalidate(scheduledPostsProvider);
    ref.invalidate(draftPostsProvider);

    // Give time for the refresh to complete visually
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  /// Navigate to create post screen
  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Upcoming Posts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: vPrimaryColor,
          unselectedLabelColor: vBodyGrey,
          indicatorColor: vPrimaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.schedule),
              text: "SCHEDULED",
            ),
            Tab(
              icon: Icon(Icons.edit_note),
              text: "DRAFTS",
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/vouse_bg.jpg'),
              fit: BoxFit.cover,
              opacity: 0.8,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _refreshPosts,
            color: vPrimaryColor,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Scheduled Posts Tab
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildScheduledPostsTab(),
                ),

                // Drafts Tab
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildDraftsTab(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the scheduled posts tab content
  Widget _buildScheduledPostsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final scheduledPostsAsync = ref.watch(scheduledPostsProvider);

        return scheduledPostsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return EmptyState(
                icon: Icons.schedule,
                title: 'No scheduled posts',
                message: 'Start scheduling posts to see them here',
                buttonText: 'Create Post',
                onButtonPressed: _navigateToCreatePost,
              );
            }

            // Sort posts by scheduled time
            final sortedPosts = List<PostEntity>.from(posts)
              ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              itemCount: sortedPosts.length,
              itemBuilder: (context, index) {
                return TimelinePostItem(
                  post: sortedPosts[index],
                  index: index,
                  isLast: index == sortedPosts.length - 1,
                );
              },
            );
          },
          loading: () => const Center(
            child: FullScreenLoading(message: 'Loading scheduled posts...'),
          ),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  /// Builds the drafts tab content
  Widget _buildDraftsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final draftPostsAsync = ref.watch(draftPostsProvider);

        return draftPostsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return EmptyState(
                icon: Icons.edit_note,
                title: 'No drafts yet',
                message: 'Save drafts to continue editing later',
                buttonText: 'Create Draft',
                onButtonPressed: _navigateToCreatePost,
              );
            }

            // Sort drafts by creation date (newest first)
            final sortedDrafts = List<PostEntity>.from(posts)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              itemCount: sortedDrafts.length,
              itemBuilder: (context, index) {
                return DraftCard(post: sortedDrafts[index]);
              },
            );
          },
          loading: () => const Center(
            child: FullScreenLoading(message: 'Loading drafts...'),
          ),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }
}

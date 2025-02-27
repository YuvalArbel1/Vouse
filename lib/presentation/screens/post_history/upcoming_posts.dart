// lib/presentation/screens/post_history/upcoming_posts_screen.dart
// Renamed from scheduled_posts_screen.dart for better clarity

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/post_card.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';

/// A modern, visually appealing screen showing upcoming scheduled posts and drafts
/// with tab navigation, animated transitions, and contextual actions.
///
/// Features:
/// - Tab navigation between Scheduled and Drafts
/// - Timeline visualization for scheduled posts
/// - Card-based layout with visual cues for post status
/// - Empty state handling with action prompts
/// - Pull-to-refresh functionality
/// - Contextual quick actions for each post type
class UpcomingPostsScreen extends ConsumerStatefulWidget {
  /// Creates an [UpcomingPostsScreen] with default configuration.
  const UpcomingPostsScreen({super.key});

  @override
  ConsumerState<UpcomingPostsScreen> createState() => _UpcomingPostsScreenState();
}

class _UpcomingPostsScreenState extends ConsumerState<UpcomingPostsScreen> with TickerProviderStateMixin {
  /// Tab controller for switching between Scheduled and Drafts
  late TabController _tabController;

  /// Animation controller for page transitions
  late AnimationController _animationController;

  /// Animation for content fade-in
  late Animation<double> _fadeAnimation;

  /// Controls if we're currently refreshing data
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
      // Remove floating action button as it conflicts with bottom nav bar
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
              return _buildEmptyState(
                icon: Icons.schedule,
                title: 'No scheduled posts',
                message: 'Start scheduling posts to see them here',
                buttonText: 'Create Post',
                onPressed: _navigateToCreatePost,
              );
            }

            // Sort posts by scheduled time
            final sortedPosts = List<PostEntity>.from(posts)
              ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: sortedPosts.length,
              itemBuilder: (context, index) {
                return _buildScheduledPostTimelineItem(sortedPosts[index], index, sortedPosts.length);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
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
              return _buildEmptyState(
                icon: Icons.edit_note,
                title: 'No drafts yet',
                message: 'Save drafts to continue editing later',
                buttonText: 'Create Draft',
                onPressed: _navigateToCreatePost,
              );
            }

            // Sort drafts by creation date (newest first)
            final sortedDrafts = List<PostEntity>.from(posts)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 0.9,
                mainAxisSpacing: 24,
                crossAxisSpacing: 16,
              ),
              itemCount: sortedDrafts.length,
              itemBuilder: (context, index) {
                return _buildDraftItem(sortedDrafts[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  /// Builds a scheduled post item with timeline visualization
  Widget _buildScheduledPostTimelineItem(PostEntity post, int index, int totalItems) {
    final isLast = index == totalItems - 1;
    final scheduledTime = post.scheduledAt!;
    final now = DateTime.now();

    // Calculate if post is scheduled for today, tomorrow, or later
    final isToday = scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;

    final isTomorrow = scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day + 1;

    // Format the date for display
    final dateLabel = isToday
        ? 'Today'
        : isTomorrow
        ? 'Tomorrow'
        : DateFormat('EEE, MMM d').format(scheduledTime);

    // Format the time
    final timeLabel = DateFormat('h:mm a').format(scheduledTime);

    // Check if post is upcoming or past due
    final isPastDue = scheduledTime.isBefore(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline visualization
          Column(
            children: [
              // Time indicator dot
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPastDue ? Colors.grey : vAccentColor,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (isPastDue ? Colors.grey : vAccentColor).withAlpha(100),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  isPastDue ? Icons.hourglass_empty : Icons.schedule,
                  color: Colors.white,
                  size: 14,
                ),
              ),

              // Connecting line (hide for last item)
              if (!isLast)
                Container(
                  width: 2,
                  height: 310,
                  color: Colors.grey.withAlpha(100),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Post content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date/time header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPastDue ? Colors.grey.withAlpha(200) : vAccentColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isPastDue ? Colors.grey : vAccentColor).withAlpha(50),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isPastDue ? Icons.warning : Icons.access_time,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Post card
                SizedBox(
                  height: 300, // Fixed height for consistency
                  child: PostCard(post: post),
                ),

                if (!isLast)
                  const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a draft post item
  Widget _buildDraftItem(PostEntity post) {
    // Calculate time since creation
    final now = DateTime.now();
    final difference = now.difference(post.createdAt);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      timeAgo = 'Just now';
    }

    // Check if post has images
    final hasImages = post.localImagePaths.isNotEmpty;

    return Stack(
      children: [
        // Post card
        PostCard(post: post),

        // Draft badge
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 14,
                  color: vPrimaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'DRAFT',
                  style: TextStyle(
                    color: vPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Created time
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Has images indicator
        if (hasImages)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.image,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.localImagePaths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Builds an empty state widget with action button
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: vPrimaryColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: vPrimaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: vPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: vBodyGrey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: vPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
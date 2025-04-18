// lib/presentation/screens/post_history/published_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/presentation/widgets/common/empty_state.dart';
import 'package:vouse_flutter/presentation/widgets/common/filter_chips.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/post_card.dart';
import 'package:vouse_flutter/presentation/widgets/stats/engagement_metrics_card.dart';
import 'package:vouse_flutter/presentation/providers/filter/post_filtered_provider.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/presentation/providers/local_db/local_user_providers.dart';
import 'package:vouse_flutter/presentation/providers/navigation/navigation_service.dart';

import '../../../core/resources/data_state.dart';
import '../../../core/util/common.dart';
import '../../providers/server/server_sync_provider.dart';
import '../../providers/engagement/post_engagement_provider.dart';
import '../../widgets/common/loading/post_loading.dart';
import '../../widgets/post/post_preview/publish_posts_header.dart';

/// Analytics-driven screen showing published posts with:
/// - Personalized header
/// - Engagement metrics
/// - Filtering capabilities
/// - Performance visualization
///
class PublishedPostsScreen extends ConsumerStatefulWidget {
  const PublishedPostsScreen({super.key});

  @override
  ConsumerState<PublishedPostsScreen> createState() =>
      _PublishedPostsScreenState();
}

class _PublishedPostsScreenState extends ConsumerState<PublishedPostsScreen>
    with SingleTickerProviderStateMixin {
  /// Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /// Available time-based filter options
  final List<String> _filterOptions = [
    'All Time',
    'This Month',
    'This Week',
    'Today'
  ];

  /// User profile for personalized header
  UserEntity? _userProfile;

  /// Loading state
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  /// Initialize screen animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Initialize data when the screen loads
  Future<void> _initializeData() async {
    setState(() => _isRefreshing = true);

    try {
      // Load user profile
      await _loadUserProfile();

      // Ensure we have the latest engagement data
      if (ref.read(postEngagementDataProvider).engagementByPostId.isEmpty) {
        await ref
            .read(postEngagementDataProvider.notifier)
            .fetchEngagementData();
      }

      // Start animation after data is loaded
      _animationController.forward();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// Load user profile for personalized content
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final getUserUC = ref.read(getUserUseCaseProvider);
    final result = await getUserUC.call(params: GetUserParams(user.uid));

    if (result is DataSuccess<UserEntity?> && mounted) {
      setState(() {
        _userProfile = result.data;
      });
    }
  }

  /// Refresh all data
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // First synchronize with server to update post statuses
      await ref.read(serverSyncProvider.notifier).synchronizePosts();

      // Then fetch the latest engagement data
      await ref
          .read(postEngagementDataProvider.notifier)
          .refreshAllEngagements();

      // Reset animations for visual feedback
      _animationController.reset();

      // Invalidate the filtered posts provider to force refetching
      ref.invalidate(filteredPostsProvider);

      // Load user profile for personalized content
      await _loadUserProfile();

      // Start animations after data is loaded
      _animationController.forward();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Navigate to create post screen
  void _navigateToCreatePost() {
    ref.read(navigationServiceProvider).navigateToCreatePost(context);
  }

  /// Calculate total posts from filtered data
  int _calculateTotalPosts() {
    final postsAsync = ref.watch(filteredPostsProvider);
    return postsAsync.when(
      data: (posts) => posts.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if engagement data is loading
    final isEngagementLoading = ref.watch(isEngagementLoadingProvider);
    final showLoading = _isRefreshing || isEngagementLoading;

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: vPrimaryColor,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Personalized Header
                SliverToBoxAdapter(
                  child: PublishedPostsHeader(
                    userProfile: _userProfile,
                    postCount: _calculateTotalPosts(),
                  ),
                ),

                // Filter Chips
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeaderDelegate(
                    child: Container(
                      color: Colors.white,
                      child: FilterChips(
                        filters: _filterOptions,
                        activeFilter: ref.watch(activeTimeFilterProvider),
                        onFilterChanged: (filter) {
                          ref.read(activeTimeFilterProvider.notifier).state =
                              filter;
                          _animationController.reset();
                          _animationController.forward();
                        },
                      ),
                    ),
                  ),
                ),

                // Main Content
                SliverToBoxAdapter(
                  child: _buildPostsContent(),
                ),
              ],
            ),

            // Loading overlay
            if (showLoading)
              BlockingSpinnerOverlay(
                isVisible: true,
              ),
          ],
        ),
      ),
    );
  }

  /// Build main posts content with metrics and grid/list
  Widget _buildPostsContent() {
    return Consumer(
      builder: (context, ref, _) {
        final filteredPostsAsync = ref.watch(filteredPostsProvider);
        final activeFilter = ref.watch(activeTimeFilterProvider);

        // Get engagement metrics using the provider
        final engagementMetrics = ref.watch(engagementMetricsProvider);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              child: filteredPostsAsync.when(
                data: (posts) =>
                    _buildPostsSection(posts, engagementMetrics, activeFilter),
                loading: () => const Center(
                  child: HorizontalPostListLoading(itemCount: 2),
                ),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build posts section with metrics and posts list/grid
  Widget _buildPostsSection(
      List<dynamic> posts, Map<String, int> metrics, String activeFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Engagement Metrics
        EngagementMetricsCard(
          metrics: metrics,
          timeFilter: activeFilter,
        ),
        const SizedBox(height: 20),

        // Posts Count Header
        _buildPostsHeader(posts, activeFilter),
        const SizedBox(height: 16),

        // Posts Grid or Empty State
        posts.isEmpty
            ? EmptyState(
                icon: Icons.post_add,
                title: '📝 No published posts yet',
                message: activeFilter != 'All Time'
                    ? '✨ There are no posts from $activeFilter'
                    : '✨ Time to share your first brilliant post!',
                buttonText: 'Create Your First Post',
                onButtonPressed: _navigateToCreatePost,
              )
            : _buildPostsList(posts),
      ],
    );
  }

  /// Build posts header with count and new post button
  Widget _buildPostsHeader(List<dynamic> posts, String activeFilter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${posts.length} ${posts.length == 1 ? 'Post' : 'Posts'} '
          '${activeFilter != 'All Time' ? 'in $activeFilter' : ''}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (posts.isNotEmpty)
          TextButton.icon(
            onPressed: _navigateToCreatePost,
            icon: const Icon(Icons.add),
            label: const Text('New Post'),
            style: TextButton.styleFrom(
              foregroundColor: vPrimaryColor,
            ),
          ),
      ],
    );
  }

  /// Build posts list view
  Widget _buildPostsList(List<dynamic> posts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: PostCard(post: post),
        );
      },
    );
  }
}

/// Custom persistent header delegate for filter chips
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterHeaderDelegate({required this.child});

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// lib/presentation/screens/post_history/published_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/presentation/widgets/common/empty_state.dart';
import 'package:vouse_flutter/presentation/widgets/common/filter_chips.dart';
import 'package:vouse_flutter/presentation/widgets/common/loading_states.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/post_card.dart';

import '../../providers/filter/post_filtered_provider.dart';
import '../../widgets/stats/engagement_metrics_card.dart';

/// A refined screen showing published posts with performance analytics,
/// engagement metrics, and modern filtering options.
class PublishedPostsScreen extends ConsumerStatefulWidget {
  const PublishedPostsScreen({super.key});

  @override
  ConsumerState<PublishedPostsScreen> createState() => _PublishedPostsScreenState();
}

class _PublishedPostsScreenState extends ConsumerState<PublishedPostsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _filterOptions = [
    'All Time',
    'This Month',
    'This Week',
    'Today'
  ];

  @override
  void initState() {
    super.initState();

    // Setup animations
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Navigate to create post screen
  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  /// Refresh data
  Future<void> _refreshData() async {
    ref.invalidate(filteredPostsProvider);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: vPrimaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: vPrimaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Published Posts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background with gradient overlay
                      Image.asset(
                        'assets/images/vouse_bg.jpg',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              vPrimaryColor.withAlpha(100),
                              vPrimaryColor.withAlpha(200),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter chips
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterHeaderDelegate(
                  child: Container(
                    color: Colors.white,
                    child: FilterChips(
                      filters: _filterOptions,
                      activeFilter: ref.watch(activeTimeFilterProvider),
                      onFilterChanged: (filter) {
                        ref.read(activeTimeFilterProvider.notifier).state = filter;
                        _animationController.reset();
                        _animationController.forward();
                      },
                    ),
                  ),
                ),
              ),

              // Content area
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final filteredPostsAsync = ref.watch(filteredPostsProvider);
                          final metrics = ref.watch(engagementMetricsProvider);
                          final activeFilter = ref.watch(activeTimeFilterProvider);

                          return filteredPostsAsync.when(
                            data: (posts) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Engagement metrics
                                  EngagementMetricsCard(
                                    metrics: metrics,
                                    timeFilter: activeFilter,
                                  ),
                                  const SizedBox(height: 20),

                                  // Posts count
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${posts.length} ${posts.length == 1 ? 'Post' : 'Posts'} ${activeFilter != 'All Time' ? 'in $activeFilter' : ''}',
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
                                  ),
                                  const SizedBox(height: 16),

                                  // Posts grid or empty state
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
                                      : _buildPostsGrid(posts),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 100),
                                child: FullScreenLoading(message: 'Loading your posts...'),
                              ),
                            ),
                            error: (error, _) => Center(child: Text('Error: $error')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the posts grid layout
  Widget _buildPostsGrid(List<dynamic> posts) {
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

/// Persistent header delegate for filter chips
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
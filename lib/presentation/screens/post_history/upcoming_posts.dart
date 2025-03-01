// lib/presentation/screens/post_history/upcoming_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';

import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';
import 'package:vouse_flutter/presentation/providers/local_db/local_user_providers.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/presentation/widgets/common/empty_state.dart';
import 'package:vouse_flutter/presentation/widgets/common/loading_states.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/draft_card.dart';
import 'package:vouse_flutter/presentation/widgets/post/timeline/timeline_item.dart';

import '../../../core/resources/data_state.dart';
import '../../widgets/post/post_preview/upcoming_posts_header.dart';

/// A comprehensive screen for managing upcoming and draft posts
///
/// Key Features:
/// - Tabbed interface for Scheduled and Draft posts
/// - Personalized header with content journey insights
/// - Animated transitions
/// - Responsive design
/// - Empty state handling
/// - Refresh capabilities
class UpcomingPostsScreen extends ConsumerStatefulWidget {
  /// Creates an instance of [UpcomingPostsScreen]
  const UpcomingPostsScreen({super.key});

  @override
  ConsumerState<UpcomingPostsScreen> createState() =>
      _UpcomingPostsScreenState();
}

class _UpcomingPostsScreenState extends ConsumerState<UpcomingPostsScreen>
    with TickerProviderStateMixin {
  /// Tab controller for managing scheduled and draft tabs
  late TabController _tabController;

  /// Animation controller for smooth transitions
  late AnimationController _animationController;

  /// Fade animation for content
  late Animation<double> _fadeAnimation;

  /// User profile for personalization
  UserEntity? _userProfile;

  /// Tracks refresh state
  bool _isRefreshing = false;

  /// Total number of scheduled posts
  int _scheduledPostCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserProfile();
  }

  /// Initialize tab and animation controllers
  void _initializeControllers() {
    // Tab controller setup
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Animation controller setup
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

  /// Load user profile for personalization
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final getUserUC = ref.read(getUserUseCaseProvider);
    final result = await getUserUC.call(params: GetUserParams(user.uid));

    if (result is DataSuccess<UserEntity?>) {
      setState(() {
        _userProfile = result.data;
      });
    }
  }

  /// Handle tab change events
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

  /// Refresh posts data
  Future<void> _refreshPosts() async {
    setState(() => _isRefreshing = true);

    // Invalidate providers to force refresh
    ref.invalidate(scheduledPostsProvider);
    ref.invalidate(draftPostsProvider);

    // Reload user profile
    await _loadUserProfile();

    // Simulate refresh delay
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

  /// Calculate total number of scheduled posts
  int _calculateScheduledPosts() {
    final scheduledPostsAsync = ref.read(scheduledPostsProvider);
    return scheduledPostsAsync.when(
      data: (posts) => posts.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update scheduled post count
    final currentScheduledPosts = _calculateScheduledPosts();
    if (currentScheduledPosts != _scheduledPostCount) {
      setState(() {
        _scheduledPostCount = currentScheduledPosts;
      });
    }

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Personalized Upcoming Posts Header
          SliverToBoxAdapter(
            child: UpcomingPostsHeader(
              scheduledPostCount: _scheduledPostCount,
            ),
          ),

          // Tabs and Content
          SliverFillRemaining(
            child: RefreshIndicator(
              onRefresh: _refreshPosts,
              color: vPrimaryColor,
              child: Column(
                children: [
                  // Tab Bar
                  TabBar(
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

                  // Tab Content
                  // Optimized TabBarView in UpcomingPostsScreen
// Replace the current implementation with this version that properly
// uses your existing filter providers

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Scheduled Posts Tab - Using Consumer to isolate rebuilds
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Consumer(
                            builder: (context, ref, child) {
                              // Use your existing filter provider instead of direct watching and sorting
                              final scheduledPostsAsync =
                                  ref.watch(scheduledPostsProvider);

                              return scheduledPostsAsync.when(
                                data: (posts) {
                                  if (posts.isEmpty) {
                                    return _buildEmptyState(
                                      icon: Icons.schedule,
                                      title: 'No scheduled posts',
                                      message:
                                          'Start scheduling posts to see them here',
                                      buttonText: 'Create Post',
                                    );
                                  }

                                  // No need to sort here since your filter provider already handles it
                                  return ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                        top: 16, bottom: 100),
                                    itemCount: posts.length,
                                    itemBuilder: (context, index) {
                                      return TimelinePostItem(
                                        post: posts[index],
                                        index: index,
                                        isLast: index == posts.length - 1,
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: FullScreenLoading(
                                      message: 'Loading scheduled posts...'),
                                ),
                                error: (error, _) =>
                                    Center(child: Text('Error: $error')),
                              );
                            },
                          ),
                        ),

                        // Drafts Tab - Using Consumer to isolate rebuilds
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Consumer(
                            builder: (context, ref, child) {
                              // Use your existing filter provider
                              final draftPostsAsync =
                                  ref.watch(draftPostsProvider);

                              return draftPostsAsync.when(
                                data: (posts) {
                                  if (posts.isEmpty) {
                                    return _buildEmptyState(
                                      icon: Icons.edit_note,
                                      title: 'No drafts yet',
                                      message:
                                          'Save drafts to continue editing later',
                                      buttonText: 'Create Draft',
                                    );
                                  }

                                  // No need to sort here
                                  return ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                        top: 16, bottom: 100),
                                    itemCount: posts.length,
                                    itemBuilder: (context, index) {
                                      return DraftCard(post: posts[index]);
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: FullScreenLoading(
                                      message: 'Loading drafts...'),
                                ),
                                error: (error, _) =>
                                    Center(child: Text('Error: $error')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      buttonText: buttonText,
      onButtonPressed: _navigateToCreatePost,
    );
  }
}

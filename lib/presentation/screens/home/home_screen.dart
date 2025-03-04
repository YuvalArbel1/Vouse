// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/presentation/widgets/common/section_header.dart';
import 'package:vouse_flutter/presentation/widgets/home/quick_actions_panel.dart';
import 'package:vouse_flutter/presentation/widgets/home/motivation_card.dart';

// Import new providers and components
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';
import 'package:vouse_flutter/presentation/providers/home/home_content_provider.dart';
import 'package:vouse_flutter/presentation/widgets/common/common_ui_components.dart';

import '../../../core/resources/data_state.dart';
import '../../../domain/entities/local_db/user_entity.dart';
import '../../providers/auth/firebase/firebase_auth_notifier.dart';
import '../../widgets/common/loading/post_loading.dart';
import '../../widgets/home/stat_item.dart';
import '../../providers/navigation/navigation_service.dart';
import '../../widgets/post/post_preview/post_card.dart';

/// A modern, visually engaging home screen with dynamic content sections
/// and personalized user experience.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _actionsAnimation;
  late Animation<double> _contentAnimation;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _actionsAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );

    _contentAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    // Remove splash screen and load app data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _loadInitialData();
    });

    // Set preferred status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: vAppLayoutBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Loads all initial data required for the home screen
  Future<void> _loadInitialData() async {
    // Load user profile if not already loaded
    if (ref.read(userProfileProvider).loadingState ==
        UserProfileLoadingState.initial) {
      await ref.read(userProfileProvider.notifier).loadUserProfile();
    }

    // Load home content
    await ref.read(homeContentProvider.notifier).loadHomeContent();

    // Start animations after data is loaded
    _animationController.forward();
  }

  /// Refreshes user data and post providers
  // FIXED CODE
  Future<void> _refreshData() async {
    _animationController.reset();

    // Use a debouncer to prevent multiple refreshes
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      // Use single refresh method that handles both concerns
      await ref.read(homeContentProvider.notifier).refreshHomeContent();
      // User profile is already refreshed by auth state changes, no need for explicit refresh
    } finally {
      _isRefreshing = false;
      _animationController.forward();
    }
  }

  /// Returns a random social media tip
  String _getRandomTip() {
    final tips = [
      'Use relevant hashtags to increase your post visibility.',
      'The best times to post are typically 8 AM, 12 PM, and 8 PM.',
      'Engage with your followers by asking questions in your posts.',
      'Adding 1-3 relevant images increases engagement by up to 150%.',
      'Keep your content consistent but varied to maintain interest.',
      'Analyze your post performance to understand what resonates with your audience.',
      'Schedule posts in advance to maintain a consistent posting schedule.',
    ];

    return tips[DateTime.now().millisecond % tips.length];
  }

  /// Handles user logout
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(navigationServiceProvider)
                    .navigateBack(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => ref
                    .read(navigationServiceProvider)
                    .navigateBack(context, true),
                child:
                    const Text('Log Out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout) return;

    await ref.read(firebaseAuthNotifierProvider.notifier).signOut();
    if (!mounted) return;

    final authState = ref.read(firebaseAuthNotifierProvider);
    if (authState is DataSuccess<void>) {
      ref
          .read(navigationServiceProvider)
          .navigateToSignIn(context, clearStack: true);
    } else if (authState is DataFailed<void>) {
      final errorMsg = authState.error?.error ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $errorMsg')),
      );
    }
  }

  // Navigation helpers - now using the navigation service
// Navigation helpers - now using the navigation service with tab switching
  void _navigateToCreatePost() {
    ref.read(navigationServiceProvider).navigateToCreatePost(context);
  }

  void _navigateToPostHistory() {
    ref.read(navigationServiceProvider).navigateToPublishedPosts(context);
  }

  void _navigateToScheduledPosts() {
    ref.read(navigationServiceProvider).navigateToUpcomingPosts(context);
  }

  void _navigateToSettings() {
    ref.read(navigationServiceProvider).navigateToProfile(context);
  }

  void _navigateToEditProfile() {
    ref.read(navigationServiceProvider).navigateToEditProfile(
          context,
          isEditProfile: true,
          clearStack: false,
        );
  }

  void _navigateToPublisedPosts() {
    ref.read(navigationServiceProvider).navigateToPublishedPosts(context);
  }

  // void _showFeatureComingSoon(String feature) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('$feature coming soon!'),
  //       backgroundColor: vAccentColor,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // Replace in build() method
    final userProfile =
        ref.watch(userProfileProvider.select((state) => state.user));
    final isUserLoading = ref.watch(userProfileProvider.select((state) =>
        state.loadingState == UserProfileLoadingState.loading ||
        state.loadingState == UserProfileLoadingState.initial));
    final homeContentLoading =
        ref.watch(homeContentProvider.select((state) => state.isLoading));
    final postCounts =
        ref.watch(homeContentProvider.select((state) => state.postCounts));

    final isLoading = isUserLoading || homeContentLoading;

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      body: isLoading
          ? const HomeScreenLoading()
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/vouse_bg.jpg'),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    ),
                  ),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _headerAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.2),
                              end: Offset.zero,
                            ).animate(_headerAnimation),
                            child: _buildHeader(userProfile, postCounts),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _actionsAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.2, 0),
                              end: Offset.zero,
                            ).animate(_actionsAnimation),
                            child: QuickActionsPanel(
                              onNewPost: _navigateToCreatePost,
                              onSchedule: _navigateToScheduledPosts,
                              onPublishhed: _navigateToPublisedPosts,
                              onSettings: _navigateToSettings,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _contentAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(_contentAnimation),
                            child: Column(
                              children: [
                                SectionHeader(
                                  title: '📊 Recent Activity',
                                  onActionTap: _navigateToPostHistory,
                                ),
                                _buildRecentPostsSection(),
                                SectionHeader(
                                  title: '🗓️ Upcoming Posts',
                                  onActionTap: _navigateToScheduledPosts,
                                ),
                                _buildUpcomingPostsSection(),
                                MotivationCard(tip: _getRandomTip()),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Builds the header section with user profile and greeting
  Widget _buildHeader(UserEntity? userProfile, Map<String, int> postCounts) {
    // Time-based greeting
    final hour = DateTime.now().hour;
    String greeting = '';

    if (hour >= 5 && hour < 12) {
      greeting = '☀️ Good morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = '🌤️ Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      greeting = '🌙 Good evening';
    } else {
      greeting = '💫 Good night';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // User info row
          Row(
            children: [
              // Avatar with tap action - now using ProfileAvatarDisplay
              GestureDetector(
                onTap: _navigateToEditProfile,
                child: ProfileAvatarDisplay(
                  user: userProfile,
                  size: 60,
                  showEditStyle: true,
                  useHero: true,
                  uniqueId: 'home-screen',
                  heroTag: 'profile-avatar',
                  onTap: _navigateToEditProfile,
                ),
              ),
              const SizedBox(width: 16),

              // Greeting and name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 16,
                        color: vBodyGrey,
                      ),
                    ),
                    Text(
                      userProfile?.fullName ?? 'User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: vPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: vPrimaryColor),
                onPressed: _refreshData,
                tooltip: 'Refresh',
              ),

              // Logout button
              IconButton(
                icon: Icon(Icons.exit_to_app, color: Colors.red.shade400),
                onPressed: _handleLogout,
                tooltip: 'Sign out',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User info stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatItem(
                label: 'Posts',
                count: postCounts['posted'] ?? 0,
                icon: Icons.check_circle,
                color: vAccentColor,
              ),
              _buildDivider(),
              StatItem(
                label: 'Scheduled',
                count: postCounts['scheduled'] ?? 0,
                icon: Icons.schedule,
                color: vPrimaryColor,
              ),
              _buildDivider(),
              StatItem(
                label: 'Drafts',
                count: postCounts['drafts'] ?? 0,
                icon: Icons.edit_note,
                color: vBodyGrey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a vertical divider for statistics separation
  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.withAlpha(50),
    );
  }

  /// Builds the recent posts section with Consumer for reactive updates
  Widget _buildRecentPostsSection() {
    return SizedBox(
      height: 350,
      child: Consumer(
        builder: (context, ref, child) {
          final recentPosts = ref
              .watch(homeContentProvider.select((state) => state.recentPosts));

          if (recentPosts.isEmpty) {
            return _buildEmptyPostsCard(
              'No posts yet',
              'Your published posts will appear here',
              Icons.post_add,
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recentPosts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 280,
                  child: PostCard(post: recentPosts[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the upcoming posts section with Consumer for reactive updates
  Widget _buildUpcomingPostsSection() {
    return SizedBox(
      height: 350,
      child: Consumer(
        builder: (context, ref, child) {
          final upcomingPosts = ref.watch(
              homeContentProvider.select((state) => state.upcomingPosts));

          if (upcomingPosts.isEmpty) {
            return _buildEmptyPostsCard(
              'No scheduled posts',
              'Schedule posts to see them here',
              Icons.schedule,
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: upcomingPosts.length,
            itemBuilder: (context, index) {
              final post = upcomingPosts[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 280,
                  child: PostCard(post: post),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds an empty state card for when no posts are available
  Widget _buildEmptyPostsCard(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: vPrimaryColor.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: vBodyGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: vBodyGrey.withAlpha(180),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => title.contains('scheduled')
                ? _navigateToScheduledPosts()
                : _navigateToCreatePost(),
            style: ElevatedButton.styleFrom(
              backgroundColor: vPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              title.contains('scheduled') ? 'Schedule Post' : 'Create Post',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/presentation/screens/home/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';
import 'package:vouse_flutter/presentation/widgets/common/section_header.dart';
import 'package:vouse_flutter/presentation/widgets/common/loading_states.dart';
import 'package:vouse_flutter/presentation/widgets/home/stat_item.dart';
import 'package:vouse_flutter/presentation/widgets/home/quick_actions_panel.dart';
import 'package:vouse_flutter/presentation/widgets/home/motivation_card.dart';

import '../../providers/local_db/local_user_providers.dart';
import '../../providers/auth/firebase/firebase_auth_notifier.dart';
import '../../providers/home/home_posts_providers.dart';
import '../../widgets/post/post_preview/post_card.dart';
import '../auth/signin.dart';
import '../home/edit_profile_screen.dart';
import '../post_history/published_posts_screen.dart';
import '../post_history/upcoming_posts.dart';
import '../profile/profile_screen.dart';
import '../post/create_post_screen.dart';

/// Home screen provider to manage loading state
final homeScreenLoadingProvider = StateProvider<bool>((ref) => true);

/// Home screen provider to manage user profile
final homeUserProfileProvider = StateProvider<UserEntity?>((ref) => null);

/// Home screen provider to manage post counts
final homePostCountsProvider = StateProvider<Map<String, int>>((ref) => {
  'posted': 0,
  'scheduled': 0,
  'drafts': 0,
});

/// A modern, visually engaging home screen with dynamic content sections
/// and personalized user experience.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _actionsAnimation;
  late Animation<double> _contentAnimation;

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

    // Remove splash screen and load user profile after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _loadUserProfile();
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

  /// Loads user profile and post counts
  Future<void> _loadUserProfile() async {
    ref.read(homeScreenLoadingProvider.notifier).state = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ref.read(homeScreenLoadingProvider.notifier).state = false;
      return;
    }

    final getUserUC = ref.read(getUserUseCaseProvider);
    final result = await getUserUC.call(params: GetUserParams(user.uid));

    if (result is DataSuccess<UserEntity?>) {
      ref.read(homeUserProfileProvider.notifier).state = result.data;
    }

    await _loadPostCounts();

    // Start animations after data is loaded
    _animationController.forward();

    ref.read(homeScreenLoadingProvider.notifier).state = false;
  }

  /// Loads post counts for the user
  Future<void> _loadPostCounts() async {
    final postedPostsAsync = await ref.read(postedPostsProvider.future);
    final scheduledPostsAsync = await ref.read(scheduledPostsProvider.future);
    final draftPostsAsync = await ref.read(draftPostsProvider.future);

    ref.read(homePostCountsProvider.notifier).state = {
      'posted': postedPostsAsync.length,
      'scheduled': scheduledPostsAsync.length,
      'drafts': draftPostsAsync.length,
    };
  }

  /// Refreshes user data and post providers
  Future<void> _refreshData() async {
    _animationController.reset();

    await _loadUserProfile();
    ref.invalidate(postedPostsProvider);
    ref.invalidate(scheduledPostsProvider);
    ref.invalidate(draftPostsProvider);

    _animationController.forward();
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
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldLogout) return;

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

  // Navigation helpers
  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  void _navigateToPostHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PublishedPostsScreen()),
    );
  }

  void _navigateToScheduledPosts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpcomingPostsScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _showFeatureComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: vAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeScreenLoadingProvider);
    final userProfile = ref.watch(homeUserProfileProvider);
    final postCounts = ref.watch(homePostCountsProvider);

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      body: isLoading
          ? _buildShimmerLoading()
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
            child: CustomScrollView(  // Replace SingleChildScrollView with CustomScrollView
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
                        onAnalytics: () => _showFeatureComingSoon('Analytics'),
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

  /// Builds a shimmer loading effect while content is loading
  Widget _buildShimmerLoading() {
    return Container(
      color: vAppLayoutBackground,
      child: Column(
        children: [
          // Shimmer for header
          Container(
            height: 140,
            width: double.infinity,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerLoading.circle(size: 60),
                const SizedBox(height: 12),
                ShimmerLoading.roundedRectangle(
                  width: 150,
                  height: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Shimmer for action buttons
          ShimmerLoading.roundedRectangle(
            width: double.infinity,
            height: 120,
            borderRadius: 20,
          ),

          const SizedBox(height: 20),

          // Shimmer for content sections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.roundedRectangle(
                  width: 200,
                  height: 24,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                const HorizontalPostListLoading(),

                const SizedBox(height: 24),

                ShimmerLoading.roundedRectangle(
                  width: 200,
                  height: 24,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                const HorizontalPostListLoading(),
              ],
            ),
          ),
        ],
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
              // Avatar with tap action
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                    const EditProfileScreen(isEditProfile: true),
                  ),
                ),
                child: Hero(
                  tag: 'profile-avatar',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: vPrimaryColor.withAlpha(26),
                      border: Border.all(color: vPrimaryColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: vPrimaryColor.withAlpha(40),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: userProfile?.avatarPath != null
                          ? DecorationImage(
                        image: FileImage(File(userProfile!.avatarPath!)),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: userProfile?.avatarPath == null
                        ? const Icon(Icons.person,
                        color: vPrimaryColor, size: 30)
                        : null,
                  ),
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
          final postsAsync = ref.watch(postedPostsProvider);

          return postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return _buildEmptyPostsCard(
                  'No posts yet',
                  'Your published posts will appear here',
                  Icons.post_add,
                );
              }

              // Take just the most recent 5 posts
              final recentPosts = posts.take(5).toList();

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
            loading: () => const HorizontalPostListLoading(),
            error: (error, _) => Center(child: Text('Error: $error')),
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
          final postsAsync = ref.watch(scheduledPostsProvider);

          return postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return _buildEmptyPostsCard(
                  'No scheduled posts',
                  'Schedule posts to see them here',
                  Icons.schedule,
                );
              }

              // Order by scheduled time
              final scheduledPosts = List.from(posts)
                ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: scheduledPosts.length,
                itemBuilder: (context, index) {
                  final post = scheduledPosts[index];
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
            loading: () => const HorizontalPostListLoading(),
            error: (error, _) => Center(child: Text('Error: $error')),
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
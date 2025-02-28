// lib/presentation/screens/home/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/util/colors.dart';
import '../../../core/resources/data_state.dart';
import '../../../domain/usecases/home/get_user_usecase.dart';
import '../../../domain/entities/local_db/user_entity.dart';
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

/// A modern, visually engaging home screen with dynamic content sections
/// and personalized user experience.
///
/// Features:
/// - Time-based personalized greeting
/// - Quick action buttons for common tasks
/// - Beautiful category-based content browsing
/// - Activity summary and engagement metrics
/// - Modern visual design with subtle animations
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen] with default configuration.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// Current user profile information.
  UserEntity? _userProfile;

  /// Loading state for initial profile fetch.
  bool _isLoading = true;

  /// Animation controller for staggered animations
  late AnimationController _animationController;

  /// Animations for various UI elements
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

  /// Fetches the current user's profile from local database.
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final getUserUC = ref.read(getUserUseCaseProvider);
    final result = await getUserUC.call(params: GetUserParams(user.uid));

    if (result is DataSuccess<UserEntity?>) {
      setState(() {
        _userProfile = result.data;
        _isLoading = false;
      });

      // Start animations after data is loaded
      _animationController.forward();
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// Refreshes user data and post providers.
  Future<void> _refreshData() async {
    await _loadUserProfile();
    ref.invalidate(postedPostsProvider);
    ref.invalidate(scheduledPostsProvider);
    ref.invalidate(draftPostsProvider);

    // Reset and restart animations
    _animationController.reset();
    _animationController.forward();
  }

  /// Handles user logout process.
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red, // Making logout button red
                ),
                child: const Text('Log Out',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      body: _isLoading
          ? _buildShimmerLoading()
          : RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: SafeArea(
                child: Container(
                  width: width,
                  height: height,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/vouse_bg.jpg'),
                      fit: BoxFit.cover,
                      opacity:
                          0.8, // Slightly fade the background for better contrast
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Animated Header Section with User Profile and Greeting
                        FadeTransition(
                          opacity: _headerAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.2),
                              end: Offset.zero,
                            ).animate(_headerAnimation),
                            child: _buildHeader(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Quick Action Buttons
                        FadeTransition(
                          opacity: _actionsAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.2, 0),
                              end: Offset.zero,
                            ).animate(_actionsAnimation),
                            child: _buildQuickActions(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Content Sections with staggered animations
                        FadeTransition(
                          opacity: _contentAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(_contentAnimation),
                            child: _buildContentSections(),
                          ),
                        ),

                        // Extra space at bottom
                        const SizedBox(height: 100),
                      ],
                    ),
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
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 150,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Shimmer for content sections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                  3,
                  (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header section with user profile and greeting
  Widget _buildHeader() {
    // Time-based greeting
    // Time-based greeting fix
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
                      image: _userProfile?.avatarPath != null
                          ? DecorationImage(
                              image: FileImage(File(_userProfile!.avatarPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _userProfile?.avatarPath == null
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
                      _userProfile?.fullName ?? 'User',
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
          FutureBuilder(
              future: _getPostCounts(),
              builder: (context, snapshot) {
                final counts =
                    snapshot.data ?? {'posted': 0, 'scheduled': 0, 'drafts': 0};

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Posts', counts['posted'] ?? 0,
                        Icons.check_circle, vAccentColor),
                    _buildDivider(),
                    _buildStatItem('Scheduled', counts['scheduled'] ?? 0,
                        Icons.schedule, vPrimaryColor),
                    _buildDivider(),
                    _buildStatItem('Drafts', counts['drafts'] ?? 0,
                        Icons.edit_note, vBodyGrey),
                  ],
                );
              }),
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

  /// Builds an individual statistic item
  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: vBodyGrey,
          ),
        ),
      ],
    );
  }

  /// Builds quick action buttons
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: vBodyGrey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                'New Post',
                Icons.add_circle_outline,
                vPrimaryColor,
                () => _navigateToCreatePost(),
              ),
              _buildActionButton(
                'Schedule',
                Icons.schedule,
                vAccentColor,
                () => _navigateToScheduledPosts(),
              ),
              _buildActionButton(
                'Analytics',
                Icons.bar_chart,
                Colors.orange,
                () => _showFeatureComingSoon('Analytics'),
              ),
              _buildActionButton(
                'Settings',
                Icons.settings,
                vBodyGrey,
                () => _navigateToSettings(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an individual action button
  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: vBodyGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds content sections with recent posts
  Widget _buildContentSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent Posts Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '📊 Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: vPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _navigateToPostHistory(),
                child: const Text(
                  'See All',
                  style: TextStyle(color: vAccentColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        _buildRecentPostsSection(),

        const SizedBox(height: 24),

        // Upcoming Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '🗓️ Upcoming Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: vPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _navigateToScheduledPosts(),
                child: const Text(
                  'See All',
                  style: TextStyle(color: vAccentColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        _buildUpcomingPostsSection(),

        const SizedBox(height: 24),

        // Motivation Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: vPrimaryColor.withAlpha(51),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: vPrimaryColor.withAlpha(77)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: vPrimaryColor,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tip of the day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: vPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRandomTip(),
                      style: TextStyle(
                        fontSize: 14,
                        color: vBodyGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the recent posts section
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
      ),
    );
  }

  /// Builds the upcoming posts section
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
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16, top: 24),
                        child: SizedBox(
                          width: 280,
                          child: PostCard(post: post),
                        ),
                      ),
                      // Date badge - centered and elevated
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 16, // Match the right padding of the card
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: vAccentColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: vAccentColor.withAlpha(100),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _formatScheduleDate(post.scheduledAt!),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
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

  /// Formats a DateTime for the schedule badge
  String _formatScheduleDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date.isAtSameMomentAs(today)) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow, ${_formatTime(dateTime)}';
    } else {
      return DateFormat('MMM d, ${_formatTime(dateTime)}').format(dateTime);
    }
  }

  /// Formats time as HH:mm
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  /// Gets post counts for the stat blocks
  Future<Map<String, int>> _getPostCounts() async {
    final postedPostsAsync = await ref.read(postedPostsProvider.future);
    final scheduledPostsAsync = await ref.read(scheduledPostsProvider.future);
    final draftPostsAsync = await ref.read(draftPostsProvider.future);

    return {
      'posted': postedPostsAsync.length,
      'scheduled': scheduledPostsAsync.length,
      'drafts': draftPostsAsync.length,
    };
  }

  /// Shows a "Coming soon" toast for features in development
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

  /// Navigation helpers - using MaterialPageRoute instead of named routes
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
}

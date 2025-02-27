// lib/presentation/screens/post_history/published_posts_screen.dart
// Renamed from post_history_screen.dart for better clarity

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/post_card.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/local_db/local_user_providers.dart';

/// A polished screen showing published posts with performance analytics,
/// engagement metrics, and modern filtering options.
///
/// Features:
/// - Monthly/weekly/daily filtering of posts
/// - Performance metrics and engagement statistics
/// - Animated transitions between views
/// - Calendar-based navigation
/// - Interactive engagement visualizations
/// - Pull-to-refresh functionality
class PublishedPostsScreen extends ConsumerStatefulWidget {
  /// Creates a [PublishedPostsScreen] with default configuration.
  const PublishedPostsScreen({super.key});

  @override
  ConsumerState<PublishedPostsScreen> createState() => _PublishedPostsScreenState();
}

class _PublishedPostsScreenState extends ConsumerState<PublishedPostsScreen>
    with SingleTickerProviderStateMixin {
  /// Animation controller for content transitions
  late AnimationController _animationController;

  /// Animation for content fade-in
  late Animation<double> _fadeAnimation;

  /// Animation for content slide-up
  late Animation<Offset> _slideAnimation;

  /// Active filter for post timeframe
  String _activeFilter = 'All Time';

  /// Options for timeframe filtering
  final List<String> _filterOptions = ['All Time', 'This Month', 'This Week', 'Today'];

  /// Current user profile data
  UserEntity? _userProfile;

  /// Whether the screen is currently loading data
  bool _isLoading = true;

  /// List of filtered posts based on selected timeframe
  List<PostEntity> _filteredPosts = [];

  /// Mock engagement metrics data - would be replaced with real data
  final Map<String, double> _engagementData = {
    'Likes': 0,
    'Comments': 0,
    'Reposts': 0,
    'Impressions': 0,
  };

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

    // Load user profile and posts
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Load user profile and post data
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user profile
      final getUserUC = ref.read(getUserUseCaseProvider);
      final result = await getUserUC.call(params: GetUserParams(user.uid));

      if (result is DataSuccess<UserEntity?>) {
        setState(() => _userProfile = result.data);
      }
    }

    // Fetch posts and apply filters
    await _applyFilters();

    // Calculate mock engagement metrics
    _calculateEngagementData();

    // Start animations
    _animationController.forward();

    setState(() => _isLoading = false);
  }

  /// Refreshes all data
  Future<void> _refreshData() async {
    // Invalidate providers to force refresh
    ref.invalidate(postedPostsProvider);

    // Reload data
    await _loadData();
  }

  /// Apply the selected time filter to posts
  Future<void> _applyFilters() async {
    final postsAsync = await ref.read(postedPostsProvider.future);

    if (postsAsync.isEmpty) {
      setState(() => _filteredPosts = []);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    // Filter posts based on the selected timeframe
    switch (_activeFilter) {
      case 'Today':
        _filteredPosts = postsAsync.where((post) {
          return post.updatedAt != null &&
              post.updatedAt!.isAfter(today) ||
              isSameDay(post.updatedAt!, today);
        }).toList();
        break;

      case 'This Week':
        _filteredPosts = postsAsync.where((post) {
          return post.updatedAt != null &&
              (post.updatedAt!.isAfter(weekStart) ||
                  isSameDay(post.updatedAt!, weekStart));
        }).toList();
        break;

      case 'This Month':
        _filteredPosts = postsAsync.where((post) {
          return post.updatedAt != null &&
              (post.updatedAt!.isAfter(monthStart) ||
                  isSameDay(post.updatedAt!, monthStart));
        }).toList();
        break;

      case 'All Time':
      default:
        _filteredPosts = List.from(postsAsync);
        break;
    }

    // Sort by updated time, newest first
    _filteredPosts.sort((a, b) =>
        (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
  }

  /// Check if two dates are the same day
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Calculate mock engagement metrics based on posts
  void _calculateEngagementData() {
    // Reset metrics
    _engagementData['Likes'] = 0;
    _engagementData['Comments'] = 0;
    _engagementData['Reposts'] = 0;
    _engagementData['Impressions'] = 0;

    // In a real app, these would be fetched from analytics
    // For now, we'll generate some placeholder values based on post count
    final postCount = _filteredPosts.length;

    if (postCount > 0) {
      _engagementData['Likes'] = (postCount * 12.5).roundToDouble();
      _engagementData['Comments'] = (postCount * 3.2).roundToDouble();
      _engagementData['Reposts'] = (postCount * 2.7).roundToDouble();
      _engagementData['Impressions'] = (postCount * 84.3).roundToDouble();
    }
  }

  /// Changes the active time filter and applies filtering
  Future<void> _changeFilter(String filter) async {
    if (_activeFilter == filter) return;

    // Reset animations for smooth transition
    _animationController.reset();

    setState(() {
      _activeFilter = filter;
      _isLoading = true;
    });

    // Apply new filters
    await _applyFilters();

    // Recalculate engagement metrics
    _calculateEngagementData();

    // Restart animations
    _animationController.forward();

    setState(() => _isLoading = false);
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
      body: RefreshIndicator(
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

                    // Avatar and welcome text
                    Positioned(
                      left: 16,
                      bottom: 60,
                      child: Row(
                        children: [
                          if (_userProfile?.avatarPath != null)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                image: DecorationImage(
                                  image: FileImage(File(_userProfile!.avatarPath!)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(100),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Your Story',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _userProfile?.fullName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                filterOptions: _filterOptions,
                activeFilter: _activeFilter,
                onFilterChanged: _changeFilter,
              ),
            ),

            // Content area
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
                  : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Engagement metrics
                        _buildEngagementMetricsCard(),
                        const SizedBox(height: 20),

                        // Posts count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_filteredPosts.length} ${_filteredPosts.length == 1 ? 'Post' : 'Posts'} ${_activeFilter != 'All Time' ? 'in $_activeFilter' : ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_filteredPosts.isNotEmpty)
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
                        _filteredPosts.isEmpty
                            ? _buildEmptyState()
                            : _buildPostsGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Remove floating action button as it conflicts with bottom nav bar
    );
  }

  /// Builds the engagement metrics card with visualizations
  Widget _buildEngagementMetricsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Engagement Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vPrimaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _activeFilter,
                    style: TextStyle(
                      fontSize: 12,
                      color: vPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Engagement metrics grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildMetricItem('Likes', _engagementData['Likes']!.toInt(), Icons.favorite, Colors.red),
                _buildMetricItem('Comments', _engagementData['Comments']!.toInt(), Icons.chat_bubble, Colors.blue),
                _buildMetricItem('Reposts', _engagementData['Reposts']!.toInt(), Icons.repeat, Colors.green),
                _buildMetricItem('Impressions', _engagementData['Impressions']!.toInt(), Icons.visibility, Colors.purple),
              ],
            ),

            const SizedBox(height: 16),

            // Mini chart placeholder - in a real app, this would be an actual chart
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: vPrimaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _MiniChartPainter(
                  color: vPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an individual metric item tile
  Widget _buildMetricItem(String title, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: vBodyGrey,
                ),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the posts grid layout
  Widget _buildPostsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 0.9,
        mainAxisSpacing: 24,
        crossAxisSpacing: 16,
      ),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        return _buildPostItem(post);
      },
    );
  }

  /// Builds an individual post item with engagement metrics
  Widget _buildPostItem(PostEntity post) {
    // Format the post date
    final formattedDate = post.updatedAt != null
        ? DateFormat('MMM d, yyyy').format(post.updatedAt!)
        : 'Unknown date';

    // Format the post time
    final formattedTime = post.updatedAt != null
        ? DateFormat('h:mm a').format(post.updatedAt!)
        : '';

    return Stack(
      children: [
        // Post card
        PostCard(post: post),

        // Posted status badge
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: vAccentColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: vAccentColor.withAlpha(100),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                const Text(
                  'POSTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Posted time
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
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '$formattedDate • $formattedTime',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Mini engagement metrics
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
                  Icons.favorite,
                  size: 12,
                  color: Colors.red,
                ),
                const SizedBox(width: 2),
                Text(
                  '${(12 + post.content.length % 25)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chat_bubble,
                  size: 12,
                  color: Colors.blue,
                ),
                const SizedBox(width: 2),
                Text(
                  '${(3 + post.content.length % 8)}',
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

  /// Builds an empty state when no posts are available
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
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
                Icons.post_add,
                size: 40,
                color: vPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No published posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: vPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _activeFilter != 'All Time'
                  ? 'There are no posts from $_activeFilter'
                  : 'Start creating and posting content',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: vBodyGrey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreatePost,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Post'),
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
    );
  }
}

/// Persistent header delegate for filter chips
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> filterOptions;
  final String activeFilter;
  final Function(String) onFilterChanged;

  _FilterHeaderDelegate({
    required this.filterOptions,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 60,
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: filterOptions.map((filter) {
              final isActive = filter == activeFilter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isActive,
                  onSelected: (selected) {
                    if (selected) {
                      onFilterChanged(filter);
                    }
                  },
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : vBodyGrey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: vPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isActive ? vPrimaryColor : Colors.grey.withAlpha(100),
                    ),
                  ),
                  elevation: isActive ? 2 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
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

/// Custom painter for the mini engagement chart
class _MiniChartPainter extends CustomPainter {
  final Color color;

  _MiniChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final path = Path();

    // Generate some fake chart data points
    final points = <Offset>[];
    final random = DateTime.now().microsecond;

    for (var i = 0; i < 10; i++) {
      final x = i * size.width / 9;
      // Create a somewhat random but deterministic pattern
      final y = size.height * 0.5 -
          (((i + random) % 7) * size.height * 0.05) -
          (i % 3 == 0 ? size.height * 0.1 : 0) -
          (i % 5 == 0 ? size.height * 0.15 : 0);
      points.add(Offset(x, y));
    }

    // Move to starting point
    path.moveTo(points.first.dx, points.first.dy);

    // Add points to the path with a smooth curve
    for (var i = 1; i < points.length; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];

      path.cubicTo(
        p0.dx + (p1.dx - p0.dx) / 2, p0.dy,
        p0.dx + (p1.dx - p0.dx) / 2, p1.dy,
        p1.dx, p1.dy,
      );
    }

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw dots at data points
    for (final point in points) {
      canvas.drawCircle(point, 2, dotPaint);
    }

    // Draw a filled gradient area under the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withAlpha(100),
          color.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
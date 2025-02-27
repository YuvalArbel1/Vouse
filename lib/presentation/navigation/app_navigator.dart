// lib/presentation/navigation/app_navigator.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/screens/home/home_screen.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/presentation/screens/profile/profile_screen.dart';
import 'package:vouse_flutter/presentation/widgets/navigation/custom_bottom_nav.dart';

// Updated imports to use the renamed screens
import '../screens/post_history/published_posts_screen.dart';
import '../screens/post_history/upcoming_posts.dart';

/// State provider for the main navigation screens
final currentScreenProvider = StateProvider<int>((ref) => 0);

/// An app-wide navigator that handles main navigation with bottom nav bar
class AppNavigator extends ConsumerStatefulWidget {
  const AppNavigator({super.key});

  @override
  ConsumerState<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends ConsumerState<AppNavigator> {
  // List of screens to navigate between
  final List<Widget> _screens = [
    const HomeScreen(),
    const PublishedPostsScreen(),
    const UpcomingPostsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Reset system UI for consistent navigation
    _resetSystemUI();
  }

  /// Reset system UI overlays to ensure navbar is visible
  void _resetSystemUI() {
    // Ensure system UI is properly configured for bottom nav
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  /// Navigate to create post screen
  void _navigateToCreatePost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current selected index
    final currentIndex = ref.watch(currentScreenProvider);

    // Get bottom padding for safe area
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      // Use IndexedStack to maintain state of each screen
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      // SafeArea only on bottom to respect system navigation
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: CustomBottomNavBar(
          onTabSelected: (index) => ref.read(currentScreenProvider.notifier).state = index,
          onCreatePostPressed: () => _navigateToCreatePost(context),
          currentIndex: currentIndex,
        ),
      ),
      extendBody: true, // Makes content go behind the bottom nav for transparency
    );
  }
}
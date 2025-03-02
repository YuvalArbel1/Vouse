// lib/presentation/navigation/app_navigator.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/screens/home/home_screen.dart';
import 'package:vouse_flutter/presentation/screens/profile/profile_screen.dart';
import 'package:vouse_flutter/presentation/widgets/navigation/custom_bottom_nav.dart';
import 'package:vouse_flutter/core/util/colors.dart';

// Updated imports to use the renamed screens
import '../../core/util/ui_settings.dart';
import '../screens/post_history/published_posts_screen.dart';
import '../screens/post_history/upcoming_posts.dart';
import '../providers/navigation/navigation_service.dart';

// State provider for the main navigation screens
final currentScreenProvider = StateProvider<int>((ref) => 0);

/// An app-wide navigator that handles main navigation with bottom nav bar
/// and supports edge-to-edge layout for modern, immersive UI.
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
    UiSettings.hideSystemNavBar();
  }

  /// Navigate to create post screen
  void _navigateToCreatePost(BuildContext context) {
    ref.read(navigationServiceProvider).navigateToCreatePost(context);
  }

  @override
  Widget build(BuildContext context) {
    // Get current selected index
    final currentIndex = ref.watch(currentScreenProvider);

    // Get bottom padding for safe area
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ensure consistent edge-to-edge style across the app
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // Use IndexedStack to maintain state of each screen
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ),

        // Custom bottom navigation bar with proper padding
        bottomNavigationBar: Container(
          // Add a subtle gradient background for the nav bar area
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withAlpha(0),
                Colors.white.withAlpha(229),
                Colors.white,
              ],
              stops: const [0.0, 0.2, 0.6],
            ),
          ),
          // Add bottom padding for system navigation
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: CustomBottomNavBar(
            onTabSelected: (index) =>
            ref.read(currentScreenProvider.notifier).state = index,
            onCreatePostPressed: () => _navigateToCreatePost(context),
            currentIndex: currentIndex,
          ),
        ),

        // Make content go behind the bottom nav for transparency
        extendBody: true,
        // Make content go behind the app bar
        extendBodyBehindAppBar: true,
        // Set background to match app theme
        backgroundColor: vAppLayoutBackground,
      ),
    );
  }
}

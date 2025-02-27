// lib/presentation/navigation/app_navigator.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/screens/home/home_screen.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/presentation/screens/profile/profile_screen.dart';
import 'package:vouse_flutter/presentation/widgets/navigation/custom_bottom_nav.dart';

// Screens for the bottom navigation
import '../screens/post_history/post_history_screen.dart';
import '../screens/post_history/scheduled_posts_screen.dart';

/// State provider for the main navigation screens
final currentScreenProvider = StateProvider<Widget>((ref) => const HomeScreen());

/// An app-wide navigator that handles main navigation with bottom nav bar
class AppNavigator extends ConsumerStatefulWidget {
  const AppNavigator({super.key});

  @override
  ConsumerState<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends ConsumerState<AppNavigator> {
  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final currentScreen = ref.watch(currentScreenProvider);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: currentScreen,
      ),
      // SafeArea only on bottom to respect system navigation
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: CustomBottomNavBar(
          onTabSelected: (index) => _navigateToTab(ref, index),
          onCreatePostPressed: () => _navigateToCreatePost(context),
        ),
      ),
      extendBody: true, // Makes content go behind the bottom nav for transparency
    );
  }

  /// Navigate to the selected tab
  void _navigateToTab(WidgetRef ref, int index) {
    Widget screen;

    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const PostHistoryScreen();
        break;
      case 2:
        screen = const ScheduledPostsScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        screen = const HomeScreen();
    }

    ref.read(currentScreenProvider.notifier).state = screen;
  }

  /// Navigate to the create post screen
  void _navigateToCreatePost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }
}
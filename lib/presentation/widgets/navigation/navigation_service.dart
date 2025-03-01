// lib/presentation/widgets/navigation/navigation_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import 'package:vouse_flutter/presentation/screens/auth/signup.dart';
import 'package:vouse_flutter/presentation/screens/auth/verification_pending_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/presentation/screens/post/select_location_screen.dart';
import 'package:vouse_flutter/presentation/screens/post_history/published_posts_screen.dart';
import 'package:vouse_flutter/presentation/screens/post_history/upcoming_posts.dart';
import 'package:vouse_flutter/presentation/screens/profile/profile_screen.dart';
import 'package:vouse_flutter/presentation/navigation/app_navigator.dart';

/// A service that manages app navigation.
///
/// This centralizes navigation logic and provides consistent
/// navigation methods for use throughout the app.
///
/// Features:
/// - Consistent navigation patterns
/// - Animation options
/// - Support for route transitions
/// - Named routes support
/// - Stack management
class NavigationService {
  /// Navigate to the app navigator (main flow)
  void navigateToAppNavigator(BuildContext context, {bool clearStack = false}) {
    _navigate(context, const AppNavigator(), clearStack: clearStack);
  }

  /// Navigate to the sign in screen
  void navigateToSignIn(BuildContext context, {bool clearStack = false}) {
    _navigate(context, const SignInScreen(), clearStack: clearStack);
  }

  /// Navigate to the sign up screen
  void navigateToSignUp(BuildContext context) {
    _navigate(context, const SignUpScreen());
  }

  /// Navigate to the verification pending screen
  void navigateToVerificationPending(BuildContext context,
      {bool clearStack = false}) {
    _navigate(context, const VerificationPendingScreen(),
        clearStack: clearStack);
  }

  /// Navigate to the create post screen
  void navigateToCreatePost(BuildContext context, {bool animate = true}) {
    if (animate) {
      _animateToScreen(context, const CreatePostScreen());
    } else {
      _navigate(context, const CreatePostScreen());
    }
  }

  /// Navigate to the published posts screen
  void navigateToPublishedPosts(BuildContext context) {
    _navigate(context, const PublishedPostsScreen());
  }

  /// Navigate to the upcoming posts screen
  void navigateToUpcomingPosts(BuildContext context) {
    _navigate(context, const UpcomingPostsScreen());
  }

  /// Navigate to the profile screen
  void navigateToProfile(BuildContext context) {
    _navigate(context, const ProfileScreen());
  }

  /// Navigate to the edit profile screen
  void navigateToEditProfile(BuildContext context,
      {bool isEditProfile = false, required bool clearStack}) {
    _navigate(context, EditProfileScreen(isEditProfile: isEditProfile),
        clearStack: clearStack);
  }

  /// Navigate to location selection screen
  void navigateToLocationSelection(BuildContext context) {
    _slideUpScreen(context, const SelectLocationScreen());
  }

  /// Navigate back
  void navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Navigate back to a specific screen type
  void navigateBackTo<T extends Widget>(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      if (route is MaterialPageRoute) {
        final widget = route.builder(context);
        return widget is T;
      }
      return false;
    });
  }

  /// Helper method to navigate to a screen
  void _navigate(BuildContext context, Widget screen,
      {bool clearStack = false}) {
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => screen),
        (route) => false,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  /// Helper method to animate to a screen with custom transition
  void _animateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  /// Helper method for sliding screens up from bottom
  void _slideUpScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          // Fade effect combined with slide
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Helper method to show fullscreen dialog
  void showFullscreenDialog(BuildContext context, Widget dialog) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => dialog,
        fullscreenDialog: true,
      ),
    );
  }
}

/// Provider for the navigation service
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});

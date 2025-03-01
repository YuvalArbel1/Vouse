// lib/presentation/navigation/navigation_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import 'package:vouse_flutter/presentation/screens/auth/signup.dart';
import 'package:vouse_flutter/presentation/screens/auth/verification_pending_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/presentation/screens/post_history/published_posts_screen.dart';
import 'package:vouse_flutter/presentation/screens/post_history/upcoming_posts.dart';
import 'package:vouse_flutter/presentation/screens/profile/profile_screen.dart';
import 'package:vouse_flutter/presentation/navigation/app_navigator.dart';

/// A service that manages app navigation.
///
/// This centralizes navigation logic and provides consistent
/// navigation methods for use throughout the app.
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
  void navigateToVerificationPending(BuildContext context, {bool clearStack = false}) {
    _navigate(context, const VerificationPendingScreen(), clearStack: clearStack);
  }

  /// Navigate to the create post screen
  void navigateToCreatePost(BuildContext context) {
    _navigate(context, const CreatePostScreen());
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
  void navigateToEditProfile(BuildContext context, {bool isEditProfile = false, required bool clearStack}) {
    _navigate(context, EditProfileScreen(isEditProfile: isEditProfile));
  }

  /// Navigate back
  void navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Helper method to navigate to a screen
  void _navigate(BuildContext context, Widget screen, {bool clearStack = false}) {
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
}

/// Provider for the navigation service
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});
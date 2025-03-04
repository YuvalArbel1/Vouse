// lib/presentation/providers/navigation/navigation_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import 'package:vouse_flutter/presentation/screens/auth/signup.dart';
import 'package:vouse_flutter/presentation/screens/auth/verification_pending_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import 'package:vouse_flutter/presentation/screens/post/create_post_screen.dart';
import 'package:vouse_flutter/presentation/screens/post/select_location_screen.dart';
import 'package:vouse_flutter/presentation/navigation/app_navigator.dart';

import '../../../domain/entities/local_db/post_entity.dart';

/// The single source of truth for navigation in the app.
///
/// Always use this service instead of direct Navigator calls to ensure
/// consistent navigation behavior, enable analytics tracking, and
/// support future navigation patterns like deep linking.
class NavigationService {
  final Ref _ref;

  /// Constructor that receives Ref for provider access
  NavigationService(this._ref);

  /// Navigate to a specific tab in the main app navigator
  /// This preserves the bottom navigation bar
  void navigateToMainTab(BuildContext context, int tabIndex) {
    // Update the tab index in the provider
    _ref.read(currentScreenProvider.notifier).state = tabIndex;

    // If we've navigated away from AppNavigator, return to it
    Navigator.of(context).popUntil(
        (route) => route.settings.name == 'app_navigator' || route.isFirst);
  }

  /// Navigate to the app navigator (main flow)
  void navigateToAppNavigator(BuildContext context, {bool clearStack = false}) {
    _navigate(context, const AppNavigator(),
        routeName: 'app_navigator', clearStack: clearStack);
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

  /// Navigate to the published posts screen (tab 1)
  void navigateToPublishedPosts(BuildContext context) {
    navigateToMainTab(context, 1); // Switch to posts tab
  }

  /// Navigate to the upcoming posts screen (tab 2)
  void navigateToUpcomingPosts(BuildContext context) {
    navigateToMainTab(context, 2); // Switch to upcoming tab
  }

  /// Navigate to the profile screen (tab 3)
  void navigateToProfile(BuildContext context) {
    navigateToMainTab(context, 3); // Switch to profile tab
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

  /// Navigate to edit a draft post
  void navigateToEditDraft(BuildContext context, PostEntity draft) {
    _navigate(context, CreatePostScreen(draftToEdit: draft));
  }

  /// Navigate back
  void navigateBack<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  /// Helper method to show confirmation dialog
  /// Returns true if confirmed, false otherwise
  Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Helper method to navigate to a screen
  void _navigate(BuildContext context, Widget screen,
      {bool clearStack = false, String? routeName}) {
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            settings: routeName != null ? RouteSettings(name: routeName) : null,
            builder: (_) => screen),
        (route) => false,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
            settings: routeName != null ? RouteSettings(name: routeName) : null,
            builder: (_) => screen),
      );
    }
  }

  /// Helper method to animate to a screen with custom transition
  void _animateToScreen(BuildContext context, Widget screen,
      {String? routeName}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        settings: routeName != null ? RouteSettings(name: routeName) : null,
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
  void _slideUpScreen(BuildContext context, Widget screen,
      {String? routeName}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        settings: routeName != null ? RouteSettings(name: routeName) : null,
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

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
}

/// Provider for the navigation service that includes Ref
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService(ref);
});

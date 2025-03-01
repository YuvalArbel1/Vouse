// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';
import 'package:vouse_flutter/presentation/widgets/navigation/navigation_service.dart';

import '../../widgets/common/loading/full_screen_loading.dart';

/// Profile screen shows user information and account settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Use Future.microtask to defer profile loading until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserProfile();
    });
  }

  /// Refreshes the user profile data safely
  Future<void> _refreshUserProfile() async {
    try {
      setState(() => _isLoading = true);

      await ref.read(userProfileProvider.notifier).loadUserProfile();
    } catch (e) {
      // Use a more production-friendly logging approach
      debugPrint('Profile refresh error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handles user logout
  Future<void> _handleLogout() async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => navigator.pop(true),
                child:
                    const Text('Log Out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(firebaseAuthNotifierProvider.notifier).signOut();

      final authState = ref.read(firebaseAuthNotifierProvider);

      if (authState is DataSuccess<void>) {
        ref
            .read(navigationServiceProvider)
            .navigateToSignIn(context, clearStack: true);
      } else if (authState is DataFailed<void>) {
        final errorMsg = authState.error?.error ?? 'Unknown error';
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Logout failed: $errorMsg')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Consume the profile state
    final userProfileState = ref.watch(userProfileProvider);

    // Check if loading state is active or user profile is loading
    final isLoading = _isLoading ||
        userProfileState.loadingState == UserProfileLoadingState.loading;

    // If there's an error, show a snackbar or error message
    if (userProfileState.loadingState == UserProfileLoadingState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userProfileState.errorMessage ?? 'Failed to load profile',
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      body: isLoading
          ? const FullScreenLoading(message: 'Loading profile...')
          : SafeArea(
              child: Container(
                width: width,
                height: height,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/vouse_bg.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Rest of your existing profile screen content remains the same
                      // ...
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

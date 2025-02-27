// lib/presentation/screens/home/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/util/colors.dart';
import '../../../core/resources/data_state.dart';
import '../../../domain/usecases/home/get_user_usecase.dart';
import '../../../domain/entities/local_db/user_entity.dart';
import '../../providers/local_db/local_user_providers.dart';
import '../../providers/auth/firebase/firebase_auth_notifier.dart';
import '../../widgets/post/post_preview/multi_browse_carousel.dart';
import '../post/create_post_screen.dart';
import '../auth/signin.dart';
import '../home/edit_profile_screen.dart';

/// A comprehensive home screen with a dynamic, multi-browse carousel layout.
///
/// Features:
/// - Sleek user profile information
/// - Dynamic multi-browse carousel
/// - Refresh and logout actions
/// - Floating action button for creating new posts
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen] with default configuration.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Current user profile information.
  UserEntity? _userProfile;

  /// Loading state for initial profile fetch.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Remove splash screen and load user profile after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _loadUserProfile();
    });
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
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// Refreshes user data and post providers.
  void _refreshData() {
    _loadUserProfile();
  }

  /// Navigates to the Create Post screen.
  Future<void> _navigateToCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    _refreshData();
  }

  /// Handles user logout process.
  Future<void> _handleLogout() async {
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SafeArea(
          child: Container(
            width: context.width(),
            height: context.height(),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/vouse_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom app bar with user profile
                  _buildCustomAppBar(),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        // Dynamic Multi-Browse Carousel
                        DynamicMultiBrowseCarousel(),

                        // Extra space at bottom
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Floating Action Button for creating new posts
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePost,
        icon: const Icon(Icons.add),
        label: const Text("New Post"),
        backgroundColor: vPrimaryColor,
      ),
    );
  }

  /// Builds the custom app bar with user profile and actions.
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EditProfileScreen(isEditProfile: true),
              ),
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: vPrimaryColor.withAlpha(30),
                image: _userProfile?.avatarPath != null
                    ? DecorationImage(
                  image: FileImage(File(_userProfile!.avatarPath!)),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: _userProfile?.avatarPath == null
                  ? const Icon(Icons.person, color: vPrimaryColor)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey ${_userProfile?.fullName ?? 'there'}!',
                  style: boldTextStyle(size: 18),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: secondaryTextStyle(size: 12),
                ),
              ],
            ),
          ),

          // Action Buttons
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }
}
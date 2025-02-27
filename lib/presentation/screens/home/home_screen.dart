// lib/presentation/screens/home/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import '../../../core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../providers/auth/firebase/firebase_auth_notifier.dart';
import '../../providers/home/home_posts_providers.dart';
import '../../providers/local_db/local_user_providers.dart';
import '../post/create_post_screen.dart';

import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_card.dart';

/// An enhanced Home screen that displays:
/// - User profile with avatar and greeting
/// - Three horizontal rows of posts:
///   - Posted
///   - Scheduled
///   - Drafts
///
/// Includes an AppBar with refresh and logout buttons, plus a FAB for creating new posts.
/// The screen automatically refreshes when returning from the Create Post screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  UserEntity? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Remove the native splash screen after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _loadUserProfile();
    });
  }

  /// Loads the user profile from the local database
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

  /// Refreshes all post data by invalidating the providers.
  /// This forces Riverpod to re-fetch the data from the repositories.
  void _refreshData() {
    ref.invalidate(draftPostsProvider);
    ref.invalidate(scheduledPostsProvider);
    ref.invalidate(postedPostsProvider);
    _loadUserProfile();
  }

  /// Navigates to the Create Post screen and refreshes data when returning.
  ///
  /// This ensures that any newly created drafts or scheduled posts will
  /// immediately appear in the UI when the user returns to this screen.
  Future<void> _navigateToCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );

    // Refresh data when we return from create post screen
    _refreshData();
  }

  /// Navigates to the Edit Profile screen and refreshes data when returning.
  Future<void> _navigateToEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen(isEditProfile: true)),
    );

    // Refresh user profile when we return
    _loadUserProfile();
  }

  /// Handles the logout process.
  /// Uses [firebaseAuthNotifierProvider] to sign out. If successful, navigates to [SignInScreen].
  Future<void> _handleLogout() async {
    // Sign out asynchronously.
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
    // Watch the providers for real-time updates
    final draftsAsync = ref.watch(draftPostsProvider);
    final scheduledAsync = ref.watch(scheduledPostsProvider);
    final postedAsync = ref.watch(postedPostsProvider);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Posted section
                        _buildSectionHeader('Posted', Icons.check_circle),
                        const SizedBox(height: 8),
                        postedAsync.when(
                          data: (posted) => _buildPostsRow(posted),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, st) => Text('Error loading posted: $err'),
                        ),
                        const SizedBox(height: 24),

                        // Scheduled section
                        _buildSectionHeader('Scheduled', Icons.schedule),
                        const SizedBox(height: 8),
                        scheduledAsync.when(
                          data: (scheduled) => _buildPostsRow(scheduled),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, st) => Text('Error loading scheduled: $err'),
                        ),
                        const SizedBox(height: 24),

                        // Drafts section
                        _buildSectionHeader('Drafts', Icons.edit_note),
                        const SizedBox(height: 8),
                        draftsAsync.when(
                          data: (drafts) => _buildPostsRow(drafts),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, st) => Text('Error loading drafts: $err'),
                        ),

                        // Extra space at bottom for FAB
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Button to create new post
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePost,
        icon: const Icon(Icons.add),
        label: const Text("New Post"),
        backgroundColor: vPrimaryColor,
      ),
    );
  }

  /// Builds a custom app bar with user profile information and actions.
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
          // Avatar
          GestureDetector(
            onTap: _navigateToEditProfile,
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

          // User info
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

          // Action buttons
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

  /// Builds a section header with title and icon.
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: vPrimaryColor),
        const SizedBox(width: 8),
        Text(title, style: boldTextStyle(size: 18)),
      ],
    );
  }

  /// Builds a horizontally scrolling row of [PostCard]s.
  /// If empty => show a quick customized empty state.
  Widget _buildPostsRow(List<PostEntity> posts) {
    if (posts.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: vPrimaryColor.withAlpha(50)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 40, color: vPrimaryColor.withAlpha(150)),
            const SizedBox(height: 8),
            Text(
              'No posts yet',
              style: secondaryTextStyle(color: vBodyGrey),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 350,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        itemBuilder: (ctx, index) {
          final p = posts[index];
          return PostCard(post: p); // each card is 320x350
        },
      ),
    );
  }
}
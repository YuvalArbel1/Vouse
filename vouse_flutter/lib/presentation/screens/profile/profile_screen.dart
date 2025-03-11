// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/providers/auth/x/twitter_connection_provider.dart';
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';
import 'package:vouse_flutter/presentation/screens/profile/profile_twitter_section.dart';
import 'package:vouse_flutter/presentation/widgets/common/loading/full_screen_loading.dart';
import 'package:vouse_flutter/presentation/providers/navigation/navigation_service.dart';

// Import the widgets
import 'package:vouse_flutter/presentation/widgets/profile/profile_header_widget.dart';
import 'package:vouse_flutter/presentation/widgets/profile/settings_tile_widget.dart';
import 'package:vouse_flutter/presentation/widgets/profile/settings_section_widget.dart';
import 'package:vouse_flutter/presentation/widgets/profile/about_dialog_content.dart';
import 'package:vouse_flutter/presentation/widgets/profile/legal_text.dart';

import '../../widgets/profile/notification_settings_section.dart';

/// A screen that displays the user's profile and provides access to account settings.
///
/// Features:
/// - User avatar and profile information display
/// - Account settings (edit profile, connect/disconnect X)
/// - App information (about, terms, privacy policy)
/// - Logout functionality
/// - Real-time X connection status updates via provider
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  /// Whether the profile is currently loading
  bool _isLoading = false;

  /// Animation controller for fade-in effects
  late AnimationController _animationController;

  /// Fade animation for smooth UI appearance
  late Animation<double> _fadeAnimation;

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

    // Load profile data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Refresh connection status whenever the screen becomes visible
    // This ensures changes made in other screens are reflected here
    if (!_isLoading) {
      // Only check connection status, don't reload the entire profile
      // to avoid unnecessary loading indicators
      ref.read(twitterConnectionProvider.notifier).checkConnectionStatus();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Refreshes the user profile data safely
  ///
  /// Loads the user profile from the provider and refreshes X connection status.
  /// Also starts the fade-in animation after data is loaded.
  Future<void> _refreshUserProfile() async {
    try {
      setState(() => _isLoading = true);

      // Direct call to load profile
      await ref.read(userProfileProvider.notifier).loadUserProfile();

      // Also refresh the Twitter connection status
      await ref
          .read(twitterConnectionProvider.notifier)
          .checkConnectionStatus();

      // Start animations after data is loaded
      _animationController.forward();
    } catch (e) {
      debugPrint('Profile refresh error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handles user logout
  ///
  /// Shows a confirmation dialog and signs out the user if confirmed.
  /// Navigates to the sign-in screen on successful logout.
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(navigationServiceProvider)
                    .navigateBack(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => ref
                    .read(navigationServiceProvider)
                    .navigateBack(context, true),
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

      if (!mounted) return;

      final authState = ref.read(firebaseAuthNotifierProvider);
      if (authState is DataSuccess<void>) {
        ref
            .read(navigationServiceProvider)
            .navigateToSignIn(context, clearStack: true);
      } else if (authState is DataFailed<void>) {
        final errorMsg = authState.error?.error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $errorMsg')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Navigates to the edit profile screen
  void _navigateToEditProfile() {
    ref
        .read(navigationServiceProvider)
        .navigateToEditProfile(context, isEditProfile: true, clearStack: false);
  }

  /// Shows the about Vouse dialog
  void _showAboutVouse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Vouse'),
        content: const AboutDialogContent(),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(navigationServiceProvider).navigateBack(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shows the terms of service dialog
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text(LegalText.getTermsOfService()),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(navigationServiceProvider).navigateBack(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shows the privacy policy dialog
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(LegalText.getPrivacyPolicy()),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(navigationServiceProvider).navigateBack(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get user profile from provider
    final userProfileState = ref.watch(userProfileProvider);
    final user = userProfileState.user;

    // Watch X connection status directly from provider
    // This ensures real-time updates when connecting or disconnecting
    final twitterConnectionState = ref.watch(twitterConnectionProvider);
    final isXConnected = twitterConnectionState.connectionState ==
        TwitterConnectionState.connected;

    // Determine if loading is in progress
    final isLoading = _isLoading ||
        userProfileState.loadingState == UserProfileLoadingState.loading ||
        userProfileState.loadingState == UserProfileLoadingState.initial;

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      body: isLoading
          ? const FullScreenLoading(message: 'Loading profile...')
          : RefreshIndicator(
              onRefresh: _refreshUserProfile,
              child: SafeArea(
                child: Container(
                  // Add background image like in home screen
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/vouse_bg.jpg'),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Profile Header with Avatar and Logout
                          ProfileHeaderWidget(
                            user: user,
                            isXConnected: isXConnected, // Use provider value
                            onSettingsTap: _navigateToEditProfile,
                            onAvatarTap: _navigateToEditProfile,
                          ),

                          // Main Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),

                                // Account Settings Section
                                SettingsSectionWidget(
                                  title: 'Account Settings',
                                  children: [
                                    SettingsTileWidget(
                                      title: 'Edit Profile',
                                      icon: Icons.person_outline,
                                      iconColor: vPrimaryColor,
                                      onTap: _navigateToEditProfile,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Twitter Integration Section
                                const ProfileTwitterSection(),

                                const SizedBox(height: 24),

                                const NotificationSettingsSection(),

                                const SizedBox(height: 24),

                                // App Information Section
                                SettingsSectionWidget(
                                  title: 'App Information',
                                  children: [
                                    SettingsTileWidget(
                                      title: 'About Vouse',
                                      icon: Icons.info_outline,
                                      iconColor: vPrimaryColor,
                                      onTap: _showAboutVouse,
                                    ),
                                    SettingsTileWidget(
                                      title: 'Terms of Service',
                                      icon: Icons.description_outlined,
                                      iconColor: vPrimaryColor,
                                      onTap: _showTermsOfService,
                                    ),
                                    SettingsTileWidget(
                                      title: 'Privacy Policy',
                                      icon: Icons.privacy_tip_outlined,
                                      iconColor: vPrimaryColor,
                                      onTap: _showPrivacyPolicy,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 40),

                                // Logout Button
                                Center(
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: ElevatedButton.icon(
                                      onPressed: _handleLogout,
                                      icon: const Icon(Icons.logout,
                                          color: Colors.white),
                                      label: const Text('Logout',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade400,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Version info
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'Vouse v1.0.0',
                                    style: TextStyle(
                                      color: vBodyGrey.withAlpha(150),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                // Bottom padding for safe area
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

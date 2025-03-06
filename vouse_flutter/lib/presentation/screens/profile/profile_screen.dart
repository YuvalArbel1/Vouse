// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/providers/auth/x/x_connection_provider.dart';
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';
import 'package:vouse_flutter/presentation/widgets/common/loading/full_screen_loading.dart';
import 'package:vouse_flutter/presentation/providers/navigation/navigation_service.dart';
import 'package:vouse_flutter/core/util/twitter_x_auth_util.dart';

// Import the widgets
import 'package:vouse_flutter/presentation/widgets/profile/profile_header_widget.dart';
import 'package:vouse_flutter/presentation/widgets/profile/settings_tile_widget.dart';
import 'package:vouse_flutter/presentation/widgets/profile/settings_section_widget.dart';
import 'package:vouse_flutter/presentation/widgets/profile/about_dialog_content.dart';
import 'package:vouse_flutter/presentation/widgets/profile/legal_text.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isXConnected = false;
  bool _isConnectingX = false;
  late AnimationController _animationController;
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
      _checkXConnection();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Refreshes the user profile data safely
  Future<void> _refreshUserProfile() async {
    try {
      setState(() => _isLoading = true);

      // Direct call to load profile
      await ref.read(userProfileProvider.notifier).loadUserProfile();
      await _checkXConnection();

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

  /// Check if X (Twitter) is connected
  Future<void> _checkXConnection() async {
    // Use the connection status directly from the provider
    final isConnected = ref.read(xConnectionStatusProvider);
    if (mounted) {
      setState(() {
        _isXConnected = isConnected;
      });
    }

    // Also refresh the provider's connection status (optional)
    ref.read(xConnectionStatusProvider.notifier).checkConnection();
  }

  /// Connect to X (Twitter)
  Future<void> _connectToX() async {
    setState(() => _isConnectingX = true);

    final success = await TwitterXAuthUtil.connectToX(
      ref,
      setLoadingState: (loading) => setState(() => _isLoading = loading),
      mounted: mounted,
    );

    if (mounted) {
      setState(() {
        _isConnectingX = false;
        if (success) {
          _isXConnected = true;
        }
      });
    }
  }

  /// Disconnect from X (Twitter)
  Future<void> _disconnectFromX() async {
    final success = await TwitterXAuthUtil.disconnectFromX(
      context,
      ref,
      setLoadingState: (loading) => setState(() => _isLoading = loading),
      mounted: mounted,
    );

    if (success && mounted) {
      setState(() {
        _isXConnected = false;
      });
    }
  }

  /// Handles user logout
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

  void _navigateToEditProfile() {
    ref
        .read(navigationServiceProvider)
        .navigateToEditProfile(context, isEditProfile: true, clearStack: false);
  }

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
    final userProfileState = ref.watch(userProfileProvider);
    final user = userProfileState.user;

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
                            isXConnected: _isXConnected,
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
                                    SettingsTileWidget(
                                      title: _isXConnected
                                          ? 'Disconnect X Account'
                                          : 'Connect X Account',
                                      icon: Icons.link,
                                      iconColor: _isXConnected
                                          ? Colors.red
                                          : vPrimaryColor,
                                      onTap: _isXConnected
                                          ? _disconnectFromX
                                          : _connectToX,
                                      isLoading: _isConnectingX,
                                      isDestructive: _isXConnected,
                                    ),
                                  ],
                                ),

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

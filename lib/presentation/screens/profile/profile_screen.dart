// lib/presentation/screens/profile/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/providers/auth/x/x_auth_providers.dart';
import 'package:vouse_flutter/presentation/providers/auth/x/x_token_providers.dart';
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';
import 'package:vouse_flutter/presentation/widgets/common/loading/full_screen_loading.dart';
import 'package:vouse_flutter/presentation/providers/navigation/navigation_service.dart';

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
    final getTokensUC = ref.read(getXTokensUseCaseProvider);
    final result = await getTokensUC.call();

    if (result is DataSuccess && result.data?.accessToken != null) {
      if (mounted) {
        setState(() {
          _isXConnected = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isXConnected = false;
        });
      }
    }
  }

  /// Initiates Twitter OAuth sign-in flow, retrieves tokens, then stores them securely.
  /// If successful, updates UI state to reflect connected status.
  Future<void> _connectToX() async {
    setState(() {
      _isConnectingX = true;
      _isLoading = true;
    });

    try {
      // Start the sign-in flow.
      final signInUC = ref.read(signInToXUseCaseProvider);
      final result = await signInUC.call();
      if (!mounted) return;

      if (result is DataSuccess<XAuthTokens>) {
        final tokens = result.data!;
        final saveTokensUseCase = ref.read(saveXTokensUseCaseProvider);
        final saveResult = await saveTokensUseCase.call(params: tokens);
        if (!mounted) return;

        if (saveResult is DataSuccess<void>) {
          setState(() {
            _isXConnected = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('X account connected successfully')),
          );
        } else if (saveResult is DataFailed<void>) {
          final err = saveResult.error?.error ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error storing tokens: $err")),
          );
        }
      } else if (result is DataFailed<XAuthTokens>) {
        final errorMsg = result.error?.error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Twitter Auth Error: $errorMsg")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingX = false;
          _isLoading = false;
        });
      }
    }
  }

  /// Disconnect from X
  Future<void> _disconnectFromX() async {
    final shouldDisconnect = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Disconnect X Account'),
            content: const Text(
                'Are you sure you want to disconnect your X account?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Disconnect',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDisconnect) return;

    setState(() => _isLoading = true);

    try {
      final clearTokensUC = ref.read(clearXTokensUseCaseProvider);
      final result = await clearTokensUC.call();

      if (result is DataSuccess) {
        setState(() {
          _isXConnected = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('X account disconnected successfully')),
          );
        }
      } else if (result is DataFailed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to disconnect: ${result.error?.error}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text(_getTermsOfServiceText()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
          child: Text(_getPrivacyPolicyText()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getTermsOfServiceText() {
    return '''
Terms of Service

1. Acceptance of Terms
By accessing and using Vouse, you agree to be bound by these Terms of Service.

2. User Accounts
You are responsible for maintaining the security of your account and password. The app cannot and will not be liable for any loss or damage from your failure to comply with this security obligation.

3. Content Ownership
You retain ownership of any content you post through our service. By posting content, you grant us a non-exclusive license to use, display, and distribute your content.

4. Prohibited Activities
You agree not to use the app for any illegal purposes or to violate any laws in your jurisdiction.

5. Service Modifications
We reserve the right to modify or discontinue the service at any time.

6. Limitation of Liability
The app is provided "as is" without warranty of any kind.

7. Governing Law
These terms shall be governed by the laws of your country of residence.
''';
  }

  String _getPrivacyPolicyText() {
    return '''
Privacy Policy

1. Information We Collect
We collect information you provide directly to us, such as when you create an account, update your profile, or post content.

2. How We Use Information
We use your information to provide and improve our services, communicate with you, and personalize your experience.

3. Information Sharing
We do not sell your personal information to third parties. We may share information with third-party service providers who help us operate our services.

4. Security
We implement reasonable measures to help protect your personal information.

5. Data Retention
We store your information as long as necessary to provide our services or as required by law.

6. Your Rights
Depending on your location, you may have rights to access, correct, delete, or restrict the processing of your personal information.

7. Changes to This Policy
We may update this policy from time to time. We will notify you of any significant changes.
''';
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
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Profile Header with Avatar and Logout
                        _buildProfileHeader(user),

                        // Main Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // Account Settings Section
                              _buildSectionTitle('Account Settings'),
                              const SizedBox(height: 12),
                              _buildSettingsCard([
                                _buildSettingsTile(
                                  'Edit Profile',
                                  Icons.person_outline,
                                  vPrimaryColor,
                                  onTap: _navigateToEditProfile,
                                ),
                                _buildSettingsTile(
                                  _isXConnected
                                      ? 'Disconnect X Account'
                                      : 'Connect X Account',
                                  Icons.link,
                                  _isXConnected ? Colors.red : vPrimaryColor,
                                  onTap: _isXConnected
                                      ? _disconnectFromX
                                      : _connectToX,
                                ),
                              ]),

                              const SizedBox(height: 24),

                              // App Information Section
                              _buildSectionTitle('App Information'),
                              const SizedBox(height: 12),
                              _buildSettingsCard([
                                _buildSettingsTile(
                                  'About Vouse',
                                  Icons.info_outline,
                                  vPrimaryColor,
                                  onTap: () {},
                                ),
                                _buildSettingsTile(
                                  'Terms of Service',
                                  Icons.description_outlined,
                                  vPrimaryColor,
                                  onTap: _showTermsOfService,
                                ),
                                _buildSettingsTile(
                                  'Privacy Policy',
                                  Icons.privacy_tip_outlined,
                                  vPrimaryColor,
                                  onTap: _showPrivacyPolicy,
                                ),
                              ]),

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
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade400,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildProfileHeader(UserEntity? user) {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: vPrimaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                color: vPrimaryColor,
                onPressed: _navigateToEditProfile,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _navigateToEditProfile,
            child: Hero(
              tag: 'profile-avatar',
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Avatar container
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: vPrimaryColor.withAlpha(26),
                      border: Border.all(color: vPrimaryColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: vPrimaryColor.withAlpha(40),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: user?.avatarPath != null
                          ? DecorationImage(
                              image: FileImage(File(user!.avatarPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: user?.avatarPath == null
                        ? Icon(Icons.person, color: vPrimaryColor, size: 60)
                        : null,
                  ),
                  // Edit icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: vAccentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: vPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isXConnected ? 'Connected with X' : 'X not connected',
            style: TextStyle(
              fontSize: 14,
              color: _isXConnected ? vAccentColor : vBodyGrey,
              fontWeight: _isXConnected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: vPrimaryColor,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: tiles,
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, Color iconColor,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: _isConnectingX && title.contains('Connect') ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: _isConnectingX && title.contains('Connect')
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: title.contains('Disconnect') ? Colors.red : vBodyGrey,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

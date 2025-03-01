// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';
import 'package:vouse_flutter/presentation/widgets/common/loading/full_screen_loading.dart';
import 'package:vouse_flutter/presentation/widgets/common/common_ui_components.dart';

import '../../widgets/navigation/navigation_service.dart';

/// Profile screen shows user information and account settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
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
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldLogout) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(firebaseAuthNotifierProvider.notifier).signOut();

      if (!mounted) return;

      final authState = ref.read(firebaseAuthNotifierProvider);
      if (authState is DataSuccess<void>) {
        ref.read(navigationServiceProvider).navigateToSignIn(
            context,
            clearStack: true
        );
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
    ref.read(navigationServiceProvider).navigateToEditProfile(
        context,
        isEditProfile: true,
        clearStack: false
    );
  }

  void _showFeatureComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: vAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildProfileHeader(user),
                ),
              ),

              // Profile Actions
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚙️ Account Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(),
                      ],
                    ),
                  ),
                ),
              ),

              // App Information
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📱 App Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAppInfoCard(),
                      ],
                    ),
                  ),
                ),
              ),

              // Logout Button
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserEntity? user) {
    return VouseCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // User Avatar
              GestureDetector(
                onTap: _navigateToEditProfile,
                child: ProfileAvatarDisplay(
                  user: user,
                  size: 80,
                  showEditStyle: true,
                ),
              ),
              const SizedBox(width: 20),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      'Account since ${user?.dateOfBirth != null ? _formatDate(user!.dateOfBirth) : "2023"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: vBodyGrey,
                      ),
                    ),

                    // Edit Profile Button
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _navigateToEditProfile,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        foregroundColor: vPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // User Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Posts', '0', Icons.post_add),
              _buildVerticalDivider(),
              _buildStatItem('Engagement', '0', Icons.bar_chart),
              _buildVerticalDivider(),
              _buildStatItem('Scheduled', '0', Icons.schedule),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return VouseCard(
      padding: const EdgeInsets.all(0),
      borderRadius: 12,
      child: Column(
        children: [
          _buildSettingsTile(
            'Edit Profile',
            Icons.person_outline,
            onTap: _navigateToEditProfile,
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Notifications',
            Icons.notifications_none,
            onTap: () => _showFeatureComingSoon('Notifications'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Privacy & Security',
            Icons.security,
            onTap: () => _showFeatureComingSoon('Privacy & Security'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Connected Accounts',
            Icons.link,
            onTap: () => _showFeatureComingSoon('Connected Accounts'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return VouseCard(
      padding: const EdgeInsets.all(0),
      borderRadius: 12,
      child: Column(
        children: [
          _buildSettingsTile(
            'About Vouse',
            Icons.info_outline,
            onTap: () => _showFeatureComingSoon('About Vouse'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Help & Support',
            Icons.help_outline,
            onTap: () => _showFeatureComingSoon('Help & Support'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Terms of Service',
            Icons.description_outlined,
            onTap: () => _showFeatureComingSoon('Terms of Service'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Privacy Policy',
            Icons.privacy_tip_outlined,
            onTap: () => _showFeatureComingSoon('Privacy Policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: vPrimaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 70);
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withAlpha(100),
    );
  }

  Widget _buildStatItem(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: vPrimaryColor),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: vPrimaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: vBodyGrey,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
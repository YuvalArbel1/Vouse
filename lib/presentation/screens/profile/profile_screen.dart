// lib/presentation/screens/profile/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/providers/local_db/local_user_providers.dart';
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';

/// Profile screen shows user information and account settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserEntity? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Loads the user profile data
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: vAppLayoutBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                // Header with profile info
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile image
                      _buildProfileImage(),
                      const SizedBox(height: 16),

                      // User's name
                      Text(
                        _userProfile?.fullName ?? 'Your Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // User's email
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? 'email@example.com',
                        style: TextStyle(color: vBodyGrey),
                      ),

                      const SizedBox(height: 16),

                      // Edit profile button
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(isEditProfile: true),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: vPrimaryColor,
                          side: const BorderSide(color: vPrimaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Information Section
                _buildSection(
                  title: 'Account Information',
                  icon: Icons.person,
                  children: [
                    _buildInfoItem(
                      title: 'Date of Birth',
                      value: _userProfile?.dateOfBirth != null
                          ? '${_userProfile!.dateOfBirth.day}/${_userProfile!.dateOfBirth.month}/${_userProfile!.dateOfBirth.year}'
                          : 'Not set',
                      icon: Icons.cake,
                    ),
                    _buildInfoItem(
                      title: 'Gender',
                      value: _userProfile?.gender ?? 'Not set',
                      icon: Icons.people,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Connected Accounts Section
                _buildSection(
                  title: 'Connected Accounts',
                  icon: Icons.link,
                  children: [
                    _buildConnectionItem(
                      title: 'X (Twitter)',
                      isConnected: true,
                      icon: Icons.alternate_email,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Settings Section
                _buildSection(
                  title: 'Settings',
                  icon: Icons.settings,
                  children: [
                    _buildActionItem(
                      title: 'Notification Settings',
                      icon: Icons.notifications,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification settings'))
                        );
                      },
                    ),
                    _buildActionItem(
                      title: 'Privacy',
                      icon: Icons.privacy_tip,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy settings'))
                        );
                      },
                    ),
                    _buildActionItem(
                      title: 'Terms & Conditions',
                      icon: Icons.description,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terms & Conditions'))
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Logout button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: Size(width, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Extra space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the profile image with avatar
  Widget _buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: vPrimaryColor.withAlpha(26),
        border: Border.all(color: vPrimaryColor, width: 3),
        image: _userProfile?.avatarPath != null
            ? DecorationImage(
          image: FileImage(File(_userProfile!.avatarPath!)),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: _userProfile?.avatarPath == null
          ? const Icon(Icons.person, color: vPrimaryColor, size: 60)
          : null,
    );
  }

  /// Builds a section with a title and children
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: vPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: vPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Section content
          ...children,
        ],
      ),
    );
  }

  /// Builds an information item
  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: vBodyGrey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  title,
                  style: TextStyle(
                      fontSize: 12,
                      color: vBodyGrey
                  )
              ),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a connection status item
  Widget _buildConnectionItem({
    required String title,
    required bool isConnected,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: vBodyGrey, size: 20),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected ? vAccentColor.withAlpha(26) : Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isConnected ? 'Connected' : 'Connect',
              style: TextStyle(
                color: isConnected ? vAccentColor : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an action item
  Widget _buildActionItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: vBodyGrey, size: 20),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: vBodyGrey, size: 16),
          ],
        ),
      ),
    );
  }
}
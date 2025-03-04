// lib/presentation/widgets/profile/profile_header_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';

/// A stylish profile header widget displaying the user's avatar, name, and connection status.
///
/// Features:
/// - Large centered avatar with edit capability
/// - User's full name display
/// - X connection status indicator
/// - Clean white card with rounded corners and subtle shadow
/// - Hero animation support for avatar transitions
class ProfileHeaderWidget extends StatelessWidget {
  /// The user entity containing profile data
  final UserEntity? user;

  /// Whether the user has connected their X account
  final bool isXConnected;

  /// Callback when the settings icon is tapped
  final VoidCallback onSettingsTap;

  /// Callback when the avatar/edit icon is tapped
  final VoidCallback onAvatarTap;

  /// Creates a [ProfileHeaderWidget].
  const ProfileHeaderWidget({
    super.key,
    required this.user,
    required this.isXConnected,
    required this.onSettingsTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
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
                onPressed: onSettingsTap,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAvatarTap,
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
            isXConnected ? 'Connected with X' : 'X not connected',
            style: TextStyle(
              fontSize: 14,
              color: isXConnected ? vAccentColor : vBodyGrey,
              fontWeight: isXConnected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
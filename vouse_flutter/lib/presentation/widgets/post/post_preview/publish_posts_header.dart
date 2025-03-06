// lib/presentation/widgets/post/post_preview/published_posts_header.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/util/colors.dart';
import '../../../../domain/entities/local_db/user_entity.dart';

/// A stylish header widget for the published posts screen
class PublishedPostsHeader extends StatelessWidget {
  final UserEntity? userProfile;
  final int postCount;

  const PublishedPostsHeader({
    super.key,
    this.userProfile,
    required this.postCount,
  });

  String _getStoryLineEmoji() {
    if (postCount == 0) return '✍️';
    if (postCount < 5) return '🌱';
    if (postCount < 20) return '🌿';
    if (postCount < 50) return '🌳';
    return '🌲';
  }

  String _getStoryLine() {
    if (postCount == 0) return 'Your story is just beginning!';
    if (postCount < 5) return 'Your first steps into content creation';
    if (postCount < 20) return 'Building your unique voice';
    if (postCount < 50) return 'Crafting a powerful narrative';
    return 'A master of storytelling';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [vPrimaryColor, vPrimaryColor.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular profile image
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: userProfile?.avatarPath != null
                    ? FileImage(File(userProfile!.avatarPath!))
                    : null,
                child: userProfile?.avatarPath == null
                    ? Icon(Icons.person, color: vPrimaryColor, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getStoryLineEmoji()} Your Content Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStoryLine(),
                      style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('📝 Total Posts', postCount.toString()),
              _buildStatChip(
                  '🚀 Engagement', (postCount * 12.5).round().toString()),
              _buildStatChip(
                  '🌟 Progress', '${(postCount / 50 * 100).round()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

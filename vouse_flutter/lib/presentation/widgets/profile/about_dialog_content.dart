// lib/presentation/widgets/profile/about_dialog_content.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A widget that displays the about dialog content with formatted sections.
///
/// Features:
/// - Consistent section styling for about information
/// - Predefined application info sections
/// - Clean layout with proper spacing
/// - Easter egg on "Our Team" section that links to a YouTube video
class AboutDialogContent extends StatelessWidget {
  /// Creates an [AboutDialogContent] widget.
  const AboutDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAboutSection('✨ Welcome to Vouse!', _getAboutVouseIntro()),
          const SizedBox(height: 16),
          _buildAboutSection('🚀 Key Features', _getAboutVouseFeatures()),
          const SizedBox(height: 16),
          _buildTeamSection(context),
          const SizedBox(height: 16),
          _buildAboutSection('📱 Contact Us', _getAboutVouseContact()),
        ],
      ),
    );
  }

  /// Builds a section with a title and content
  Widget _buildAboutSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: vPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Builds the team section with an Easter egg
  Widget _buildTeamSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _launchEasterEgg(context),
          child: Row(
            children: [
              Text(
                '👥 Our Team',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: vPrimaryColor,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.touch_app,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getAboutVouseTeam(),
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Launches the YouTube Easter egg
  /// Launches the YouTube Easter egg
  void _launchEasterEgg(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Uri url = Uri.parse(
        'https://www.youtube.com/watch?v=K533gW3boIY&ab_channel=GEazyMusicVEVO');

    launchUrl(url, mode: LaunchMode.externalApplication).then((success) {
      if (!success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not launch YouTube')),
        );
      }
    }).catchError((e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    });
  }

  /// Returns the app introduction text
  String _getAboutVouseIntro() {
    return '''
Vouse is your all-in-one social media management tool designed to streamline your posting experience. Our app helps content creators, small businesses, and social media enthusiasts create, schedule, and publish their content with ease.

Launched in 2025, Vouse aims to simplify your social media workflow while maximizing engagement through smart scheduling and AI assistance.
''';
  }

  /// Returns the app features text
  String _getAboutVouseFeatures() {
    return '''
- 📝 AI-powered content creation
- 🗓️ Smart scheduling with best time predictions
- 📊 Post analytics and engagement tracking
- 📱 Multi-platform support (Starting with X/Twitter)
- 📷 Enhanced media management
- 📍 Location tagging
- 💾 Draft saving for work-in-progress
''';
  }

  /// Returns the team information text
  String _getAboutVouseTeam() {
    return '''
Vouse was created by a passionate team of developers dedicated to improving the social media experience. We combine expertise in mobile development, AI, and user experience design to create a tool that's both powerful and easy to use.

Our mission is to help you share your voice effectively in the noisy world of social media.
''';
  }

  /// Returns the contact information text
  String _getAboutVouseContact() {
    return '''
Email: vouse1studio@gmail.com
Twitter: @Vouse1Studio

We value your feedback and are constantly working to improve Vouse. Let us know how we can make it better for you!
''';
  }
}

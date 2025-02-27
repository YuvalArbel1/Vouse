// lib/presentation/widgets/post/post_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/screens/post/full_screen_image_preview.dart';

/// A post card that:
/// - If it's a draft, shows a "Draft" green button at the bottom.
/// - If scheduled, shows a green button with the scheduled time.
/// - If posted, shows normal posted time + action icons.
///
/// Also displays a special UI for posts without images, showing a green-outlined
/// icon with custom text centered between the content and bottom bar.
class PostCard extends StatelessWidget {
  final PostEntity post;

  /// Standard dimensions for consistent card layout
  static const double cardWidth = 320;
  static const double cardHeight = 350;

  /// Creates a [PostCard] for displaying a [post].
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: vPrimaryColor.withAlpha(40),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1) Title. If empty string, doesn't display.
            if (post.title.isNotEmpty) _buildCenteredTitle(),

            // 2) Post text, fixed height for up to 6 lines
            Align(
              alignment: Alignment.centerLeft,
              child: _buildFixedHeightText(context),
            ),
            const SizedBox(height: 4),

            // 3) Location (if any)
            if (post.locationAddress != null && post.locationAddress!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _buildLocationRow(),
              ),

            // Add spacer to push content to the center
            const Spacer(),

            // 4) Images row or "No images" indicator - centered vertically
            _buildImagesRow(context),

            // Add spacer to center the images section
            const Spacer(),

            // 5) Show bottom status based on post type:
            if (post.scheduledAt != null)
              _buildScheduledButton()
            else if (post.updatedAt != null)
              _buildIconsRowPosted()
            else
              _buildDraftIndicator(),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  // 1) Centered bold title
  //--------------------------------------------------------------------------
  /// Builds a centered title with the post's title text.
  Widget _buildCenteredTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        post.title,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: boldTextStyle(
          size: 14,
          color: vPrimaryColor.withAlpha(220),
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  // 2) Post text with a fixed height for 6 lines
  //--------------------------------------------------------------------------
  /// Builds a fixed-height container for post content, showing up to 6 lines.
  Widget _buildFixedHeightText(BuildContext context) {
    const double lineHeightPx = 18.0;
    const double totalHeightPx = lineHeightPx * 6;

    return Container(
      width: double.infinity,
      height: totalHeightPx,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: vPrimaryColor.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        post.content,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        style: secondaryTextStyle(
          size: 13,
          color: vPrimaryColor.withAlpha(220),
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  // 3) Location
  //--------------------------------------------------------------------------
  /// Builds a row showing the location icon and address.
  Widget _buildLocationRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            post.locationAddress!,
            style: secondaryTextStyle(
              color: Colors.redAccent,
              size: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  //--------------------------------------------------------------------------
  // 4) Images row
  //--------------------------------------------------------------------------
  /// Builds either:
  /// - A row of images if the post has images
  /// - A "No images" indicator with green outline if no images are present
  Widget _buildImagesRow(BuildContext context) {
    final images = post.localImagePaths;

    // If there are no images, show a placeholder with appropriate text
    if (images.isEmpty) {
      final isDraft = post.scheduledAt == null && post.updatedAt == null;
      final message = isDraft
          ? "No images added to this draft"
          : "No images selected for this post";

      return Container(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: vAccentColor,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: vAccentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: secondaryTextStyle(
                  color: vAccentColor,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // If the post has images, display them in a scrollable row
    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.map((path) {
            return GestureDetector(
              onTap: () =>
                  _openFullScreen(context, images, images.indexOf(path)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: vPrimaryColor.withAlpha(77),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Opens a full-screen view of the selected images, starting at [index].
  /// This view is read-only (cannot delete images).
  void _openFullScreen(BuildContext context, List<String> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImagePreview(
          initialIndex: index,
          useDirectList: true,
          directImages: images,
          allowDeletion: false,
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  // 5) Bottom status indicators
  //--------------------------------------------------------------------------
  /// Builds a row for posted posts showing post time and action icons.
  Widget _buildIconsRowPosted() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Posted at ${post.updatedAt!.toIso8601String().substring(0, 10)}",
          style: secondaryTextStyle(color: vAccentColor, size: 12),
        ),
        const SizedBox(height: 4),
        _buildActionIcons(),
      ],
    );
  }

  /// Builds a green button showing the scheduled date/time.
  Widget _buildScheduledButton() {
    final scheduledTime = post.scheduledAt!;
    // Format: "2023-02-28 14:25"
    final formattedTime = "${scheduledTime.toString().substring(0, 16)}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: vAccentColor.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formattedTime,
        textAlign: TextAlign.center,
        style: boldTextStyle(
          color: Colors.white,
          size: 13,
        ),
      ),
    );
  }

  /// Builds a "Draft" indicator bar for draft posts.
  Widget _buildDraftIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: vAccentColor.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Draft",
        textAlign: TextAlign.center,
        style: boldTextStyle(
          color: Colors.white,
          size: 13,
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  // Action icons row (only for posted content)
  //--------------------------------------------------------------------------
  /// Builds a row of action icons (comment, retweet, like, stats) with counts.
  Widget _buildActionIcons() {
    final iconColor = vPrimaryColor.withAlpha(120);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _iconWithCount(Icons.chat_bubble_outline, "0", iconColor),
        _iconWithCount(Icons.repeat, "0", iconColor),
        _iconWithCount(Icons.favorite_border, "0", iconColor),
        _iconWithCount(Icons.bar_chart_outlined, "0", iconColor),
      ],
    );
  }

  /// Builds a single icon with an associated count text.
  Widget _iconWithCount(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 2),
        Text(count, style: secondaryTextStyle(color: color, size: 12)),
      ],
    );
  }
}
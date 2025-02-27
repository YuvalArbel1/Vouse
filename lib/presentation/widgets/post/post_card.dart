// lib/presentation/widgets/post/post_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/screens/post/full_screen_image_preview.dart';

/// A post card that:
/// - If it's a draft (no scheduledAt, no updatedAt), shows a "Draft" bar at the bottom.
/// - If scheduled, shows a “Scheduled” row plus normal icons.
/// - If posted, shows normal icons row.
///
/// Removes unnecessary null checks on [post.title], presuming your PostEntity
/// always provides a non-null (possibly empty) title string.
class PostCard extends StatelessWidget {
  final PostEntity post;

  static const double cardWidth = 320;
  static const double cardHeight = 350;

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
            // 1) Title. If you want to skip an empty string, check isNotEmpty.
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
            const SizedBox(height: 4),

            // 4) Images row
            if (post.localImagePaths.isNotEmpty) _buildImagesRow(context),

            const Spacer(),

            // 5) Show bottom row depending on draft/scheduled/posted
            if (post.scheduledAt != null)
              _buildScheduledRow()
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
  Widget _buildImagesRow(BuildContext context) {
    final images = post.localImagePaths.take(4).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
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
  // 5) Handling draft/scheduled/posted
  //--------------------------------------------------------------------------
  Widget _buildScheduledRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeInfo(),
        const SizedBox(height: 4),
        _buildActionIcons(),
      ],
    );
  }

  Widget _buildIconsRowPosted() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeInfo(),
        const SizedBox(height: 4),
        _buildActionIcons(),
      ],
    );
  }

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
  // Time info
  //--------------------------------------------------------------------------
  Widget _buildTimeInfo() {
    if (post.scheduledAt != null) {
      final dateStr = post.scheduledAt.toString().substring(0, 16);
      return Text(
        "Scheduled: $dateStr",
        style: secondaryTextStyle(color: vAccentColor, size: 12),
      );
    } else if (post.updatedAt != null) {
      final dateStr = post.updatedAt!.toIso8601String().substring(0, 10);
      return Text(
        "Posted at $dateStr",
        style: secondaryTextStyle(color: vAccentColor, size: 12),
      );
    } else {
      // draft => won't even call this
      return const SizedBox.shrink();
    }
  }

  //--------------------------------------------------------------------------
  // Normal icons row
  //--------------------------------------------------------------------------
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

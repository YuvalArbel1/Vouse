// lib/presentation/widgets/post/post_preview/draft_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';

import '../../../providers/navigation/navigation_service.dart';
import '../../../../domain/usecases/post/delete_post_usecase.dart';
import '../../../providers/local_db/local_post_providers.dart';
import '../../../providers/post/post_refresh_provider.dart';
import '../../../providers/home/home_content_provider.dart';
import '../../../../core/resources/data_state.dart';

/// A specialized card widget for displaying draft posts with a consistent,
/// polished appearance.
class DraftCard extends ConsumerWidget {
  /// The post entity containing draft data
  final PostEntity post;

  /// Creates a [DraftCard] for displaying a draft [post].
  const DraftCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate time since creation
    final now = DateTime.now();
    final difference = now.difference(post.createdAt);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo =
          '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      timeAgo =
          '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo =
          '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      timeAgo = 'Just now';
    }

    // Check if post has images
    final hasImages = post.localImagePaths.isNotEmpty;
    final hasLocation =
        post.locationAddress != null && post.locationAddress!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        ref.read(navigationServiceProvider).navigateToEditDraft(context, post);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with title, time and draft badge
            Stack(
              children: [
                // Title area
                Padding(
                  padding: const EdgeInsets.fromLTRB(50, 16, 16, 8),
                  child: post.title.isNotEmpty
                      ? Row(
                          children: [
                            const Text(
                              "✍️ ", // Draft emoji
                              style: TextStyle(fontSize: 18),
                            ),
                            Expanded(
                              child: Text(
                                post.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: vPrimaryColor.withAlpha(220),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(
                          height: 24), // Maintain spacing if no title
                ),

                // Draft badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 14,
                          color: vPrimaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'DRAFT',
                          style: TextStyle(
                            color: vPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Delete button
                Positioned(
                  top: 12,
                  left: 12,
                  child: InkWell(
                    onTap: () => _showDeleteConfirmDialog(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Post content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 80),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: vBodyGrey,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Location
            if (hasLocation)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          post.locationAddress!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Time indicator - moved to appear near content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(70),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Images section with proper spacing
            if (hasImages)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image label and count
                    Row(
                      children: [
                        const Text(
                          "📷 Images",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${post.localImagePaths.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withAlpha(180),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Image grid with better layout and spacing
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: post.localImagePaths.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: vPrimaryColor.withAlpha(50),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Builder(
                                builder: (context) {
                                  try {
                                    final file =
                                        File(post.localImagePaths[index]);
                                    if (file.existsSync()) {
                                      return Image.file(
                                        file,
                                        fit: BoxFit.cover,
                                      );
                                    } else {
                                      // Return a placeholder if file doesn't exist
                                      return Container(
                                        color: Colors.grey.withAlpha(30),
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 30,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // Return error placeholder
                                    return Container(
                                      color: Colors.grey.withAlpha(30),
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 30,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 8),

            // Draft button at bottom - full width and clear
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: vAccentColor.withAlpha(180),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Draft",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog for deleting a draft post
  Future<void> _showDeleteConfirmDialog(
      BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(navigationServiceProvider).showConfirmationDialog(
              context,
              'Delete Draft',
              'Are you sure you want to delete this draft? This action cannot be undone.',
              cancelText: 'Cancel',
              confirmText: 'Delete',
            );

    if (result) {
      if (context.mounted) {
        // User confirmed deletion
        _deleteDraft(context, ref);
      }
    }
  }

  /// Deletes the draft post from local database
  Future<void> _deleteDraft(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(vPrimaryColor),
        ),
      ),
    );

    try {
      // Delete from local database
      final deleteUseCase = ref.read(deletePostUseCaseProvider);
      final result = await deleteUseCase.call(
        params: DeletePostParams(post.postIdLocal),
      );

      // Hide loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result is DataSuccess) {
        // Refresh providers
        ref.read(postRefreshProvider.notifier).refreshDrafts();
        ref.read(postRefreshProvider.notifier).refreshAll();

        // Explicitly refresh home content
        await ref.read(homeContentProvider.notifier).refreshHomeContent();

        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Draft deleted successfully'),
              backgroundColor: vAccentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (result is DataFailed && context.mounted) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error?.error}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog if there was an exception
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

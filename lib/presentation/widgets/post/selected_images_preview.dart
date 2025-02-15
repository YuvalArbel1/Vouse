import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../providers/post/post_images_provider.dart';

/// Displays up to 4 images from postImagesProvider, each 80×80 with:
///  - a subtle vPrimaryColor border of width 1,
///  - the image centered & cropped via BoxFit.cover,
///  - an 'X' button to remove it.
///
/// Any "white side" bars are eliminated because we're using 'cover', which
/// crops the image equally. The container is symmetrical (80×80).
class SelectedImagesPreview extends ConsumerWidget {
  const SelectedImagesPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(postImagesProvider);

    // If no images, return nothing
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: vAppLayoutBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: images.map((path) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: vPrimaryColor.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              child: Stack(
                children: [

                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      width: 80,
                      height: 80,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(postImagesProvider.notifier).removeImage(path);
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

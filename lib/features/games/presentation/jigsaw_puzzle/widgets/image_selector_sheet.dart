// ==============================================================================
// NIRVANA - ImageSelectorSheet Widget
// Description: Accessible picker for familiar, caregiver-approved puzzle scenes
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../models/puzzle_item.dart';

class ImageSelectorSheet extends StatelessWidget {
  final PuzzleImage activeImage;
  final String langCode;
  final ValueChanged<PuzzleImage> onImageSelected;

  const ImageSelectorSheet({
    super.key,
    required this.activeImage,
    required this.langCode,
    required this.onImageSelected,
  });

  static Future<PuzzleImage?> show(
    BuildContext context, {
    required PuzzleImage activeImage,
    required String langCode,
  }) {
    return showModalBottomSheet<PuzzleImage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ImageSelectorSheet(
        activeImage: activeImage,
        langCode: langCode,
        onImageSelected: (img) => Navigator.of(ctx).pop(img),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 48.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 18.0),

            // Header
            Row(
              children: [
                const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF0F766E),
                  size: 28.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    langCode == 'hi'
                        ? 'पसंदीदा तस्वीर चुनें'
                        : langCode == 'bn'
                            ? 'পছন্দের ছবি বেছে নিন'
                            : langCode == 'as'
                                ? 'পছন্দৰ ছবি বাছক'
                                : langCode == 'ne'
                                    ? 'मनपर्ने तस्वीर छान्नुहोस्'
                                    : 'Choose a Familiar Picture',
                    style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 28.0),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Pictures List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: PuzzleImage.defaultFamiliarImages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final image = PuzzleImage.defaultFamiliarImages[index];
                final isCurrent = image.id == activeImage.id;

                return InkWell(
                  onTap: () => onImageSelected(image),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE2E8F0),
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: SizedBox(
                            width: 72.0,
                            height: 72.0,
                            child: Image.asset(
                              image.assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE2E8F0),
                                child: const Icon(Icons.broken_image_rounded),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),

                        // Title & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                image.localizedTitle(langCode),
                                style: TextStyle(
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrent
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                image.localizedDescription(langCode),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isCurrent)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF16A34A),
                              size: 28.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }
}

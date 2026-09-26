import 'dart:typed_data';

import 'package:flutter/material.dart';

// ============================================================
// UPLOAD DISH PHOTO
// ============================================================
//
// Real image picker target. Shows:
// - a live preview once a photo is picked (Image.memory)
// - the existing photo in edit mode (Image.network)
// - the placeholder when neither exists
// ============================================================

class UploadDishImage extends StatelessWidget {
  final Uint8List? imageBytes;

  final String? imageUrl;

  final VoidCallback onPick;

  const UploadDishImage({
    super.key,
    this.imageBytes,
    this.imageUrl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        (imageBytes != null && imageBytes!.isNotEmpty) ||
            (imageUrl != null && imageUrl!.isNotEmpty);

    return InkWell(
      onTap: onPick,

      borderRadius: BorderRadius.circular(24),

      child: Container(
        height: 220,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.orange.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: .08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // ==================================================
                  // PHOTO PREVIEW
                  // ==================================================

                  imageBytes != null && imageBytes!.isNotEmpty
                      ? Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return _placeholder();
                          },
                        ),

                  // ==================================================
                  // CHANGE BADGE
                  // ==================================================

                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: .65,
                        ),
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Change Photo",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Container(
          width: 80,
          height: 80,

          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.camera_alt_rounded,
            size: 42,
            color: Color(0xffFF5A1F),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          "Upload Dish Photo",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: "Poppins",
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "JPG • PNG • WEBP",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontFamily: "Poppins",
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),

          decoration: BoxDecoration(
            color: const Color(0xffFF5A1F),
            borderRadius: BorderRadius.circular(30),
          ),

          child: const Text(
            "Choose Image",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class UploadDishImage extends StatelessWidget {
  const UploadDishImage({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO : Pick Image
      },

      borderRadius: BorderRadius.circular(24),

      child: Container(
        height: 220,
        width: double.infinity,

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

        child: Column(
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
            )

          ],
        ),
      ),
    );
  }
}
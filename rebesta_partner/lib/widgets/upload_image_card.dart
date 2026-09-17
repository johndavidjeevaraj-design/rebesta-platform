import 'package:flutter/material.dart';

class UploadImageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const UploadImageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.only(bottom: 24),

        padding: const EdgeInsets.symmetric(
          vertical: 30,
          horizontal: 20,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(22),

          border: Border.all(
            color: const Color(0xffFF5A1F).withValues(alpha: .20),
            width: 2,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),

        child: Column(
          children: [

            const CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xffFFF3ED),

              child: Icon(
                Icons.add_a_photo_outlined,
                size: 34,
                color: Color(0xffFF5A1F),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),

              decoration: BoxDecoration(
                color: const Color(0xffFF5A1F),
                borderRadius: BorderRadius.circular(14),
              ),

              child: const Text(
                "Choose Image",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
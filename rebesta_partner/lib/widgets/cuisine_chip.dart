import 'package:flutter/material.dart';

class CuisineChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const CuisineChip({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xffFF5A1F)
              : Colors.white,

          borderRadius: BorderRadius.circular(30),

          border: Border.all(
            color: selected
                ? const Color(0xffFF5A1F)
                : Colors.grey.shade300,
          ),
        ),

        child: Text(
          title,
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}
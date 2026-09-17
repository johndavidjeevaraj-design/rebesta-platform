import 'package:flutter/material.dart';

class SelectionChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const SelectionChip({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 14,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xffFF5A1F)
              : Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: selected
                ? const Color(0xffFF5A1F)
                : Colors.grey.shade300,
          ),

          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xffFF5A1F)
                        .withValues(alpha: .20),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
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
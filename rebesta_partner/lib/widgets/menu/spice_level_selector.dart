import 'package:flutter/material.dart';

class SpiceLevelSelector extends StatelessWidget {
  final String selectedLevel;
  final Function(String) onChanged;

  const SpiceLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Row(
            children: [

              Icon(
                Icons.local_fire_department,
                color: Color(0xffFF5A1F),
              ),

              SizedBox(width: 10),

              Text(
                "Spice Level",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),

            ],
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 12,
            runSpacing: 12,

            children: [

              _chip("🌱 Mild"),
              _chip("🌶 Medium"),
              _chip("🔥 Hot"),

            ],
          )

        ],
      ),
    );
  }

  Widget _chip(String value) {
    final bool selected = selectedLevel == value;

    return InkWell(
      onTap: () => onChanged(value),

      borderRadius: BorderRadius.circular(30),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xffFF5A1F)
              : Colors.grey.shade100,

          borderRadius: BorderRadius.circular(30),

          border: Border.all(
            color: selected
                ? const Color(0xffFF5A1F)
                : Colors.grey.shade300,
          ),
        ),

        child: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }
}
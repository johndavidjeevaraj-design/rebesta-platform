import 'package:flutter/material.dart';

class FoodTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onChanged;

  const FoodTypeSelector({
    super.key,
    required this.selectedType,
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
                Icons.eco,
                color: Color(0xffFF5A1F),
              ),

              SizedBox(width: 10),

              Text(
                "Food Type",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),

            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [

              Expanded(
                child: _FoodCard(
                  emoji: "🥗",
                  title: "Veg",
                  selected: selectedType == "Veg",
                  onTap: () => onChanged("Veg"),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: _FoodCard(
                  emoji: "🍗",
                  title: "Non Veg",
                  selected: selectedType == "Non Veg",
                  onTap: () => onChanged("Non Veg"),
                ),
              ),

            ],
          ),

        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final String emoji;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _FoodCard({
    required this.emoji,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xffFF5A1F)
              : Colors.grey.shade100,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: selected
                ? const Color(0xffFF5A1F)
                : Colors.grey.shade300,
          ),
        ),

        child: Column(
          children: [

            Text(
              emoji,
              style: const TextStyle(
                fontSize: 34,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : Colors.black,
              ),
            ),

          ],
        ),
      ),
    );
  }
}
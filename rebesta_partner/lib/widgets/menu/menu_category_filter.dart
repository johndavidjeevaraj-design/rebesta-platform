import 'package:flutter/material.dart';


class MenuCategoryFilter extends StatelessWidget {
  const MenuCategoryFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      "All",
      "Breakfast",
      "Lunch",
      "Dinner",
      "Snacks",
      "Beverages",
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: index == 0
                  ? const Color(0xffFF5A1F)
                  : Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                color: index == 0
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuCategoryTabsWidget extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const MenuCategoryTabsWidget({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const Color orange = Color(0xFFF05C03);
  static const Color ink = Color(0xFF2A1D1A);
  static const Color muted = Color(0xFF918985);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final selected =
              selectedIndex == index;

          return GestureDetector(
            onTap: () => onSelected(index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(
                right: 28,
              ),
              padding: const EdgeInsets.only(
                top: 3,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Text(
                    categories[index],
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selected
                          ? orange
                          : muted,
                    ),
                  ),

                  const SizedBox(height: 10),

                  AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 200,
                    ),
                    height: 2,
                    width: selected ? 20 : 0,
                    decoration: BoxDecoration(
                      color: orange,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
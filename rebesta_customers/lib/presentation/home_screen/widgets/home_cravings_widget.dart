import 'package:flutter/material.dart';

class HomeCravingsWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const HomeCravingsWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const List<HomeCategory> categories = [
    HomeCategory(
      name: 'Biriyani',
      image: 'assets/home_categories/1.png',
    ),
    HomeCategory(
      name: 'Pizzas',
      image: 'assets/home_categories/19.png',
    ),
    HomeCategory(
      name: 'Idli',
      image: 'assets/home_categories/20.png',
    ),
    HomeCategory(
      name: 'Dosa',
      image: 'assets/home_categories/21.png',
    ),
    HomeCategory(
      name: 'Shawarma',
      image: 'assets/home_categories/22.png',
    ),
    HomeCategory(
      name: 'Cakes',
      image: 'assets/home_categories/14.png',
    ),
    HomeCategory(
      name: 'Burgers',
      image: 'assets/home_categories/4.png',
    ),
    HomeCategory(
      name: 'Rolls',
      image: 'assets/home_categories/5.png',
    ),
    HomeCategory(
      name: 'Noodles',
      image: 'assets/home_categories/18.png',
    ),
    HomeCategory(
      name: 'Ice cream',
      image: 'assets/home_categories/6.png',
    ),
    HomeCategory(
      name: 'Sandwich',
      image: 'assets/home_categories/3.png',
    ),
    HomeCategory(
      name: 'Momos',
      image: 'assets/home_categories/7.png',
    ),
    HomeCategory(
      name: 'Kebab',
      image: 'assets/home_categories/8.png',
    ),
    HomeCategory(
      name: 'Shake',
      image: 'assets/home_categories/9.png',
    ),
    HomeCategory(
      name: 'Pasta',
      image: 'assets/home_categories/10.png',
    ),
    HomeCategory(
      name: 'Juice',
      image: 'assets/home_categories/24.png',
    ),
    HomeCategory(
      name: 'Salad',
      image: 'assets/home_categories/11.png',
    ),
    HomeCategory(
      name: 'Pastry',
      image: 'assets/home_categories/12.png',
    ),
    HomeCategory(
      name: 'Thali',
      image: 'assets/home_categories/17.png',
    ),
    HomeCategory(
      name: 'Mousse',
      image: 'assets/home_categories/23.png',
    ),
    HomeCategory(
      name: 'Chicken',
      image: 'assets/home_categories/13.png',
    ),
    HomeCategory(
      name: 'Desserts',
      image: 'assets/home_categories/23.png',
    ),
    HomeCategory(
      name: 'Chinese',
      image: 'assets/home_categories/18.png',
    ),
    HomeCategory(
      name: 'Snacks',
      image: 'assets/home_categories/13.png',
    ),
    HomeCategory(
      name: 'Rice',
      image: 'assets/home_categories/15.png',
    ),
    HomeCategory(
      name: 'Paratha',
      image: 'assets/home_categories/2.png',
    ),
    HomeCategory(
      name: 'Mutton',
      image: 'assets/home_categories/16.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Text(
              "What's on your mind?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF202635),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              itemCount: categories.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 12),

              itemBuilder: (context, index) {
                final category = categories[index];
                final selected =
                    selectedIndex == index;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(index),

                  child: AnimatedScale(
                    scale: selected ? 1.05 : 1.0,
                    duration: const Duration(
                      milliseconds: 280,
                    ),
                    curve: Curves.easeOutCubic,

                    child: SizedBox(
                      width: 78,

                      child: Column(
                        children: [

                          // ==================================================
                          // FOOD IMAGE
                          // Transparent / no circle / no border
                          // Slightly larger + slightly pushed upward
                          // ==================================================

                          SizedBox(
                            width: 78,
                            height: 78,

                            child: Transform.translate(
                              offset: const Offset(
                                0,
                                -4,
                              ),

                              child: Image.asset(
                                category.image,

                                width: 100,
                                height: 100,

                                fit: BoxFit.contain,

                                errorBuilder:
                                    (_, _, _) {
                                  return const Icon(
                                    Icons.fastfood_rounded,
                                    color:
                                        Color(0xFFFF6538),
                                    size: 38,
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 2),

                          // ==================================================
                          // CATEGORY NAME
                          // ==================================================

                          AnimatedDefaultTextStyle(
                            duration: const Duration(
                              milliseconds: 280,
                            ),
                            curve: Curves.easeOutCubic,

                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? const Color(
                                      0xFFFF5735,
                                    )
                                  : const Color(
                                      0xFF4B5262,
                                    ),
                            ),

                            child: Text(
                              category.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeCategory {
  final String name;
  final String image;

  const HomeCategory({
    required this.name,
    required this.image,
  });
}
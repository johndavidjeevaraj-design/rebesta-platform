import 'package:flutter/material.dart';
import '../../../models/restaurant.dart';

class RestaurantHeaderWidget extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantHeaderWidget({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Image.network(
            restaurant.imageUrl ??
                "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: const Icon(
                Icons.restaurant,
                size: 80,
              ),
            ),
          ),
        ),

        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black26,
                Colors.transparent,
                Colors.black87,
              ],
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                _circleButton(
                  context,
                  Icons.arrow_back,
                  () => Navigator.pop(context),
                ),

                const Spacer(),

                _circleButton(
                  context,
                  restaurant.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  () {},
                ),

                const SizedBox(width: 12),

                _circleButton(
                  context,
                  Icons.share,
                  () {},
                ),
              ],
            ),
          ),
        ),

        Positioned(
          left: 20,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (restaurant.promoLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    restaurant.promoLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: restaurant.isOpen
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  restaurant.isOpen
                      ? "Open Now"
                      : "Closed",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton(
      BuildContext context,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Icon(
          icon,
          color: Colors.black87,
        ),
      ),
    );
  }
}
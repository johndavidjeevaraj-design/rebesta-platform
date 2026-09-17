import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/custom_image_widget.dart';

class OrderAgainWidget extends StatelessWidget {
  final VoidCallback onOrderTap;

  const OrderAgainWidget({required this.onOrderTap, super.key});

  static const List<Map<String, dynamic>> _pastOrders = [
    {
      'restaurant': 'The Burger Lab',
      'item': 'Double Smash Burger',
      'price': 14.99,
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1950d7a04-1772256932396.png',
      'semanticLabel': 'Double smash burger with crispy edges and cheese sauce',
    },
    {
      'restaurant': 'Sakura Sushi Bar',
      'item': 'Dragon Roll ×2',
      'price': 22.50,
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_19d2b5aa9-1784357582038.png',
      'semanticLabel':
          'Dragon roll sushi with avocado and spicy mayo on dark plate',
    },
    {
      'restaurant': 'Napoli Pizza Co.',
      'item': 'Margherita L',
      'price': 18.00,
      'imageUrl':
          'https://images.unsplash.com/photo-1726298882906-6d01c9116e13',
      'semanticLabel': 'Margherita pizza with fresh basil and mozzarella',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Text(
                'Order Again',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              GestureDetector(
                onTap: onOrderTap,
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pastOrders.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final order = _pastOrders[index];
              return GestureDetector(
                onTap: onOrderTap,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        child: CustomImageWidget(
                          imageUrl: order['imageUrl'] as String,
                          width: 80,
                          height: 110,
                          fit: BoxFit.cover,
                          semanticLabel: order['semanticLabel'] as String,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['restaurant'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppTheme.mutedText),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order['item'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${(order['price'] as double).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: CustomIconWidget(
                                      iconName: 'replay_rounded',
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

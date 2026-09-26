import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

// ============================================================
// ORDER AGAIN
// ============================================================
//
// Real recent delivered orders passed in by the home screen.
// Tapping a card re-adds every item to the cart and lands in
// checkout for that restaurant.
//
// (Used to be hardcoded template data with fake restaurants
// and placeholder images.)
// ============================================================

class OrderAgainWidget extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  final void Function(Map<String, dynamic> order) onReorder;

  const OrderAgainWidget({
    required this.orders,
    required this.onReorder,
    super.key,
  });

  // ==========================================================
  // DATA HELPERS
  // ==========================================================

  String _restaurantName(Map<String, dynamic> order) {
    final partner = order['restaurant_partners'];

    if (partner is Map) {
      return partner['restaurant_name']?.toString() ??
          'Restaurant';
    }

    return 'Restaurant';
  }

  String _itemText(Map<String, dynamic> order) {
    final items = order['order_items'];

    if (items is! List || items.isEmpty) {
      return 'Past order';
    }

    final first = items.first;

    if (first is Map) {
      final menuItem = first['menu_items'];

      final name = menuItem is Map
          ? menuItem['name']?.toString()
          : null;

      if (name != null && name.isNotEmpty) {
        return items.length > 1
            ? '$name +${items.length - 1} more'
            : name;
      }
    }

    return '${items.length} items';
  }

  String? _imageUrl(Map<String, dynamic> order) {
    final items = order['order_items'];

    if (items is! List || items.isEmpty) return null;

    final first = items.first;

    if (first is Map) {
      final menuItem = first['menu_items'];

      if (menuItem is Map) {
        final url = menuItem['image_url']?.toString();

        if (url != null && url.isNotEmpty) return url;
      }
    }

    return null;
  }

  String _total(Map<String, dynamic> order) {
    final amount = order['total_amount'];

    final value = amount is num ? amount.toDouble() : 0;

    return '\u20B9${value.toStringAsFixed(0)}';
  }

  Widget _image(String? imageUrl) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        width: 72,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagePlaceholder(),
      );
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      color: AppTheme.primary.withAlpha(25),
      child: Icon(
        Icons.restaurant_rounded,
        color: AppTheme.primary,
      ),
    );
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Order Again',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final order = orders[index];

              return GestureDetector(
                onTap: () => onReorder(order),
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
                        borderRadius:
                            const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        child: _image(_imageUrl(order)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                _restaurantName(order),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _itemText(order),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withAlpha(25),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _total(order),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
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

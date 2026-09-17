import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/restaurant.dart';

class RestaurantInfoStripWidget extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantInfoStripWidget({
    super.key,
    required this.restaurant,
  });

  static const Color orange = Color(0xFFF05C03);
  static const Color ink = Color(0xFF2A1D1A);
  static const Color muted = Color(0xFF70625F);

  @override
  Widget build(BuildContext context) {
    final rating = restaurant.rating.toStringAsFixed(1);

    final reviewCount = restaurant.reviewCount;

    final deliveryTime =
        restaurant.deliveryTime?.trim().isNotEmpty == true
            ? restaurant.deliveryTime!
            : '20–30 min';

    final deliveryFee =
        restaurant.deliveryFee == 0
            ? 'Free delivery'
            : '₹${restaurant.deliveryFee.toStringAsFixed(0)} delivery';

    final minOrder =
        'Min ₹${restaurant.minOrder.toStringAsFixed(0)}';

    final cuisine =
        restaurant.cuisine?.trim().isNotEmpty == true
            ? restaurant.cuisine!
            : 'Food · Restaurant';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        13,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // RESTAURANT NAME + RATING
          // =====================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      cuisine,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // =================================================
              // RATING
              // =================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF8EF),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),

                    const SizedBox(width: 3),

                    Text(
                      rating,
                      style:
                          GoogleFonts.sora(
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            const Color(
                          0xFF16A34A,
                        ),
                      ),
                    ),

                    if (reviewCount > 0) ...[
                      Text(
                        ' (${_formatReviews(reviewCount)})',
                        style:
                            GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w400,
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =====================================================
          // INFO ROW
          // =====================================================

          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: Row(
              children: [
                _InfoItem(
                  icon:
                      Icons.schedule_rounded,
                  label: deliveryTime,
                  color: orange,
                ),

                const SizedBox(width: 13),

                _InfoItem(
                  icon:
                      Icons.delivery_dining_rounded,
                  label: deliveryFee,
                ),

                const SizedBox(width: 13),

                _InfoItem(
                  icon:
                      Icons.shopping_bag_outlined,
                  label: minOrder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviews(int count) {
    if (count >= 1000) {
      final value = count / 1000;

      if (value >= 10) {
        return '${value.toStringAsFixed(0)}k';
      }

      return '${value.toStringAsFixed(1)}k';
    }

    return count.toString();
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF70625F);

    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: color ?? muted,
        ),

        const SizedBox(width: 4),

        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 10.5,
            fontWeight:
                FontWeight.w500,
            color: color ?? muted,
          ),
        ),
      ],
    );
  }
}
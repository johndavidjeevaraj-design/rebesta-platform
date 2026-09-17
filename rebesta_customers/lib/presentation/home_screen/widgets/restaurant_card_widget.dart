import 'package:flutter/material.dart';
import '../../../models/restaurant.dart';

class RestaurantCardWidget extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCardWidget({
    super.key,
    required this.restaurant,
    this.onTap,
  });

  @override
  State<RestaurantCardWidget> createState() =>
      _RestaurantCardWidgetState();
}

class _RestaurantCardWidgetState
    extends State<RestaurantCardWidget>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // HEART ANIMATION
  // ============================================================

  late AnimationController _heartController;
  late Animation<double> _heartScale;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();

    _isFavorite = widget.restaurant.isFavorite;

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );

    _heartScale = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 1.35,
          ).chain(
            CurveTween(
              curve: Curves.easeOut,
            ),
          ),
          weight: 45,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.35,
            end: 1.0,
          ).chain(
            CurveTween(
              curve: Curves.easeOutBack,
            ),
          ),
          weight: 55,
        ),
      ],
    ).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 12,
              offset: const Offset(
                0,
                5,
              ),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeroImage(),
              _buildRestaurantInfo(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO IMAGE
  // ============================================================

  Widget _buildHeroImage() {
    return AspectRatio(
      // Compact Swiggy-like card proportion
      aspectRatio: 1.80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ------------------------------------------------------
          // RESTAURANT IMAGE
          // ------------------------------------------------------

          widget.restaurant.imageUrl != null &&
                  widget.restaurant.imageUrl!
                      .trim()
                      .isNotEmpty
              ? Image.network(
                  widget.restaurant.imageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return _imagePlaceholder();
                  },
                )
              : _imagePlaceholder(),

          // ------------------------------------------------------
          // SUBTLE BOTTOM GRADIENT
          // ------------------------------------------------------

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [
                    0.0,
                    0.55,
                    1.0,
                  ],
                  colors: [
                    Colors.black.withValues(
                      alpha: 0.02,
                    ),
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: 0.42,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ------------------------------------------------------
          // CAROUSEL DOTS
          // ------------------------------------------------------

          Positioned(
            top: 11,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) {
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    width: index == 0 ? 6 : 5,
                    height: index == 0 ? 6 : 5,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(
                        alpha:
                            index == 0 ? 0.95 : 0.60,
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ),
          ),

          // ------------------------------------------------------
          // FAVORITE
          // NO CIRCLE / NO BACKGROUND
          // HEART RETURNS TO ORIGINAL POSITION
          // ------------------------------------------------------

          Positioned(
            top: 13,
            right: 49,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });

                _heartController.forward(
                  from: 0,
                );
              },
              child: ScaleTransition(
                scale: _heartScale,
                child: Icon(
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorite
                      ? Colors.red
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // ------------------------------------------------------
          // MORE
          // NO CIRCLE / NO BACKGROUND
          // ------------------------------------------------------

          Positioned(
            top: 13,
            right: 13,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // More options
              },
              child: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // ------------------------------------------------------
          // OFFER
          // ------------------------------------------------------

          if (_hasOffer)
            Positioned(
              left: 13,
              bottom: 13,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.restaurant.promoLabel!,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

          // ------------------------------------------------------
          // DELIVERY BADGE
          // ------------------------------------------------------

          Positioned(
            right: 0,
            bottom: 0,
            child: _buildDeliveryBadge(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESTAURANT INFO
  // ============================================================

  Widget _buildRestaurantInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // RESTAURANT NAME
          // ------------------------------------------------------

          Text(
            widget.restaurant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF171A21),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 3),

          // ------------------------------------------------------
          // RATING / REVIEWS / LOCATION / DISTANCE
          // ------------------------------------------------------

          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF16864A),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

              const SizedBox(width: 5),

              Text(
                widget.restaurant.rating
                    .toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF777C84),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 4),

              Text(
                '(${_formatReviews(
                  widget.restaurant.reviewCount,
                )})',
                style: const TextStyle(
                  color: Color(0xFF92969E),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 6),

              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFFB0B3B8),
                  fontSize: 12,
                ),
              ),

              const SizedBox(width: 6),

              const Flexible(
                child: Text(
                  'Hosur City',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF858A92),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 5),

              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFFB0B3B8),
                  fontSize: 12,
                ),
              ),

              const SizedBox(width: 5),

              const Text(
                '2.2 km',
                style: TextStyle(
                  color: Color(0xFF858A92),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // ------------------------------------------------------
          // CUISINE / PRICE
          // ------------------------------------------------------

          Row(
            children: [
              Flexible(
                child: Text(
                  widget.restaurant.cuisine ??
                      widget.restaurant.category ??
                      '',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B9098),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFFB0B3B8),
                  fontSize: 12,
                ),
              ),

              const SizedBox(width: 6),

              Text(
                '₹${widget.restaurant.minOrder.toInt()} for two',
                style: const TextStyle(
                  color: Color(0xFF8B9098),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELIVERY BADGE
  // ============================================================

  Widget _buildDeliveryBadge() {
    final deliveryTime =
        widget.restaurant.deliveryTime ??
            '25-30 mins';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        13,
        7,
        13,
        7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(
              -1,
              -2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Text(
            deliveryTime.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF363A40),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.1,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            widget.restaurant.deliveryFee == 0
                ? 'FREE DELIVERY'
                : 'DELIVERY FEE',
            style: const TextStyle(
              color: Color(0xFFFF572F),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _roundActionButton({
    required IconData icon,
    required Color iconColor,
    required double iconSize,
    required Color backgroundColor,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE8E8E8),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 40,
          color: Color(0xFFAAAAAA),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get _hasOffer {
    return widget.restaurant.promoLabel != null &&
        widget.restaurant.promoLabel!
            .trim()
            .isNotEmpty;
  }

  String _formatReviews(int count) {
    if (count >= 1000) {
      final value = count / 1000;

      if (value >= 10) {
        return '${value.toStringAsFixed(0)}K+';
      }

      return '${value.toStringAsFixed(1)}K+';
    }

    return '$count';
  }
}
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class MenuItemCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  

  // NEW
  final VoidCallback? onTap;

  const MenuItemCardWidget({
    super.key,
    required this.data,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        data['name']?.toString() ?? 'Menu Item';

    final String description =
        data['description']?.toString() ?? '';

    final double price =
        (data['price'] as num?)?.toDouble() ?? 0;

    final String imageUrl =
        data['imageUrl']?.toString() ??
        data['image_url']?.toString() ??
        '';

    final String badge =
        data['badge']?.toString() ??
        data['badges']?.toString() ??
        '';

    final int calories =
        (data['calories'] as num?)?.toInt() ?? 0;

    final bool isVeg =
        data['isVeg'] == true ||
        data['is_veg'] == true;

    return GestureDetector(
      // =========================================================
      // CARD TAP
      // =========================================================
      onTap: onTap,
      behavior: HitTestBehavior.opaque,

      child: Container(
        margin: const EdgeInsets.only(
          left: 4,
          right: 4,
          bottom: 4,
        ),

        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: AppTheme.outlineLight,
            width: 1,
          ),

          boxShadow:
              AppTheme.cardShadow,
        ),

        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(14),

          child: Stack(
            children: [
              // =================================================
              // VEG / NON-VEG SIDE INDICATOR
              // =================================================

              Positioned(
                left: 0,
                top: 0,
                bottom: 0,

                child: Container(
                  width: 3,
                  color: isVeg
                      ? AppTheme.success
                      : AppTheme.primary,
                ),
              ),

              // =================================================
              // CARD CONTENT
              // =================================================

              SizedBox(
                height: 125,

                child: Row(
                  children: [
                    // =============================================
                    // ITEM INFORMATION
                    // =============================================

                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          12,
                          8,
                          6,
                          7,
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            // ===================================
                            // BADGE
                            // ===================================

                            if (badge.isNotEmpty)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      AppTheme.primaryContainer,

                                  borderRadius:
                                      BorderRadius.circular(
                                    5,
                                  ),
                                ),

                                child: Text(
                                  badge,

                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppTheme.primary,
                                  ),
                                ),
                              ),

                            if (badge.isNotEmpty)
                              const SizedBox(
                                height: 3,
                              ),

                            // ===================================
                            // NAME
                            // ===================================

                            Text(
                              name,

                              maxLines: 1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppTheme.headlineText,
                                    height: 1.05,
                                  ),
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            // ===================================
                            // DESCRIPTION
                            // ===================================

                            Expanded(
                              child: Text(
                                description,

                                maxLines: 2,

                                overflow:
                                    TextOverflow.ellipsis,

                                style:
                                    Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      fontSize: 9.5,
                                      height: 1.15,
                                      color:
                                          AppTheme.mutedText,
                                    ),
                              ),
                            ),

                            // ===================================
                            // PRICE + CALORIES
                            // ===================================

                            Row(
                              children: [
                                Text(
                                  '₹${price.toStringAsFixed(2)}',

                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppTheme.headlineText,
                                  ),
                                ),

                                if (calories > 0) ...[
                                  const SizedBox(
                                    width: 6,
                                  ),

                                  const Icon(
                                    Icons
                                        .local_fire_department_rounded,
                                    size: 10,
                                    color:
                                        AppTheme.warning,
                                  ),

                                  const SizedBox(
                                    width: 2,
                                  ),

                                  Text(
                                    '$calories cal',

                                    style:
                                        TextStyle(
                                      fontSize: 9,
                                      color:
                                          AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // =================================================
                    // IMAGE + ADD BUTTON
                    // =================================================

                    Padding(
                      padding:
                          const EdgeInsets.all(6),

                      child: SizedBox(
                        width: 104,
                        height: 104,

                        child: Stack(
                          clipBehavior:
                              Clip.none,

                          children: [
                            // =====================================
                            // SQUARE IMAGE
                            // =====================================

                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),

                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,

                                      width: 104,
                                      height: 104,

                                      fit: BoxFit.cover,

                                      errorBuilder:
                                          (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        debugPrint(
                                          '❌ MENU IMAGE ERROR: $imageUrl',
                                        );

                                        debugPrint(
                                          '❌ ERROR: $error',
                                        );

                                        return _placeholder();
                                      },
                                    )
                                  : _placeholder(),
                            ),

                            // =====================================
                            // ADD / QUANTITY BUTTON
                            // =====================================

                            Positioned(
                              right: -3,
                              bottom: -3,

                              child:
                                  quantity == 0
                                      ? _AddButton(
                                          onTap: onAdd,
                                        )
                                      : _QuantityButton(
                                          quantity:
                                              quantity,
                                          onAdd:
                                              onAdd,
                                          onRemove:
                                              onRemove,
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // IMAGE PLACEHOLDER
  // ===============================================================

  Widget _placeholder() {
    return Container(
      width: 104,
      height: 104,

      color:
          AppTheme.surfaceVariantLight,

      child: const Icon(
        Icons.restaurant_rounded,
        color: AppTheme.mutedText,
        size: 30,
      ),
    );
  }
}

// =================================================================
// ADD BUTTON
// =================================================================

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      behavior:
          HitTestBehavior.opaque,

      child: Container(
        width: 34,
        height: 34,

        decoration: BoxDecoration(
          color: AppTheme.primary,

          shape: BoxShape.circle,

          border: Border.all(
            color: Colors.white,
            width: 2,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withAlpha(35),

              blurRadius: 7,

              offset:
                  const Offset(0, 2),
            ),
          ],
        ),

        child: const Icon(
          Icons.add_rounded,

          color: Colors.white,

          size: 18,
        ),
      ),
    );
  }
}

// =================================================================
// QUANTITY BUTTON
// =================================================================

class _QuantityButton
    extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityButton({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 2,
      ),

      decoration: BoxDecoration(
        color:
            AppTheme.surfaceLight,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow:
            AppTheme.cardShadow,

        border: Border.all(
          color:
              AppTheme.outlineLight,

          width: 1,
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          // =======================================================
          // MINUS
          // =======================================================

          GestureDetector(
            onTap: onRemove,

            behavior:
                HitTestBehavior.opaque,

            child: const Padding(
              padding:
                  EdgeInsets.all(4),

              child: Icon(
                Icons.remove_rounded,

                size: 15,

                color:
                    AppTheme.headlineText,
              ),
            ),
          ),

          // =======================================================
          // QUANTITY
          // =======================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 4,
            ),

            child: Text(
              '$quantity',

              style:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                color:
                    AppTheme.headlineText,
              ),
            ),
          ),

          // =======================================================
          // PLUS
          // =======================================================

          GestureDetector(
            onTap: onAdd,

            behavior:
                HitTestBehavior.opaque,

            child: const Padding(
              padding:
                  EdgeInsets.all(4),

              child: Icon(
                Icons.add_rounded,

                size: 15,

                color:
                    AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
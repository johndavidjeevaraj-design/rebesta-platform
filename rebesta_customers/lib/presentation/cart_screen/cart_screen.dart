import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';

class CartScreen extends StatefulWidget {
  // ============================================================
  // RESTAURANT PARTNER ID
  // ============================================================

  final String restaurantPartnerId;

  const CartScreen({
    super.key,
    required this.restaurantPartnerId,
  });

  @override
  State<CartScreen> createState() =>
      _CartScreenState();
}

class _CartScreenState
    extends State<CartScreen> {
  final CartService _cartService =
      CartService();

  List<CartItem> _items = [];

  double _total = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadCart();
  }

  // ============================================================
  // LOAD CART
  // ============================================================

  Future<void> _loadCart() async {
    try {
      debugPrint(
        'CART SCREEN: Loading cart...',
      );

      debugPrint(
        'Restaurant Partner ID: ${widget.restaurantPartnerId}',
      );

      final response =
          await _cartService.getCart(
        restaurantPartnerId:
            widget.restaurantPartnerId,
      );

      final cart =
          response['cart'];

      if (cart == null) {
        throw Exception(
          'Cart not found',
        );
      }

      final rawItems =
          cart['items'] as List? ?? [];

      final items =
          rawItems
              .map(
                (item) =>
                    CartItem.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              )
              .toList();

      if (!mounted) return;

      setState(() {
        _items = items;

        _total =
            (cart['total'] as num?)
                    ?.toDouble() ??
                0;

        _loading = false;
      });

      debugPrint(
        'CART SCREEN: ${items.length} items loaded',
      );
    } catch (e) {
      debugPrint(
        'CART LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _items = [];
        _total = 0;
        _loading = false;
      });
    }
  }

  // ============================================================
  // UPDATE QUANTITY
  // ============================================================

  Future<void> _updateQuantity(
    CartItem item,
    int quantity,
  ) async {
    try {
      if (quantity <= 0) {
        await _cartService.removeItem(
          cartItemId: item.id,
        );
      } else {
        await _cartService.updateItem(
          cartItemId: item.id,
          quantity: quantity,
        );
      }

      await _loadCart();
    } catch (e) {
      debugPrint(
        'CART UPDATE ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundLight,

      appBar: AppBar(
        backgroundColor:
            AppTheme.backgroundLight,

        elevation: 0,

        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: Text(
          'Your Cart',
          style:
              GoogleFonts.bricolageGrotesque(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color:
                AppTheme.headlineText,
          ),
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _items.isEmpty
              ? _buildEmptyCart()
              : _buildCart(),
    );
  }

  // ============================================================
  // CART
  // ============================================================

  Widget _buildCart() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24,
            ),
            children: [
              Text(
                '${_items.length} items',
                style:
                    GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppTheme.mutedText,
                ),
              ),

              const SizedBox(height: 12),

              ..._items.map(
                _buildCartItem,
              ),
            ],
          ),
        ),

        _buildBottomSummary(),
      ],
    );
  }

  // ============================================================
  // CART ITEM
  // ============================================================

  Widget _buildCartItem(
    CartItem item,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(12),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow:
            AppTheme.cardShadow,
      ),

      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(14),

            child: CustomImageWidget(
              imageUrl:
                  item.imageUrl ?? '',
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              semanticLabel:
                  item.name,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppTheme.headlineText,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style:
                      GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppTheme.mutedText,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _quantityButton(
                      icon:
                          Icons.remove,
                      onTap: () {
                        _updateQuantity(
                          item,
                          item.quantity - 1,
                        );
                      },
                    ),

                    SizedBox(
                      width: 38,
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style:
                              GoogleFonts.sora(
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    _quantityButton(
                      icon:
                          Icons.add,
                      onTap: () {
                        _updateQuantity(
                          item,
                          item.quantity + 1,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '₹${item.subtotal.toStringAsFixed(0)}',
            style:
                GoogleFonts.sora(
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppTheme.headlineText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUANTITY BUTTON
  // ============================================================

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(10),

      child: Container(
        width: 30,
        height: 30,

        decoration:
            BoxDecoration(
          color:
              AppTheme.primary
                  .withValues(
            alpha: 0.10,
          ),

          borderRadius:
              BorderRadius.circular(10),
        ),

        child: Icon(
          icon,
          size: 17,
          color:
              AppTheme.primary,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SUMMARY
  // ============================================================

  Widget _buildBottomSummary() {
    return SafeArea(
      top: false,

      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16,
        ),

        decoration:
            const BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.vertical(
            top:
                Radius.circular(24),
          ),
        ),

        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Subtotal',
                  style:
                      GoogleFonts.sora(
                    fontSize: 13,
                    color:
                        AppTheme.mutedText,
                  ),
                ),

                const Spacer(),

                Text(
                  '₹${_total.toStringAsFixed(0)}',
                  style:
                      GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    AppRoutes.checkoutScreen,
                    extra: widget.restaurantPartnerId,
                  );
                },

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.primary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      const StadiumBorder(),
                ),

                child: Text(
                  'Proceed to Checkout',
                  style:
                      GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CART
  // ============================================================

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 82,
              height: 82,

              decoration:
                  BoxDecoration(
                color:
                    AppTheme.primary
                        .withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                Icons
                    .shopping_bag_outlined,
                size: 38,
                color:
                    AppTheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Your cart is empty',
              style:
                  GoogleFonts
                      .bricolageGrotesque(
                fontSize: 24,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add something delicious and it will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.sora(
                fontSize: 13,
                color:
                    AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
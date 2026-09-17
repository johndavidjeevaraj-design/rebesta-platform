import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../models/address.dart';
import '../../models/cart_item.dart';
import '../../routes/app_routes.dart';
import '../../services/address_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

enum CheckoutType {
  delivery,
  pickup,
}

enum PaymentMethod {
  online,
  cod
}

class CheckoutScreen extends StatefulWidget {
  final String restaurantPartnerId;
  final String restaurantName;

  const CheckoutScreen({
    super.key,
    required this.restaurantPartnerId,
    this.restaurantName = 'Your order',
  });

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final CartService _cartService = CartService();
  final AddressService _addressService = AddressService();
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  // ============================================================
  // DATA
  // ============================================================

  List<CartItem> _items = [];

  double _subtotal = 0;
  double _deliveryFee = 0;
  final double _discount = 0;

  double? _serverTotal;

  List<Address> _addresses = [];

  Address? _selectedAddress;

  // ============================================================
  // CUSTOMER
  // ============================================================

  final String _customerName = '';
  final String _customerPhone = '';

  // ============================================================
  // CHECKOUT
  // ============================================================

  CheckoutType _checkoutType = CheckoutType.delivery;
  PaymentMethod _paymentMethod = PaymentMethod.online;

  String _selectedTime = 'ASAP';

  String? _couponCode;

  bool _loading = true;
  bool _loadingAddress = true;
  bool _processingPayment = false;

  

  String? _currentOrderId;

  late Razorpay _razorpay;

  // ============================================================
  // GET TOTAL
  // ============================================================

  double get _total {
    if (_serverTotal != null) {
      return _serverTotal!;
    }
    final value =
        _subtotal +
        _deliveryFee -
        _discount;

    return value < 0 ? 0 : value;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );

    _loadCart();
    _loadAddress();
    _loadCustomer();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }



  // ============================================================
// CHANGE ITEM QUANTITY
// ============================================================

Future<void> _changeQuantity(int index, int delta) async {
  if (_processingPayment) return;

  final item = _items[index];
  final nextQty = item.quantity + delta;

  if (nextQty < 1) {
    try{
      await _cartService.removeItem(cartItemId: item.id);
      if (!mounted) return;
      await _loadCart();
    } catch (_) {
    _showMessage('Quantity cannot be less than 1');
    return;
  }
  if (nextQty > 20) {
    _showMessage('Maximum 20 per item');
    return;
  }
  }

  // 1) Instant (optimistic) UI update
  setState(() {
    _items[index] = _items[index].copyWith(
      quantity: nextQty,
      subtotal: item.price * nextQty,
    ); // ⚠️ adjust if your subtotal includes per-item discount
    _subtotal = _items.fold(0.0, (sum, i) => sum + i.subtotal);
    _serverTotal = null;                  // ← stale-total fix (explained below)
  });

  // 2) Persist to server — it's the source of truth for payment
  try {
    await _cartService.updateItem( // ⚠️ adjust to YOUR actual method name
      cartItemId: item.id,
      quantity: nextQty,
    );
  } catch (e) {
    debugPrint('QUANTITY SYNC ERROR: $e');
    await _loadCart(); // roll back to server truth
    _showMessage('Could not save the quantity change');
  }
}

  // ============================================================
  // LOAD CART
  // ============================================================

  Future<void> _loadCart() async {
    try {
      debugPrint('================================');
      debugPrint('CHECKOUT CART LOADING');
      debugPrint(
        'Restaurant Partner ID: '
        '${widget.restaurantPartnerId}',
      );
      debugPrint('================================');

      final response =
          await _cartService.getCart
          (

            
        restaurantPartnerId:
            widget.restaurantPartnerId,
      );

      debugPrint('FULL CART RESPONSE: $response');

      final cart = response['cart'];

      if (cart == null) {
        throw Exception('Cart not found');
      }

      final rawItems =
          cart['items'] as List? ?? [];

      final items = rawItems
          .map(
            (item) => CartItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _items = items;

        _subtotal =
            (cart['total'] as num?)
                    ?.toDouble() ??
                0;

        _loading = false;
      });

      debugPrint(
        'CHECKOUT CART SUCCESS: '
        '${items.length} items',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'CHECKOUT CART ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) return;

      setState(() {
        _items = [];
        _subtotal = 0;
        _loading = false;
      });
    }
  }

  // ============================================================
  // LOAD ADDRESS
  // ============================================================

  Future<void> _loadAddress() async {
    try {
      final data =
          await _addressService.getAddresses();

      if (!mounted) return;

      setState(() {
        _addresses = data;

        _selectedAddress =
            data.isNotEmpty
                ? data.first
                : null;

        _loadingAddress = false;
      });
    } catch (e) {
      debugPrint(
        'CHECKOUT ADDRESS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _addresses = [];
        _selectedAddress = null;
        _loadingAddress = false;
      });
    }
  }

  

  // ============================================================
  // CUSTOMER
  // ============================================================

  Future<void> _loadCustomer() async {
    /*
     * We intentionally do not ask the customer
     * for the phone number again.
     *
     * Your authenticated customer profile should
     * provide this information.
     *
     * If your AuthService exposes /me or /profile,
     * connect it here later.
     */
  }

  // ============================================================
  // CHANGE CHECKOUT TYPE
  // ============================================================

  void _changeCheckoutType(
    CheckoutType type,
  ) {
    if (_processingPayment) return;

    setState(() {
      _checkoutType = type;
      
      
      if (type == CheckoutType.pickup) {
        _deliveryFee = 0;
      }
    });
  }

  // ============================================================
  // SELECT TIME
  // ============================================================

  Future<void> _selectTime() async {
    final selected =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _buildTimeSheet();
      },
    );

    if (selected == null) return;

    setState(() {
      _selectedTime = selected;
    });
  }

  // ============================================================
  // TIME SHEET
  // ============================================================

  Widget _buildTimeSheet() {
    final times = [
      'ASAP',
      '30–40 min',
      '40–50 min',
      '50–60 min',
    ];

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Choose ${_checkoutType == CheckoutType.delivery ? 'delivery' : 'pickup'} time',
            style:
                GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color:
                  AppTheme.headlineText,
            ),
          ),

          const SizedBox(height: 18),

          ...times.map(
            (time) {
              final selected =
                  _selectedTime == time;

              return InkWell(
                onTap: () {
                  Navigator.pop(
                    context,
                    time,
                  );
                },
                borderRadius:
                    BorderRadius.circular(16),
                child: Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  padding:
                      const EdgeInsets.all(15),
                  decoration:
                      BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                            .withValues(
                            alpha: 0.08,
                          )
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : const Color(
                              0xFFEDE8E2,
                            ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.mutedText,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: Text(
                          time,
                          style:
                              GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                AppTheme.headlineText,
                          ),
                        ),
                      ),

                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color:
                              AppTheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECT ADDRESS
  // ============================================================

  Future<void> _selectAddress() async {
    final selected =
        await context.push(
      AppRoutes.addressListScreen,
    );

    if (!mounted) return;

    if (selected is Address) {
      setState(() {
        _selectedAddress = selected;
      });
    } else {
      await _loadAddress();
    }
  }

  // ============================================================
  // COUPON
  // ============================================================

  Future<void> _openCoupon() async {
    final controller =
        TextEditingController(
      text: _couponCode ?? '',
    );

    final code =
        await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding:
              EdgeInsets.only(
            bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom,
          ),
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply coupon',
                  style:
                      GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppTheme.headlineText,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                TextField(
                  controller: controller,
                  textCapitalization:
                      TextCapitalization.characters,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Enter coupon code',
                    prefixIcon:
                        const Icon(
                      Icons.local_offer_outlined,
                    ),
                    filled: true,
                    fillColor:
                        AppTheme.backgroundLight,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      final value =
                          controller.text
                              .trim();

                      if (value.isEmpty) {
                        Navigator.pop(
                          context,
                        );
                        return;
                      }

                      Navigator.pop(
                        context,
                        value,
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
                      'Apply Coupon',
                      style:
                          GoogleFonts.sora(
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
      },
    );

    controller.dispose();

    if (!mounted) return;

    if (code != null &&
        code.isNotEmpty) {
      setState(() {
        _couponCode = code;
      });

      _showMessage(
        'Coupon "$code" selected',
      );

      /*
       * IMPORTANT:
       *
       * Actual coupon validation should call
       * your CouponsController:
       *
       * POST /coupons/apply
       *
       * We are not inventing that response here.
       */
    }
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  // ============================================================
  // PLACE ORDER
  //
  // No order is created here. This only creates a Razorpay
  // payment to pay against. The real order is created by the
  // backend only after payment is verified.
  // ============================================================

  Future<void> _placeOnlineOrder() async {
    if (_processingPayment) return;

    if (_checkoutType == CheckoutType.delivery) {
      if (_selectedAddress == null) {
        _showMessage('Please select a delivery address');
        return;
      }
    }

    if (_items.isEmpty) {
      _showMessage('Your cart is empty');
      return;
    }

    setState(() {
      _processingPayment = true;
    });

    try {
      debugPrint('================================');
      debugPrint('CREATING CHECKOUT PAYMENT');
      debugPrint('Restaurant: ${widget.restaurantPartnerId}');
      debugPrint('Address: ${_selectedAddress?.id}');
      debugPrint('================================');

      final paymentResponse =
    await _paymentService.createCheckoutPayment(
  addressId: _checkoutType == CheckoutType.delivery
      ? _selectedAddress?.id
      : null,
  restaurantPartnerId: widget.restaurantPartnerId,
  couponCode: _couponCode,
  orderType: _checkoutType == CheckoutType.delivery
      ? 'delivery'
      : 'pickup',
);

      debugPrint('PAYMENT ORDER RESPONSE: $paymentResponse');

      final razorpayOrderId =
          paymentResponse['orderId']?.toString();
      final key = paymentResponse['key']?.toString();
      final amount = paymentResponse['amount'];
      final currency =
          paymentResponse['currency']?.toString() ?? 'INR';

      final serverAmount = (amount as num).toDouble();
      

      if (mounted) {
  setState(() {
    _serverTotal = serverAmount / 100;
  });
}

debugPrint(
  'SERVER PAYMENT AMOUNT: ₹$serverAmount',
);

      if (razorpayOrderId == null || razorpayOrderId.isEmpty) {
        throw Exception('Unable to start payment. Please try again.');
      }

      if (key == null || key.isEmpty) {
        throw Exception('Unable to start payment. Please try again.');
      }

      final options = {
        'key': key,
        'amount': amount,
        'currency': currency,
        'name': 'REBESTA',
        'description': _checkoutType == CheckoutType.delivery
            ? 'Food Delivery Order'
            : 'Food Pickup Order',
        'order_id': razorpayOrderId,
        if (_customerPhone.isNotEmpty)
          'prefill': {
            'name': _customerName,
            'contact': _customerPhone,
          },
        'theme': {'color': '#F05C03'},
        'modal': {'confirm_close': true, 'animation': true},
        'retry': {'enabled': true, 'max_count': 3},
      };

      debugPrint('OPENING RAZORPAY');
      debugPrint('================================');
debugPrint('RAZORPAY FINAL AMOUNT');
debugPrint('Server amount paise: $amount');
debugPrint(
  'Server amount rupees: ${serverAmount.toStringAsFixed(2)}',
);
debugPrint(
  'Checkout UI total: ₹${_total.toStringAsFixed(2)}',
);
debugPrint('================================');


      _razorpay.open(options);
    } catch (e, stackTrace) {
      debugPrint('CHECKOUT PAYMENT ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _processingPayment = false;
      });

      _showMessage(_friendlyError(e));
    }
  }

  // ============================================================
// PLACE ORDER (dispatcher)
// ============================================================

Future<void> _placeOrder() async {
  if (_paymentMethod == PaymentMethod.cod) {
    await _placeCODOrder();
  } else {
    await _placeOnlineOrder();
  }
}

// ============================================================
// PLACE COD ORDER — NO Razorpay. Creates the order directly.
// ============================================================

Future<void> _placeCODOrder() async {
  if (_processingPayment) return;

  if (_checkoutType == CheckoutType.delivery && _selectedAddress == null) {
    _showMessage('Please select a delivery address');
    return;
  }

  if (_items.isEmpty) {
    _showMessage('Your cart is empty');
    return;
  }

  setState(() => _processingPayment = true);

  try {
    debugPrint('================================');
    debugPrint('📦 PLACING COD ORDER');
    debugPrint('Restaurant: ${widget.restaurantPartnerId}');
    debugPrint('Address: ${_selectedAddress?.id}');
    debugPrint('================================');

    final response = await _orderService.checkout(
  addressId: _checkoutType == CheckoutType.delivery
      ? _selectedAddress?.id
      : null,
  restaurantPartnerId: widget.restaurantPartnerId,
  couponCode: _couponCode,
);

    debugPrint('COD ORDER RESPONSE: $response');   // ← we need this log!

    final order = response['order'] is Map
        ? Map<String, dynamic>.from(response['order'] as Map)
        : response;

    final orderId = (order['id'] ?? order['orderId'] ?? '').toString();

    if (orderId.isEmpty) {
      throw Exception('Order could not be confirmed');
    }

    if (!mounted) return;
    setState(() => _processingPayment = false);

    context.go(AppRoutes.orderTrackingScreen, extra: orderId);
  } catch (e) {
    debugPrint('COD ORDER ERROR: $e');
    if (!mounted) return;
    setState(() => _processingPayment = false);
    _showMessage(_friendlyError(e));
  }
}

  // ============================================================
  // PAYMENT SUCCESS
  //
  // The real order is created here, server-side, as a result
  // of verified payment — not before.
  // ============================================================

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    debugPrint('RAZORPAY PAYMENT SUCCESS: ${response.paymentId}');

    if (response.orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      if (!mounted) return;
      setState(() => _processingPayment = false);
      _showMessage(
        'Payment received, but verification data is missing. '
        'Please contact support if money was deducted.',
      );
      return;
    }

    try {
      final result = await _paymentService.verifyPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        signature: response.signature!,
      );

      debugPrint('VERIFY RESPONSE: $result');

      if (result['success'] != true) {
        throw Exception('Payment verification failed');
      }

      final order = result['order'];
      final orderId = order?['id']?.toString();

      if (orderId == null || orderId.isEmpty) {
        throw Exception('Order could not be confirmed');
      }

      _currentOrderId = orderId;

      if (!mounted) return;

      setState(() {
        _processingPayment = false;
      });

      context.go(
        AppRoutes.orderTrackingScreen,
        extra: orderId,
      );
    } catch (e, stackTrace) {
      debugPrint('PAYMENT VERIFICATION ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _processingPayment = false;
      });

      _showMessage(
        'Payment received, but we could not confirm your order. '
        'Please contact support before trying again.',
      );
    }
  }

  // ============================================================
  // PAYMENT ERROR (failed or cancelled by user)
  //
  // No order was ever created for this attempt — nothing to
  // clean up. Cart remains untouched so the customer can retry.
  // ============================================================

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {
    debugPrint('RAZORPAY PAYMENT FAILED: ${response.code} ${response.message}');

    if (!mounted) return;

    setState(() {
      _processingPayment = false;
    });

    final isCancelled = response.code == 2; // Razorpay: user-cancelled code

    _showMessage(
      isCancelled
          ? 'Payment cancelled. Your order has not been placed — your cart is still saved.'
          : 'Payment could not be completed. Your order has not been placed. Please try again.',
    );
  }

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    debugPrint('External wallet: ${response.walletName}');

    if (!mounted) return;

    setState(() {
      _processingPayment = false;
    });
  }

  // ============================================================
  // FRIENDLY ERROR MESSAGE
  // ============================================================

  String _friendlyError(Object e) {
    final message = e.toString();

    if (message.contains('DioException') ||
        message.contains('SocketException')) {
      return 'Something went wrong. Please check your connection and try again.';
    }

    return message.replaceFirst('Exception: ', '');
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          style:
              GoogleFonts.sora(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

   // ============================================================
  // BUILD
  // ============================================================

   // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F5),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _items.isEmpty
              ? _emptyCart()
              : _buildSwiggyCheckout(),
    );
  }

  // ============================================================
  // SWIGGY STYLE CHECKOUT
  // ============================================================

  Widget _buildSwiggyCheckout() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildSwiggyHeader(),
            ),

            SliverToBoxAdapter(
              child: _buildSavingsBanner(),
            ),

            SliverToBoxAdapter(
              child: _buildCartCard(),
            ),

            SliverToBoxAdapter(
              child: _buildSurpriseDeals(),
            ),

            SliverToBoxAdapter(
              child: _buildSavingsCorner(),
            ),

            SliverToBoxAdapter(
              child: _buildDeliveryOptions(),
            ),

            SliverToBoxAdapter(
              child: _buildSwiggyBillDetails(),

            ),

            SliverToBoxAdapter(
              child: _buildPaymentMethodSection()
              ),

            SliverToBoxAdapter(
              child: _buildCancellationPolicy(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),

        _buildSwiggyBottomBar(),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildSwiggyHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        18,
        42,
        12,
        12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _processingPayment
                ? null
                : () => context.pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 23,
              color: Color(0xFF444444),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
  widget.restaurantName,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: GoogleFonts.sora(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF202124),
  ),
),

                const SizedBox(height: 4),

GestureDetector(
  onTap: _processingPayment ||
          _checkoutType == CheckoutType.pickup
      ? null
      : _selectAddress,
  child: Row(
    children: [
      Icon(
        _checkoutType == CheckoutType.pickup
            ? Icons.storefront_rounded
            : Icons.home_rounded,
        size: 19,
        color: const Color(0xFF202124),
      ),

      const SizedBox(width: 6),

      Text(
        _checkoutType == CheckoutType.pickup
            ? 'Pickup'
            : 'Home',
        style: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF202124),
        ),
      ),

      const SizedBox(width: 5),

      const Text(
        '|',
        style: TextStyle(
          color: Color(0xFFAAAAAA),
        ),
      ),

      const SizedBox(width: 5),

      Expanded(
        child: Text(
          _checkoutType == CheckoutType.pickup
              ? 'Collect from restaurant'
              : _selectedAddress?.address ??
                  'Select delivery address',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.sora(
            fontSize: 13,
            color: const Color(0xFF888888),
          ),
        ),
      ),

      const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 22,
        color: Color(0xFF777777),
      ),
    ],
  ),
),
              ],
            ),
          ),

          const Icon(
            Icons.more_vert_rounded,
            size: 25,
            color: Color(0xFF333333),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVINGS BANNER
  // ============================================================

Widget _buildSavingsBanner() {
  final couponApplied = _couponCode != null && _couponCode!.isNotEmpty;

  return Container(
    margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFE0F7EF),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFC3EBDD)),
    ),
    child: Row(
      children: [
        const Text(
          '✦',
          style: TextStyle(fontSize: 17, color: Color(0xFF269E75)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            couponApplied
                ? 'Coupon "${_couponCode!}" applied ✓'
                : 'Add a coupon to save more',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF269E75),
            ),
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // CART CARD
  // ============================================================

  Widget _buildCartCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),
      padding: const EdgeInsets.fromLTRB(
        14,
        15,
        14,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          ...List.generate(
            _items.length,
            (index) {
              final item = _items[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      index == _items.length - 1
                          ? 12
                          : 14,
                ),
                child: _buildSwiggyCartItem(item, index),
              );
            },
          ),

          const Divider(
            height: 1,
            color: Color(0xFFE8E8E8),
          ),

          const SizedBox(height: 13),

Row(
  children: [
    Expanded(
      child: _cartActionButton(
        Icons.add_rounded,
        'Add Items',
        onTap: () {
          context.pop();
        },
        expanded: true,
      ),
    ),

    const SizedBox(width: 8),

    Expanded(
      child: _cartActionButton(
        Icons.edit_outlined,
        'Cooking requests',
        onTap: () {
          _showMessage(
            'Cooking requests coming soon',
          );
        },
        expanded: true,
      ),
    ),

    const SizedBox(width: 8),

    Expanded(
      child: Container(
        height: 43,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFD9D9D9),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFBBBBBB),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),

            const SizedBox(width: 6),

            Expanded(
              child: Text(
                'Cutlery',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
        ],
      ),
    );
  }

  Widget _buildSwiggyCartItem(
    CartItem item,
    int index
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _vegIndicator(item.isVeg),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sora(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF444444),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Container(
          height: 40,
          constraints:
              const BoxConstraints(
            minWidth: 108,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFD5D5D5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ],
          ),
child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _quantityButton(
      '−',
      enabled: item.quantity > 1 && !_processingPayment,
      onTap: () => _changeQuantity(index, -1),
    ),

    Text(
      '${item.quantity}',
      style: GoogleFonts.sora(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF444444),
      ),
    ),

    _quantityButton(
      '+',
      enabled: !_processingPayment,
      onTap: () => _changeQuantity(index, 1),
    ),
  ],
),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 55,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              if (item.price != item.subtotal)
                Text(
                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    decoration:
                        TextDecoration.lineThrough,
                    color:
                        const Color(0xFF888888),
                  ),
                ),

              Text(
                '₹${item.subtotal.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      const Color(0xFF444444),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CART ACTION
  // ============================================================

  Widget _cartActionButton(
    IconData icon,
    String title, {
    required VoidCallback onTap,
    bool expanded = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: expanded ? double.infinity
          : null,
        height: 43,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFD9D9D9),
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: const Color(0xFF666666),
            ),

            const SizedBox(width: 5),

            Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _quantityButton(
  String label, {
  required bool enabled,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: enabled
              ? const Color(0xFF269E75)
              : const Color(0xFFC8C8C8),
        ),
      ),
    ),
  );
}

// ============================================================
// VEG / NON-VEG INDICATOR (FSSAI style)
// ============================================================

Widget _vegIndicator(bool isVeg) {
  final color = isVeg
      ? const Color(0xFF159570) // green
      : const Color(0xFFC62828); // non-veg red

  return Container(
    width: 22,
    height: 22,
    margin: const EdgeInsets.only(top: 2),
    decoration: BoxDecoration(
      border: Border.all(
        color: color,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Center(
      child: isVeg
          ? CircleAvatar(
              radius: 4,
              backgroundColor: color,
            )
          : CustomPaint(
            size: const Size(12, 11),
            painter: _TrianglePainter(color),
          ),
    ),
  );
}

  // ============================================================
  // SURPRISE DEALS
  // ============================================================

  Widget _buildSurpriseDeals() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),
      padding: const EdgeInsets.fromLTRB(
        14,
        18,
        14,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SURPRISE DEALS ✦',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: const Color(0xFFD03FC9),
                ),
              ),

              const Spacer(),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1FD),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  '1m : 22s',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color:
                        const Color(0xFFD03FC9),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection:
                  Axis.horizontal,
              children: [
                _dealCard(
                  title: 'Add a side',
                  price: 39,
                ),
                _dealCard(
                  title: 'Extra portion',
                  price: 49,
                ),
                _dealCard(
                  title: 'Dessert',
                  price: 59,
                ),
                _dealCard(
                  title: 'Beverage',
                  price: 49,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dealCard({
    required String title,
    required double price,
  }) {
    return Container(
      width: 105,
      margin: const EdgeInsets.only(
        right: 10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 105,
                height: 90,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF1EEE9),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 32,
                  color: Color(0xFFBBBBBB),
                ),
              ),

              Positioned(
                right: -2,
                top: -5,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          const Color(0xFFD5D5D5),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 21,
                    color:
                        Color(0xFF159570),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF555555),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Price Drop',
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD03FC9),
            ),
          ),

          Text(
            '₹$price',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVINGS CORNER
  // ============================================================

  Widget _buildSavingsCorner() {
    final applied =
        _couponCode != null &&
        _couponCode!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              10,
            ),
            child: Text(
              'SAVINGS CORNER',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFF999999),
              ),
            ),
          ),

          _savingsRow(
            icon: Icons.local_offer_rounded,
            title: 'Apply Coupon',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              size: 27,
              color: Color(0xFF333333),
            ),
            onTap: _openCoupon,
          ),

          _savingsRow(
            icon: Icons.local_offer_rounded,
            title: applied
                ? 'Coupon "$_couponCode" applied'
                : 'Add a coupon and save more',
            trailing: applied
                ? Text(
                    '✓ Applied',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          const Color(0xFF269E75),
                    ),
                  )
                : null,
          ),

          //Only claim free delivery when it's actually free

          if (_checkoutType == CheckoutType.delivery &&
              _deliveryFee <= 0)
          _savingsRow(
            icon: Icons.local_shipping_rounded,
            title: 'Free delivery on this order',
            trailing: Text(
              '✓ Applied',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF269E75),
              ),
            ),
            bottom: true,
          ),
        ],
      ),
    );
  }

  Widget _savingsRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool bottom = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          border: bottom
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8E8E8),
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5B24),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 21,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      const Color(0xFF444444),
                ),
              ),
            ),

            if (trailing != null)
              trailing,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DELIVERY OPTIONS
  // ============================================================

 Widget _buildDeliveryOptions() {
  final isDelivery =
      _checkoutType == CheckoutType.delivery;

  return Container(
    margin: const EdgeInsets.fromLTRB(
      16,
      4,
      16,
      12,
    ),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // DELIVERY / PICKUP TOGGLE
        // ========================================================

        Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _processingPayment
                      ? null
                      : () => _changeCheckoutType(
                            CheckoutType.delivery,
                          ),
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDelivery
                          ? Colors.black
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delivery_dining_rounded,
                          size: 19,
                          color: isDelivery
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Delivery',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDelivery
                                ? Colors.white
                                : const Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: _processingPayment
                      ? null
                      : () => _changeCheckoutType(
                            CheckoutType.pickup,
                          ),
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !isDelivery
                          ? Colors.black
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 19,
                          color: !isDelivery
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Pickup',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: !isDelivery
                                ? Colors.white
                                : const Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ========================================================
        // DELIVERY MODE
        // ========================================================

        if (isDelivery) ...[
          _deliveryChoice(
            title: 'Express',
            subtitle:
                'Fastest delivery, directly to you!',
            time: '20–25 mins',
            selected: false,
          ),

          _deliveryChoice(
            title: 'Standard',
            subtitle:
                'Minimal order grouping',
            time: '25–30 mins',
            selected: true,
          ),

          _deliveryChoice(
            title: 'Eco Saver',
            subtitle:
                'Lesser CO2 by order grouping',
            time: '30–40 mins',
            selected: false,
            last: true,
          ),
        ]

        // ========================================================
        // PICKUP MODE
        // ========================================================

        else ...[
          Container(
            padding: const EdgeInsets.fromLTRB(
              8,
              10,
              8,
              12,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFF5B24)
                            .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFFFF5B24),
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup from restaurant',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color:
                              const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your order will be prepared for pickup.',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color:
                              const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  '20–30 mins',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        const Color(0xFFFF5B24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

  Widget _deliveryChoice({
    required String title,
    required String subtitle,
    required String time,
    required bool selected,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFE8E8E8),
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            child: Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 27,
              color: selected
                  ? const Color(0xFFFF5B24)
                  : const Color(0xFF888888),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? const Color(0xFFFF5B24)
                        : const Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color:
                        const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),

          Text(
            time,
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFFFF5B24)
                  : const Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BILL DETAILS
  // ============================================================

  Widget _buildSwiggyBillDetails() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F5EF),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 21,
                  color: Color(0xFF269E75),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                'To Pay',
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF444444),
                ),
              ),

              const Spacer(),

              Text(
                '₹${_total.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF222222),
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 23,
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(
            height: 1,
            color: Color(0xFFE8E8E8),
          ),

          const SizedBox(height: 13),

          _swiggyBillRow(
            'Item total',
            _subtotal,
          ),

          const SizedBox(height: 10),

          _swiggyBillRow(
            'Delivery fee',
            _deliveryFee,
          ),

          if (_discount > 0) ...[
            const SizedBox(height: 10),

            _swiggyBillRow(
              'Coupon discount',
              -_discount,
              green: true,
            ),
          ],

          const SizedBox(height: 15),

          Row(
            children: [
              Text(
                'Total',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),

              const Spacer(),

              Text(
                '₹${_total.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF222222),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          const SizedBox(height: 9),

if (_discount > 0)
  Align(
    alignment: Alignment.centerLeft,
    child: Text(
      '₹${_discount.toStringAsFixed(0)} saved on the total!',
      style: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF269E75),
      ),

    ),
  ),
        ],
      ),
    );
  }

  // ============================================================
// PAYMENT METHOD
// ============================================================

Widget _buildPaymentMethodSection() {
  final isCod = _paymentMethod == PaymentMethod.cod;

  return Container(
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: InkWell(
      onTap: _processingPayment ? null : _pickPaymentMethod,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5B24).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isCod ? Icons.payments_rounded : Icons.account_balance_wallet_rounded,
              size: 21,
              color: const Color(0xFFFF5B24),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCod
                      ? 'Cash on Delivery'
                      : 'UPI • Cards • Wallets (online)',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 27, color: Color(0xFF333333)),
        ],
      ),
    ),
  );
}

Future<void> _pickPaymentMethod() async {
  final selected = await showModalBottomSheet<PaymentMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose payment method',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.headlineText,
            ),
          ),
          const SizedBox(height: 18),
          _paymentOption(
            PaymentMethod.online,
            Icons.account_balance_wallet_rounded,
            'Pay online',
            'UPI • Cards • Wallets',
          ),
          _paymentOption(
            PaymentMethod.cod,
            Icons.payments_rounded,
            'Cash on Delivery',
            'Pay cash when your order arrives',
          ),
        ],
      ),
    ),
  );

  if (selected != null && selected != _paymentMethod && mounted) {
    setState(() => _paymentMethod = selected);
  }
}

Widget _paymentOption(PaymentMethod method, IconData icon, String title, String subtitle) {
  final selected = _paymentMethod == method;
  return InkWell(
    onTap: () => Navigator.pop(context, method),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF5B24).withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFFFF5B24) : const Color(0xFFEDE8E2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? const Color(0xFFFF5B24) : AppTheme.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.headlineText)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.sora(fontSize: 11, color: AppTheme.mutedText)),
              ],
            ),
          ),
          if (selected) const Icon(Icons.check_circle_rounded, color: Color(0xFFFF5B24)),
        ],
      ),
    ),
  );
}

  Widget _swiggyBillRow(
    String title,
    double amount, {
    bool green = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 12,
            color: const Color(0xFF777777),
          ),
        ),

        const Spacer(),

        Text(
          '${amount < 0 ? '-' : ''}'
          '₹${amount.abs().toStringAsFixed(0)}',
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: green
                ? const Color(0xFF269E75)
                : const Color(0xFF555555),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CANCELLATION POLICY
  // ============================================================

  Widget _buildCancellationPolicy() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        3,
        20,
        10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation policy:',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFAAAAAA),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Please double-check your order and address details.\n'
            'Orders are non-refundable once placed.',
            style: GoogleFonts.sora(
              fontSize: 11,
              height: 1.55,
              color: const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM PAY BAR
  // ============================================================

  Widget _buildSwiggyBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            13,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Color(0xFFE5E5E5),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
  _paymentMethod == PaymentMethod.cod
      ? 'PAY ON DELIVERY'
      : 'PAY USING',
  style: GoogleFonts.sora(
    fontSize: 9,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF999999),
    letterSpacing: .5,
  ),
),

const SizedBox(height: 2),

Text(
  _paymentMethod == PaymentMethod.cod
      ? 'Cash'
      : 'UPI • Cards • Wallets',
  style: GoogleFonts.sora(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF444444),
  ),
),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed:
                        _processingPayment
                            ? null
                            : () {
                              print('🔥 PAY BUTTON CLICKED');
                             _placeOrder();
                            },

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFF5B24),
                      disabledBackgroundColor:
                          const Color(0x99FF5B24),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: _processingPayment
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _paymentMethod == PaymentMethod.cod
                            ? 'Place Order'
                            :  'Pay ₹${_total.toStringAsFixed(0)}',
                            style:
                                GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CART
  // ============================================================

  Widget _emptyCart() {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF2F2F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppTheme.primary
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 38,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Your cart is empty',
                style:
                    GoogleFonts.bricolageGrotesque(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.headlineText,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Add something delicious and come back.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

// ============================================================
// NON-VEG TRIANGLE PAINTER
// ============================================================

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}


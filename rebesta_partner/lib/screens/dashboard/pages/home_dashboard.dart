import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/partner_auth_service.dart';
import '../../../core/services/partner_orders_service.dart';
import '../../../models/partner_order.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
  });

  @override
  State<HomeDashboard> createState() =>
      HomeDashboardState();
}

class HomeDashboardState extends State<HomeDashboard> {
  // ============================================================
  // SERVICES
  // ============================================================

  final PartnerOrdersService _ordersService =
      PartnerOrdersService();


  Future<void> refreshOrders() async {
    await _loadDashboard();
  }

  Future<void> _refresh() async {
    await _loadDashboard();
  }

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;

  String? errorMessage;

  List<PartnerOrder> orders = [];

  String partnerName = 'Partner';
  String restaurantName = 'Restaurant';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      // Load logged-in partner information.
      await _loadPartnerInfo();

      // Load orders through the SERVICE.
      final result = await _ordersService.getOrders();

      debugPrint('========================================');
debugPrint('🏠 PARTNER DASHBOARD ORDERS');
debugPrint('Order count: ${result.length}');
debugPrint('Orders: $result');
debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // LOAD PARTNER INFO
  // ============================================================

 Future<void> _loadPartnerInfo() async {
  final profile =
      await PartnerAuthService.getPartnerProfile();

  if (!mounted) return;

  if (profile != null) {
    final name =
        profile['name']?.toString();

    final restaurant =
        profile['restaurantName']?.toString();

    setState(() {
      if (name != null &&
          name.trim().isNotEmpty) {
        partnerName = name.trim();
      }

      if (restaurant != null &&
          restaurant.trim().isNotEmpty) {
        restaurantName = restaurant.trim();
      }
    });

    return;
  }

  // Fallback to locally stored data.
  final savedName =
      await PartnerAuthService.getPartnerName();

  final savedRestaurant =
      await PartnerAuthService.getRestaurantName();

  if (!mounted) return;

  setState(() {
    if (savedName != null &&
        savedName.trim().isNotEmpty) {
      partnerName = savedName.trim();
    }

    if (savedRestaurant != null &&
        savedRestaurant.trim().isNotEmpty) {
      restaurantName =
          savedRestaurant.trim();
    }
  });
}

  // ============================================================
  // REFRESH
  // ============================================================

  // ============================================================
  // TODAY ORDERS
  // ============================================================

  List<PartnerOrder> get todayOrders {
    final now = DateTime.now();

    return orders.where((order) {
      final date = order.createdAt.toLocal();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  // ============================================================
  // TODAY ORDER COUNT
  // ============================================================

  int get todayOrderCount {
    return todayOrders.length;
  }

  // ============================================================
  // TODAY REVENUE
  // ============================================================

  double get todayRevenue {
    double total = 0;

    for (final order in todayOrders) {
      final status =
          order.orderStatus.toLowerCase();

      // Cancelled orders should not count as revenue.
      if (status == 'cancelled') {
        continue;
      }

      total += order.totalAmount;
    }

    return total;
  }

  // ============================================================
  // STATUS COUNTS
  // ============================================================

  int get pendingOrders {
    return orders.where(
      (order) =>
          order.orderStatus.toLowerCase() ==
          'pending',
    ).length;
  }

  int get preparingOrders {
    return orders.where(
      (order) =>
          order.orderStatus.toLowerCase() ==
          'preparing',
    ).length;
  }

  int get completedOrders {
    return orders.where(
      (order) =>
          order.orderStatus.toLowerCase() ==
          'completed',
    ).length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _loadingView();
    }

    if (errorMessage != null) {
      return _errorView();
    }

    return RefreshIndicator(
      onRefresh: _refresh,

      color: AppColors.primary,

      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          110,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(),

            const SizedBox(height: 24),

            // ==================================================
            // RESTAURANT STATUS
            // ==================================================

            _buildRestaurantStatus(),

            const SizedBox(height: 26),

            // ==================================================
            // TODAY
            // ==================================================

            const Text(
              'Today',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon:
                        Icons.receipt_long_rounded,
                    title: 'Orders',
                    value:
                        todayOrderCount.toString(),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _statCard(
                    icon:
                        Icons.currency_rupee_rounded,
                    title: 'Revenue',
                    value:
                        '₹${todayRevenue.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==================================================
            // ORDER STATUS
            // ==================================================

            const Text(
              'Order Status',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _statusCard(
                    icon:
                        Icons.schedule_rounded,
                    title: 'Pending',
                    value: pendingOrders,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _statusCard(
                    icon:
                        Icons.local_fire_department_rounded,
                    title: 'Preparing',
                    value: preparingOrders,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _statusCard(
                    icon:
                        Icons.check_circle_rounded,
                    title: 'Completed',
                    value: completedOrders,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==================================================
            // RECENT ORDERS
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),

                if (orders.isNotEmpty)
                  Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.primary,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ==================================================
            // ORDERS
            // ==================================================

            if (orders.isEmpty)
              _emptyOrders()
            else
              ...orders
                  .take(5)
                  .map(_orderCard),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'Good ${_greeting()} 👋',

                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 3),

               Text(
  restaurantName,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
  ),
),
            ],
          ),
        ),

        Container(
          width: 52,
          height: 52,

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(17),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.04,
                ),

                blurRadius: 12,

                offset:
                    const Offset(0, 4),
              ),
            ],
          ),

          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.black,
            size: 25,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Morning';
    }

    if (hour < 17) {
      return 'Afternoon';
    }

    return 'Evening';
  }

  // ============================================================
  // RESTAURANT STATUS
  // ============================================================

  Widget _buildRestaurantStatus() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color:
                  Colors.green.withValues(
                alpha: 0.10,
              ),

              borderRadius:
                  BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.green,
              size: 27,
            ),
          ),

          const SizedBox(width: 15),

       Expanded(
  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Text(
        restaurantName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 4),

      const Text(
        'Your restaurant is accepting orders',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: Colors.grey,
        ),
      ),
    ],
  ),
),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color:
                  Colors.green.withValues(
                alpha: 0.10,
              ),

              borderRadius:
                  BorderRadius.circular(30),
            ),

            child: const Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.green,
                ),

                SizedBox(width: 6),

                Text(
                  'ONLINE',

                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 166,

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.10),

              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              color: AppColors.primary,
              size: 25,
            ),
          ),

          const Spacer(),

          Text(
            value,

            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 25,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _statusCard({
    required IconData icon,
    required String title,
    required int value,
  }) {
    return Container(
      height: 120,

      padding:
          const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),

          const SizedBox(height: 7),

          Text(
            value.toString(),

            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _orderCard(
    PartnerOrder order,
  ) {
    final orderId = order.id;

    final shortId =
        orderId.length > 8
            ? orderId
                .substring(0, 8)
                .toUpperCase()
            : orderId.toUpperCase();

    final customerName =
        order.customer?.name ??
            'Customer';

    final itemCount =
        order.items.length;

    final itemText =
        itemCount == 1
            ? '1 item'
            : '$itemCount items';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          // ======================================================
          // ORDER ICON
          // ======================================================

          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.10),

              borderRadius:
                  BorderRadius.circular(15),
            ),

            child: Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 13),

          // ======================================================
          // ORDER INFORMATION
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  '#$shortId',

                  style:
                      const TextStyle(
                    fontFamily:
                        'Poppins',
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  customerName,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    fontFamily:
                        'Poppins',
                    fontSize: 11,
                    color:
                        AppColors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  itemText,

                  style: TextStyle(
                    fontFamily:
                        'Poppins',
                    fontSize: 10,
                    color:
                        AppColors.grey,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // AMOUNT + STATUS
          // ======================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',

                style:
                    const TextStyle(
                  fontFamily:
                      'Poppins',
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 5),

              _statusBadge(
                order.orderStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.10),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight:
              FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
    String status,
  ) {
    switch (
        status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;

      case 'preparing':
        return Colors.orange;

      case 'ready':
        return Colors.purple;

      case 'completed':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      case 'pending':
      default:
        return AppColors.primary;
    }
  }

  // ============================================================
  // EMPTY ORDERS
  // ============================================================

  Widget _emptyOrders() {
    return Container(
      width: double.infinity,

      height: 220,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 55,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 15),

          const Text(
            'No orders yet',

            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'New orders will appear here.',

            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _loadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              'Could not load dashboard',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage ??
                  'Something went wrong.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  _loadDashboard,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,

                foregroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              child: const Text(
                'Try Again',

                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
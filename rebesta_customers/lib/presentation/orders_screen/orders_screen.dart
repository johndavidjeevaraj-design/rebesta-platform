import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      debugPrint('================================');
      debugPrint('📦 CUSTOMER ORDERS');
      debugPrint('GET /orders/my');
      debugPrint('================================');

      final response =
          await _orderService.getMyOrders();

      debugPrint(
        '📦 CUSTOMER ORDERS RESPONSE: $response',
      );

      final rawOrders = response['orders'];

      if (rawOrders is List) {
        _orders = rawOrders
            .whereType<Map>()
            .map(
              (order) =>
                  Map<String, dynamic>.from(order),
            )
            .toList();
      } else {
        _orders = [];
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('❌ CUSTOMER ORDERS ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _status(Map<String, dynamic> order) {
    return (order['order_status'] ?? 'pending')
        .toString()
        .toLowerCase()
        .trim();
  }

   String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'New Order';

      case 'accepted':
        return 'Confirmed';

      case 'ready':
        return 'Ready for Pickup';

      case 'accepted_for_delivery':
        return 'Rider Assigned';

      case 'arrived_at_restaurant':
        return 'Rider at Restaurant';

      case 'picked_up':
      case 'out_for_delivery':
        return 'Out for Delivery';

      case 'arrived_at_customer':
        return 'Rider at Customer';

      case 'delivered':
        return 'Delivered';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

    Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'accepted':
        return Colors.blue;

      case 'ready':
        return Colors.deepOrange;

      case 'accepted_for_delivery':
      case 'arrived_at_restaurant':
      case 'picked_up':
      case 'out_for_delivery':
      case 'arrived_at_customer':
        return Colors.purple;

      case 'delivered':
        return Colors.teal;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }
  // ============================================================
  // ORDER ID
  // ============================================================

  String _orderId(
    Map<String, dynamic> order,
  ) {
    return order['id']?.toString() ?? '';
  }

  // ============================================================
  // TOTAL
  // ============================================================

  String _total(
    Map<String, dynamic> order,
  ) {
    final value =
        order['total_amount'] ?? 0;

    final amount =
        value is num
            ? value.toDouble()
            : double.tryParse(
                  value.toString(),
                ) ??
                0;

    return '₹${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // ITEMS
  // ============================================================

  String _itemsText(
    Map<String, dynamic> order,
  ) {
    final items =
        order['order_items'];

    if (items is! List ||
        items.isEmpty) {
      return 'Order items';
    }

    final names = <String>[];

    for (final item in items) {
      if (item is! Map) continue;

      final menuItem =
          item['menu_items'];

      if (menuItem is Map) {
        final name =
            menuItem['name']?.toString();

        if (name != null &&
            name.isNotEmpty) {
          names.add(name);
        }
      }
    }

    if (names.isEmpty) {
      return '${items.length} item${items.length == 1 ? '' : 's'}';
    }

    if (names.length <= 2) {
      return names.join(', ');
    }

    return '${names.take(2).join(', ')} + ${names.length - 2} more';
  }

  // ============================================================
  // OPEN TRACKING
  // ============================================================

  void _openTracking(
    Map<String, dynamic> order,
  ) {
    final orderId =
        _orderId(order);

    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Order information is missing',
          ),
        ),
      );

      return;
    }

    context.push(
      AppRoutes.orderTrackingScreen,
      extra: orderId,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            AppTheme.backgroundLight,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),

          const Icon(
            Icons.error_outline_rounded,
            size: 56,
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Unable to load orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppTheme.mutedText,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton(
              onPressed: _loadOrders,
              child:
                  const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 150),

          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color:
                AppTheme.mutedText,
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              'Your orders will appear here',
              style: TextStyle(
                color:
                    AppTheme.mutedText,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        110,
      ),
      itemCount: _orders.length,
      itemBuilder:
          (context, index) {
        return _buildOrderCard(
          _orders[index],
        );
      },
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
    Map<String, dynamic> order,
  ) {
    final status =
        _status(order);

    final statusColor =
        _statusColor(status);

    final statusLabel =
        _statusLabel(status);

    final itemsText =
        _itemsText(order);

    final total =
        _total(order);

    return GestureDetector(
      onTap: () =>
          _openTracking(order),
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
            const EdgeInsets.all(16),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          boxShadow:
              AppTheme.pillNavShadow,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 22,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Order #${_orderId(order).substring(
                      0,
                      _orderId(order).length > 8
                          ? 8
                          : _orderId(order).length,
                    )}',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color: statusColor
                        .withAlpha(25),
                    borderRadius:
                        BorderRadius
                            .circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color:
                          statusColor,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              itemsText,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    AppTheme.mutedText,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Text(
                  total,
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const Spacer(),

                Text(
                  'Track order',
                  style: TextStyle(
                    color:
                        AppTheme.primary,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(width: 6),

                Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 13,
                  color:
                      AppTheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
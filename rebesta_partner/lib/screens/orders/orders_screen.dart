import 'package:flutter/material.dart';

import '../../core/services/partner_orders_service.dart';
import '../../models/partner_order.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final PartnerOrdersService _ordersService =
      PartnerOrdersService();

  List<PartnerOrder> _orders = [];

  bool _loading = true;
  String? _error;

  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final orders =
          await _ordersService.getOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'PARTNER ORDERS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<PartnerOrder> get _filteredOrders {
    if (_filter == 'all') {
      return _orders;
    }

    return _orders.where((order) {
      return order.orderStatus == _filter;
    }).toList();
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'New Order';

      case 'accepted':
        return 'Accepted';

      case 'preparing':
        return 'Preparing';

      case 'ready':
        return 'Ready';

      case 'completed':
        return 'Completed';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'accepted':
        return Colors.blue;

      case 'preparing':
        return Colors.deepOrange;

      case 'ready':
        return Colors.green;

      case 'completed':
        return Colors.teal;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // PAYMENT LABEL
  // ============================================================

  String _paymentLabel(String paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return 'PAID';

      case 'pending':
        return 'PAYMENT PENDING';

      case 'failed':
        return 'PAYMENT FAILED';

      default:
        return paymentStatus.toUpperCase();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Orders',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    final filters = [
      ('all', 'All'),
      ('pending', 'New'),
      ('accepted', 'Accepted'),
      ('preparing', 'Preparing'),
      ('ready', 'Ready'),
      ('completed', 'Completed'),
    ];

    return Container(
      height: 64,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final item = filters[index];

          final selected =
              _filter == item.$1;

          return GestureDetector(
            onTap: () {
              setState(() {
                _filter = item.$1;
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFFF1F1EF),
                borderRadius:
                    BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                item.$2,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, index) {
          return _buildOrderCard(
            orders[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
    PartnerOrder order,
  ) {
    final statusColor =
        _statusColor(order.orderStatus);

    final customerName =
        order.customer?.name ??
        'Customer';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailsScreen(
                orderId: order.id,
              ),
            ),
          );

          _loadOrders();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor
                          .withAlpha(25),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Text(
                      _statusLabel(
                        order.orderStatus,
                      ),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // CUSTOMER
              // ------------------------------------------------

              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFFEEE7,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color:
                          Color(0xFFFF6B35),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          customerName,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (order
                                .customer
                                ?.mobile
                                .isNotEmpty ==
                            true)
                          Text(
                            order
                                .customer!
                                .mobile,
                            style:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  Text(
                    '₹${order.totalAmount.toStringAsFixed(0)}',
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // ITEMS
              // ------------------------------------------------

              ...order.items
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}×',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          ),
                          Text(
                            '₹${item.subtotal.toStringAsFixed(0)}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              if (order.items.length > 3)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 2,
                  ),
                  child: Text(
                    '+ ${order.items.length - 3} more items',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              const Divider(height: 1),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // PAYMENT + TIME
              // ------------------------------------------------

              Row(
                children: [
                  Icon(
                    order.paymentStatus ==
                            'paid'
                        ? Icons
                            .check_circle_rounded
                        : Icons
                            .pending_rounded,
                    size: 16,
                    color:
                        order.paymentStatus ==
                                'paid'
                            ? Colors.green
                            : Colors.orange,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    _paymentLabel(
                      order.paymentStatus,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          order.paymentStatus ==
                                  'paid'
                              ? Colors.green
                              : Colors.orange,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    _formatTime(
                      order.createdAt,
                    ),
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // ACTION
              // ------------------------------------------------

              _buildActionButton(order),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

 Widget _buildActionButton(
  PartnerOrder order,
) {
  String? nextStatus;
  String label = '';

  switch (order.orderStatus) {
    case 'pending':
      nextStatus = 'accepted';
      label = 'Accept Order';
      break;

    case 'accepted':
      nextStatus = 'preparing';
      label = 'Start Preparing';
      break;

    case 'preparing':
      nextStatus = 'ready';
      label = 'Mark Ready';
      break;

    case 'ready':
      nextStatus = 'completed';
      label = 'Complete Order';
      break;

    case 'completed':
      return Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF9F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Order Completed',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

    default:
      return const SizedBox.shrink();
  }

  return SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: () => _updateStatus(
        order,
        nextStatus!,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus(
    PartnerOrder order,
    String status,
  ) async {
    try {
      await _ordersService.updateStatus(
        orderId: order.id,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Order ${_statusLabel(status).toLowerCase()}',
          ),
        ),
      );

      await _loadOrders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders here',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New customer orders will appear here.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load orders',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadOrders,
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(
    DateTime dateTime,
  ) {
    final hour =
        dateTime.hour % 12 == 0
            ? 12
            : dateTime.hour % 12;

    final minute =
        dateTime.minute
            .toString()
            .padLeft(2, '0');

    final period =
        dateTime.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }
}
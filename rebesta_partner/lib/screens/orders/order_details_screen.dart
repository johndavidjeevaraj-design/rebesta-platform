import 'package:flutter/material.dart';

import '../../core/services/partner_orders_service.dart';
import '../../models/partner_order.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() =>
      _OrderDetailsScreenState();
}

class _OrderDetailsScreenState
    extends State<OrderDetailsScreen> {
  final PartnerOrdersService _service =
      PartnerOrdersService();

  PartnerOrder? _order;

  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final order =
          await _service.getOrder(
        widget.orderId,
      );

      if (!mounted) return;

      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _updateStatus(
    String status,
  ) async {
    if (_order == null) return;

    try {
      setState(() {
        _updating = true;
      });

      final updated =
          await _service.updateStatus(
        orderId: _order!.id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _order = updated;
        _updating = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _updating = false;
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Text(
              'Unable to load order',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadOrder,
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final order = _order!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildHeader(order),

          const SizedBox(height: 16),

          _buildCustomer(order),

          const SizedBox(height: 16),

          _buildItems(order),

          const SizedBox(height: 16),

          _buildAddress(order),

          const SizedBox(height: 20),

          _buildAction(order),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader(
    PartnerOrder order,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '#${order.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment: ${order.paymentStatus.toUpperCase()}',
            style: TextStyle(
              color:
                  order.paymentStatus ==
                          'paid'
                      ? Colors.green
                      : Colors.orange,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomer(
    PartnerOrder order,
  ) {
    final customer =
        order.customer;

    return _section(
      title: 'Customer',
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            child: Icon(
              Icons.person_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                customer?.name ??
                    'Customer',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (customer
                      ?.mobile
                      .isNotEmpty ==
                  true)
                Text(
                  customer!.mobile,
                  style: TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItems(
    PartnerOrder order,
  ) {
    return _section(
      title: 'Items',
      child: Column(
        children: order.items
            .map(
              (item) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment:
                          Alignment.center,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFEEE7,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                      child: Text(
                        '${item.quantity}×',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        item.name,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '₹${item.subtotal.toStringAsFixed(0)}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAddress(
    PartnerOrder order,
  ) {
    return _section(
      title: 'Delivery Address',
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: Color(0xFFFF6B35),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Delivery address details',
              style: TextStyle(
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildAction(
  PartnerOrder order,
) {
  String? nextStatus;
  String label;

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
      label = 'Mark Order Ready';
      break;

    case 'ready':
      return _statusCard(
        'READY - WAITING FOR DELIVERY PARTNER',
      );

    case 'accepted_for_delivery':
      return _statusCard(
        'DELIVERY PARTNER ACCEPTED',
      );

    case 'arrived_at_restaurant':
      return _statusCard(
        'DELIVERY PARTNER AT RESTAURANT',
      );

    case 'picked_up':
      return _statusCard(
        'ORDER PICKED UP',
      );

    case 'out_for_delivery':
      return _statusCard(
        'OUT FOR DELIVERY',
      );

    case 'arrived_at_customer':
      return _statusCard(
        'DELIVERY PARTNER REACHED CUSTOMER',
      );

    case 'delivered':
      return _statusCard(
        'ORDER DELIVERED',
      );

    case 'cancelled':
      return _statusCard(
        'ORDER CANCELLED',
      );

    default:
      return _statusCard(
        order.orderStatus,
      );
  }

  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: _updating
          ? null
          : () => _updateStatus(nextStatus!),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _updating
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
    ),
  );
}
  Widget _statusCard(
    String status,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Text(
        'Order status: ${status.toUpperCase()}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
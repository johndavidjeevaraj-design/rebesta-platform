import 'package:flutter/material.dart';
import '../active_delivery/active_delivery_screen.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/delivery_api_client.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() =>
      _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState
    extends State<AvailableOrdersScreen> {

  bool _loading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // ============================================================
  // LOAD AVAILABLE ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    try {
      debugPrint('=================================');
      debugPrint('🚴 AVAILABLE DELIVERY ORDERS');
      debugPrint(
        'GET: ${ApiConstants.availableOrders}',
      );
      debugPrint('=================================');

      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.get(
        ApiConstants.availableOrders,
        options: options,
      );

      debugPrint(
        'AVAILABLE ORDERS STATUS: ${response.statusCode}',
      );

      debugPrint(
        'AVAILABLE ORDERS RESPONSE: ${response.data}',
      );

      final data = response.data;

      if (data['success'] != true) {
        throw Exception(
          data['message'] ??
              'Failed to load orders',
        );
      }

      if (!mounted) return;

      setState(() {
        _orders = data['orders'] ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        '❌ AVAILABLE ORDERS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load available orders',
      );
    }
  }

  // ============================================================
  // ACCEPT ORDER
  // ============================================================

  Future<void> _acceptOrder(
    String orderId,
  ) async {
    try {
      debugPrint('=================================');
      debugPrint('🚴 ACCEPT DELIVERY ORDER');
      debugPrint('Order ID: $orderId');
      debugPrint(
        'PATCH: ${ApiConstants.acceptOrder(orderId)}',
      );
      debugPrint('=================================');

      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.patch(
        ApiConstants.acceptOrder(orderId),
        options: options,
      );

      debugPrint(
        'ACCEPT ORDER STATUS: ${response.statusCode}',
      );

      debugPrint(
        'ACCEPT ORDER RESPONSE: ${response.data}',
      );

      final data = response.data;

      if (data['success'] != true) {
        throw Exception(
          data['message'] ??
              'Unable to accept order',
        );
      }

      if (!mounted) return;

     final acceptedOrder =
    data['order'];

if (acceptedOrder is! Map) {
  throw Exception(
    'Accepted order data missing',
  );
}

if (!mounted) return;

final completed = await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (_) => ActiveDeliveryScreen(
      order: Map<String, dynamic>.from(
        acceptedOrder,
      ),
    ),
  ),
);

if (!mounted) return;

if (completed == true) {
  if (!mounted) return;

  Navigator.pop(
    context,
    true,
  );
}
    } catch (e) {
      debugPrint(
        '❌ ACCEPT ORDER ERROR: $e',
      );

      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
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
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        title: const Text(
          'Available Orders',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A1D1A),
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loading
                ? null
                : _loadOrders,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,

              child: _orders.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),

                      children: const [
                        SizedBox(height: 140),

                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Color(0xFF756864),
                        ),

                        SizedBox(height: 20),

                        Center(
                          child: Text(
                            'No orders available',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  Color(0xFF2A1D1A),
                            ),
                          ),
                        ),

                        SizedBox(height: 8),

                        Center(
                          child: Text(
                            'New delivery orders will appear here.',
                            style: TextStyle(
                              color:
                                  Color(0xFF756864),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),

                      padding:
                          const EdgeInsets.all(16),

                      itemCount: _orders.length,

                      itemBuilder:
                          (context, index) {
                        final order =
                            _orders[index];

                        return _orderCard(
                          order,
                        );
                      },
                    ),
            ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _orderCard(
    dynamic order,
  ) {
    final customer =
        order['customers'] ?? {};

    final address =
        order['addresses'] ?? {};

    final orderId =
        order['id']?.toString() ?? '';

    final amount =
        order['total_amount']?.toString() ?? '0';

    final customerName =
        customer['name']?.toString() ??
            'Customer';

    final addressText =
        address['address']?.toString() ??
            'Address unavailable';

    final landmark =
        address['landmark']?.toString();

    final city =
        address['city']?.toString();

    final pincode =
        address['pincode']?.toString();

    return Container(
      margin:
          const EdgeInsets.only(bottom: 16),

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ======================================================
          // ORDER HEADER
          // ======================================================

          Row(
            children: [

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFE8DC),

                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: const Icon(
                  Icons.receipt_long_outlined,
                  color:
                      Color(0xFFFF6B35),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      customerName,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF2A1D1A),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Order #${_shortOrderId(orderId)}',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF756864),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '₹$amount',
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF2A1D1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ======================================================
          // DELIVERY ADDRESS
          // ======================================================

          const Text(
            'Deliver to',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF756864),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Icon(
                Icons.location_on_outlined,
                size: 22,
                color:
                    Color(0xFFFF6B35),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  _buildAddress(
                    addressText,
                    landmark,
                    city,
                    pincode,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color:
                        Color(0xFF2A1D1A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ======================================================
          // STATUS
          // ======================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color:
                  const Color(0xFFE8F7EC),

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                Icon(
                  Icons.check_circle_outline,
                  size: 17,
                  color: Colors.green,
                ),

                SizedBox(width: 6),

                Text(
                  'Ready for delivery',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // ACCEPT BUTTON
          // ======================================================

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton(
              onPressed: orderId.isEmpty
                  ? null
                  : () => _confirmAccept(
                        orderId,
                      ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFF6B35),

                foregroundColor:
                    Colors.white,

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),

              child: const Text(
                'Accept Order',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRM ACCEPT
  // ============================================================

  Future<void> _confirmAccept(
    String orderId,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Accept Order?',
          ),

          content: const Text(
            'Are you sure you want to accept this delivery?',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFF6B35),
                foregroundColor:
                    Colors.white,
              ),

              child: const Text(
                'Accept',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _acceptOrder(orderId);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _shortOrderId(
    String id,
  ) {
    if (id.length <= 8) {
      return id;
    }

    return id.substring(0, 8);
  }

  String _buildAddress(
    String address,
    String? landmark,
    String? city,
    String? pincode,
  ) {
    final parts = <String>[
      address,
    ];

    if (landmark != null &&
        landmark.isNotEmpty) {
      parts.add(landmark);
    }

    if (city != null &&
        city.isNotEmpty) {
      parts.add(city);
    }

    if (pincode != null &&
        pincode.isNotEmpty) {
      parts.add(pincode);
    }

    return parts.join(', ');
  }
}
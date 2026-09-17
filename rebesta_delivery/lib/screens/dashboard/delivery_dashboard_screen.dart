import 'package:flutter/material.dart';
import '../history/delivery_history_screen.dart';
import '../wallet/delivery_wallet_screen.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/delivery_api_client.dart';
import '../orders/available_orders_screen.dart';
import '../../services/delivery_location_service.dart';
import '../active_delivery/active_delivery_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState
    extends State<DeliveryDashboardScreen> {

  bool _loading = true;
  bool _online = false;

  int _currentOrders = 0;
  int _completedDeliveries = 0;

  List<dynamic> _activeOrders = [];
  bool _activeOrdersLoading = false;

  final DeliveryLocationService _locationService =
    DeliveryLocationService.instance;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    try {
      debugPrint('=================================');
      debugPrint('🚴 DELIVERY DASHBOARD');
      debugPrint(
        'GET: ${ApiConstants.dashboard}',
      );
      debugPrint('=================================');

      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.get(
        ApiConstants.dashboard,
        options: options,
      );

      debugPrint(
        'DASHBOARD STATUS: ${response.statusCode}',
      );

      debugPrint(
        'DASHBOARD RESPONSE: ${response.data}',
      );

      final data = response.data;

      if (data['success'] == true) {
        final dashboard =
            data['dashboard'] ?? {};

        if (!mounted) return;

        setState(() {
          _currentOrders =
              dashboard['currentOrders'] ?? 0;

          _completedDeliveries =
              dashboard['completedDeliveries'] ?? 0;

          _loading = false;
        });

        await _loadActiveOrders();


      } else {
        throw Exception(
          data['message'] ??
              'Failed to load dashboard',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ DASHBOARD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load dashboard',
      );
    }
  }



  // ============================================================
// LOAD ACTIVE ORDERS
// ============================================================

Future<void> _loadActiveOrders() async {
  try {
    _activeOrdersLoading = true;

    if (mounted) {
      setState(() {});
    }

    debugPrint('=================================');
    debugPrint('🚴 ACTIVE DELIVERY ORDERS');
    debugPrint(
      'GET: ${ApiConstants.activeOrders}',
    );
    debugPrint('=================================');

    final options =
        await DeliveryApiClient.authOptions();

    final response =
        await DeliveryApiClient.dio.get(
      ApiConstants.activeOrders,
      options: options,
    );

    debugPrint(
      'ACTIVE ORDERS STATUS: ${response.statusCode}',
    );

    debugPrint(
      'ACTIVE ORDERS RESPONSE: ${response.data}',
    );

    final data = response.data;

    if (data['success'] != true) {
      throw Exception(
        data['message'] ??
            'Failed to load active orders',
      );
    }

    if (!mounted) return;

    setState(() {
      _activeOrders =
          data['orders'] ?? [];

      _activeOrdersLoading = false;
    });
  } catch (e) {
    debugPrint(
      '❌ ACTIVE ORDERS ERROR: $e',
    );

    if (!mounted) return;

    setState(() {
      _activeOrdersLoading = false;
    });
  }
}

  // ============================================================
  // ONLINE / OFFLINE
  // ============================================================

Future<void> _toggleOnline(
  bool value,
) async {
  try {
    final options =
        await DeliveryApiClient.authOptions();

    // ==========================================================
    // UPDATE BACKEND ONLINE STATUS
    // ==========================================================

    final response =
        await DeliveryApiClient.dio.patch(
      ApiConstants.updateStatus,
      data: {
        'isOnline': value,
      },
      options: options,
    );

    debugPrint(
      'STATUS RESPONSE: ${response.data}',
    );

    if (response.data['success'] != true) {
      throw Exception(
        response.data['message'] ??
            'Unable to update delivery status',
      );
    }

    // ==========================================================
    // GO ONLINE
    // ==========================================================

    if (value) {
      try {
        await _locationService.startTracking();
      } catch (e) {
        debugPrint(
          '❌ LOCATION START ERROR: $e',
        );

        // ------------------------------------------------------
        // GPS failed → rollback backend status to offline
        // ------------------------------------------------------

        try {
          await DeliveryApiClient.dio.patch(
            ApiConstants.updateStatus,
            data: {
              'isOnline': false,
            },
            options: options,
          );
        } catch (rollbackError) {
          debugPrint(
            '❌ STATUS ROLLBACK ERROR: $rollbackError',
          );
        }

        if (!mounted) return;

        _showMessage(
          e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
        );

        return;
      }
    }

    // ==========================================================
    // GO OFFLINE
    // ==========================================================

    else {
      await _locationService.stopTracking();
    }

    // ==========================================================
    // UPDATE UI
    // ==========================================================

    if (!mounted) return;

    setState(() {
      _online = value;
    });

    _showMessage(
      value
          ? 'You are now online'
          : 'You are now offline',
    );
  } catch (e) {
    debugPrint(
      '❌ STATUS UPDATE ERROR: $e',
    );

    if (!mounted) return;

    _showMessage(
      'Unable to update status',
    );
  }
}

@override
void dispose() {
  _locationService.stopTracking();
  super.dispose();
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
    backgroundColor: const Color(0xFFFFF8F2),

    appBar: AppBar(
      backgroundColor: const Color(0xFFFFF8F2),
      elevation: 0,

      title: const Text(
        'REBESTA Delivery',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF2A1D1A),
        ),
      ),

      actions: [
        IconButton(
          onPressed: _loading
              ? null
              : _loadDashboard,
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
            onRefresh: _loadDashboard,

            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.all(20),

              children: [

                // =================================================
                // ONLINE / OFFLINE CARD
                // =================================================

                Container(
                  padding:
                      const EdgeInsets.all(20),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                  ),

                  child: Row(
                    children: [

                      Container(
                        width: 52,
                        height: 52,

                        decoration:
                            BoxDecoration(
                          color: _online
                              ? const Color(
                                  0xFFE8F7EC,
                                )
                              : const Color(
                                  0xFFF3EFEC,
                                ),

                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),

                        child: Icon(
                          Icons.delivery_dining,

                          color: _online
                              ? Colors.green
                              : const Color(
                                  0xFF756864,
                                ),

                          size: 28,
                        ),
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            const Text(
                              'Delivery Status',

                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              _online
                                  ? 'You are online'
                                  : 'You are offline',

                              style: TextStyle(
                                color: _online
                                    ? Colors.green
                                    : const Color(
                                        0xFF756864,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Switch(
                        value: _online,
                        onChanged:
                            _toggleOnline,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // STATS
                // =================================================

                Row(
                  children: [

                    Expanded(
                      child: _statCard(
                        icon:
                            Icons.delivery_dining,
                        title:
                            'Current Orders',
                        value:
                            _currentOrders
                                .toString(),
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: _statCard(
                        icon:
                            Icons.check_circle_outline,
                        title:
                            'Completed',
                        value:
                            _completedDeliveries
                                .toString(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                // =================================================
                // ORDERS TITLE
                // =================================================

                const Text(
  'Active Deliveries',
  style: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    color: Color(0xFF2A1D1A),
  ),
),

const SizedBox(height: 12),

if (_activeOrdersLoading)
  const Center(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: CircularProgressIndicator(
        color: Color(0xFFFF6B35),
      ),
    ),
  )
else if (_activeOrders.isEmpty)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.local_shipping_outlined,
          size: 42,
          color: Color(0xFF756864),
        ),

        SizedBox(height: 10),

        Text(
          'No active deliveries',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A1D1A),
          ),
        ),

        SizedBox(height: 4),

        Text(
          'Accepted orders will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF756864),
          ),
        ),
      ],
    ),
  )
else
  ..._activeOrders.map(
    (order) => _activeOrderCard(order),
  ),

const SizedBox(height: 24),

const Text(
  'Orders',
  style: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    color: Color(0xFF2A1D1A),
  ),
),

const SizedBox(height: 12),

                // =================================================
                // AVAILABLE ORDERS
                // =================================================

                InkWell(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),

                  onTap: () async {
                    final completed =
                        await Navigator.push<bool>(
                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                            const AvailableOrdersScreen(),
                      ),
                    );

                    if (!mounted) return;

                    if (completed == true) {
                      await _loadDashboard();
                    }
                  },

                  child: Container(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFF6B35,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),

                    child: const Row(
                      children: [

                        Icon(
                          Icons
                              .local_shipping_outlined,
                          color:
                              Colors.white,
                          size: 30,
                        ),

                        SizedBox(
                          width: 16,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                'Available Orders',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),

                              SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Find orders ready for delivery',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          Icons
                              .arrow_forward_ios,
                          color:
                              Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // DELIVERY HISTORY
                // =================================================

                SizedBox(
                  width:
                      double.infinity,

                  height: 54,

                  child:
                      OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              const DeliveryHistoryScreen(),
                        ),
                      );

                      if (!mounted) return;

                      await _loadDashboard();
                    },

                    icon: const Icon(
                      Icons.history,
                    ),

                    label: const Text(
                      'Delivery History',

                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(
                        0xFFFF6B35,
                      ),

                      side:
                          const BorderSide(
                        color:
                            Color(
                          0xFFFF6B35,
                        ),
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // =================================================
                // WALLET & EARNINGS
                // =================================================

                SizedBox(
                  width:
                      double.infinity,

                  height: 54,

                  child:
                      ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              const DeliveryWalletScreen(),
                        ),
                      );

                      if (!mounted) return;

                      await _loadDashboard();
                    },

                    icon: const Icon(
                      Icons
                          .account_balance_wallet_outlined,
                    ),

                    label: const Text(
                      'Wallet & Earnings',

                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFFF6B35,
                      ),

                      foregroundColor:
                          Colors.white,

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
  );
}


// ============================================================
// ACTIVE ORDER CARD
// ============================================================

Widget _activeOrderCard(
  dynamic order,
) {
  final customer =
      order['customers'] ?? {};

  final restaurant =
      order['restaurant_partners'] ?? {};

  final address =
      order['addresses'] ?? {};

  final orderId =
      order['id']?.toString() ?? '';

  final customerName =
      customer['name']?.toString() ??
          'Customer';

  final restaurantName =
      restaurant['restaurant_name']
          ?.toString() ??
          'Restaurant';

  final addressText =
      address['address']?.toString() ??
          'Address unavailable';

  final city =
      address['city']?.toString();

  final pincode =
      address['pincode']?.toString();

  final status =
      order['order_status']
          ?.toString() ??
          '';

  String statusText;

  switch (status) {
    case 'accepted_for_delivery':
      statusText = 'Accepted for delivery';
      break;

    case 'picked_up':
      statusText = 'Picked up';
      break;

    case 'out_for_delivery':
      statusText = 'Out for delivery';
      break;

    default:
      statusText = status;
  }

  return Container(
    margin: const EdgeInsets.only(
      bottom: 14,
    ),

    padding: const EdgeInsets.all(18),

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
        // HEADER
        // ======================================================

        Row(
          children: [

            Container(
              width: 48,
              height: 48,

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFFFE8DC),

                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),

              child: const Icon(
                Icons.delivery_dining,
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
                    restaurantName,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF2A1D1A),
                    ),
                  ),

                  const SizedBox(height: 3),

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
          ],
        ),

        const SizedBox(height: 16),

        // ======================================================
        // CUSTOMER
        // ======================================================

        Row(
          children: [

            const Icon(
              Icons.person_outline,
              size: 20,
              color:
                  Color(0xFFFF6B35),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                customerName,
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ======================================================
        // ADDRESS
        // ======================================================

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color:
                  Color(0xFFFF6B35),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                _buildActiveAddress(
                  addressText,
                  city,
                  pincode,
                ),
                style:
                    const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color:
                      Color(0xFF756864),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ======================================================
        // STATUS
        // ======================================================

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFE8F7EC),

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child: Text(
            statusText,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color: Colors.green,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ======================================================
        // CONTINUE DELIVERY
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 50,

          child: ElevatedButton(
            onPressed: orderId.isEmpty
                ? null
                : () async {

                    await Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                            ActiveDeliveryScreen(
                          order:
                              Map<String,
                                  dynamic>.from(
                            order,
                          ),
                        ),
                      ),
                    );

                    if (!mounted) return;

                    await _loadDashboard();
                  },

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
              'Continue Delivery',
              style: TextStyle(
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
// ACTIVE ORDER ADDRESS
// ============================================================

// ============================================================
// ACTIVE ORDER ADDRESS
// ============================================================

// ============================================================
// ACTIVE ORDER ADDRESS
// ============================================================

String _buildActiveAddress(
  String address,
  String? city,
  String? pincode,
) {
  final parts = <String>[
    address,
  ];

  if (city != null && city.isNotEmpty) {
    parts.add(city);
  }

  if (pincode != null && pincode.isNotEmpty) {
    parts.add(pincode);
  }

  return parts.join(', ');
}

// ============================================================
// SHORT ORDER ID
// ============================================================

String _shortOrderId(String id) {
  if (id.length <= 8) {
    return id;
  }

  return id.substring(0, 8);
}

// ============================================================
// STAT CARD
// ============================================================
  // ============================================================
  // STAT CARD
  // ============================================================
  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color:
                const Color(0xFFFF6B35),
            size: 28,
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF2A1D1A),
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            title,
            style: const TextStyle(
              color:
                  Color(0xFF756864),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
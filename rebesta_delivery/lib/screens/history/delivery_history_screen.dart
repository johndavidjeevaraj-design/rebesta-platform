import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/delivery_api_client.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() =>
      _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState
    extends State<DeliveryHistoryScreen> {

  bool _loading = true;
  List<dynamic> _deliveries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.get(
        ApiConstants.history,
        options: options,
      );

      debugPrint(
        'HISTORY RESPONSE: ${response.data}',
      );

      final data = response.data;

      if (data['success'] != true) {
        throw Exception(
          data['message'] ??
              'Failed to load history',
        );
      }

      if (!mounted) return;

      setState(() {
        _deliveries =
            data['deliveries'] ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        '❌ HISTORY ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        .showSnackBar(
          const SnackBar(
            content:
                Text('Unable to load history'),
          ),
        );
    }
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFF8F2),
        elevation: 0,
        title: const Text(
          'Delivery History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A1D1A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
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
              onRefresh: _loadHistory,

              child: _deliveries.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 150),
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Color(0xFF756864),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No delivery history',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(16),
                      itemCount:
                          _deliveries.length,
                      itemBuilder:
                          (context, index) {

                        final order =
                            _deliveries[index];

                        final customer =
                            order['customers'];

                        final restaurant =
                            order[
                                'restaurant_partners'];

                        final orderId =
                            order['id']
                                ?.toString() ??
                                '';

                        final customerName =
                            customer is Map
                                ? customer['name']
                                        ?.toString() ??
                                    'Customer'
                                : 'Customer';

                        final restaurantName =
                            restaurant is Map
                                ? restaurant[
                                            'restaurant_name']
                                        ?.toString() ??
                                    'Restaurant'
                                : 'Restaurant';

                        final amount =
                            order['total_amount']
                                    ?.toString() ??
                                '0';

                        return Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          padding:
                              const EdgeInsets.all(18),
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Row(
                            children: [

                              Container(
                                width: 48,
                                height: 48,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFE8F7EC,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                ),
                                child: const Icon(
                                  Icons
                                      .check_circle,
                                  color:
                                      Colors.green,
                                ),
                              ),

                              const SizedBox(
                                width: 14,
                              ),

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
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      restaurantName,
                                      style:
                                          const TextStyle(
                                        color:
                                            Color(
                                          0xFF756864,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      'Order #${_shortId(orderId)}',
                                      style:
                                          const TextStyle(
                                        fontSize: 12,
                                        color:
                                            Color(
                                          0xFF756864,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                '₹$amount',
                                style:
                                    const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
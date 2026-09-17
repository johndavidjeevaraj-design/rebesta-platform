import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/delivery_api_client.dart';

class DeliveryWalletScreen extends StatefulWidget {
  const DeliveryWalletScreen({super.key});

  @override
  State<DeliveryWalletScreen> createState() =>
      _DeliveryWalletScreenState();
}

class _DeliveryWalletScreenState
    extends State<DeliveryWalletScreen> {

  bool _loading = true;

  double _walletBalance = 0;
  double _totalEarnings = 0;
  double _pendingPayout = 0;
  int _completedDeliveries = 0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.get(
        ApiConstants.wallet,
        options: options,
      );

      debugPrint(
        'WALLET RESPONSE: ${response.data}',
      );

      final data = response.data;

      if (data['success'] != true) {
        throw Exception(
          data['message'] ??
              'Failed to load wallet',
        );
      }

      final wallet =
          data['wallet'] ?? {};

      if (!mounted) return;

      setState(() {
        _walletBalance =
            double.tryParse(
              '${wallet['wallet_balance'] ?? 0}',
            ) ??
            0;

        _totalEarnings =
            double.tryParse(
              '${wallet['total_earnings'] ?? 0}',
            ) ??
            0;

        _pendingPayout =
            double.tryParse(
              '${wallet['pending_payout'] ?? 0}',
            ) ??
            0;

        _completedDeliveries =
            int.tryParse(
              '${wallet['completed_deliveries'] ?? 0}',
            ) ??
            0;

        _loading = false;
      });
    } catch (e) {
      debugPrint(
        '❌ WALLET ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Widget _card(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [

          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFE8DC),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFFFF6B35),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF756864),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFF8F2),
        elevation: 0,
        title: const Text(
          'Wallet',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadWallet,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFFF6B35),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadWallet,

              child: ListView(
                padding:
                    const EdgeInsets.all(20),
                children: [

                  Container(
                    padding:
                        const EdgeInsets.all(24),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFF6B35,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [

                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          '₹${_walletBalance.toStringAsFixed(0)}',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 34,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  _card(
                    'Total Earnings',
                    '₹${_totalEarnings.toStringAsFixed(0)}',
                    Icons
                        .account_balance_wallet_outlined,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _card(
                    'Pending Payout',
                    '₹${_pendingPayout.toStringAsFixed(0)}',
                    Icons
                        .payments_outlined,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _card(
                    'Completed Deliveries',
                    '$_completedDeliveries',
                    Icons
                        .check_circle_outline,
                  ),
                ],
              ),
            ),
    );
  }
}
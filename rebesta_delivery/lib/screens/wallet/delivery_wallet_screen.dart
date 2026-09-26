import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/delivery_api_client.dart';

// ============================================================
// WALLET & EARNINGS
// ============================================================
//
// Earnings hub for riders:
//   - Wallet balance + lifetime totals (from /delivery/wallet)
//   - Today / This Week / All Time period tabs with totals
//   - Per-delivery earnings breakdown (from /delivery/earnings)
// ============================================================

class DeliveryWalletScreen extends StatefulWidget {
  const DeliveryWalletScreen({super.key});

  @override
  State<DeliveryWalletScreen> createState() =>
      _DeliveryWalletScreenState();
}

class _DeliveryWalletScreenState
    extends State<DeliveryWalletScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;

  double _walletBalance = 0;
  double _totalEarnings = 0;
  double _pendingPayout = 0;
  int _completedDeliveries = 0;

  List<dynamic> _earnings = [];

  double _todayTotal = 0;
  int _todayCount = 0;
  double _weekTotal = 0;
  int _weekCount = 0;

  // 0 = Today, 1 = This Week, 2 = All Time

  int _selectedPeriod = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ============================================================
  // LOAD WALLET + EARNINGS
  // ============================================================

  Future<void> _loadAll() async {
    try {
      final options =
          await DeliveryApiClient.authOptions();

      final responses = await Future.wait([
        DeliveryApiClient.dio.get(
          ApiConstants.wallet,
          options: options,
        ),
        DeliveryApiClient.dio.get(
          ApiConstants.earnings,
          options: options,
        ),
      ]);

      final walletData = responses[0].data;
      final earningsData = responses[1].data;

      if (walletData['success'] != true) {
        throw Exception(
          walletData['message'] ?? 'Failed to load wallet',
        );
      }

      if (earningsData['success'] != true) {
        throw Exception(
          earningsData['message'] ??
              'Failed to load earnings',
        );
      }

      final wallet = walletData['wallet'] ?? {};

      final summary =
          earningsData['summary'] ?? {};

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

        _earnings = earningsData['earnings'] ?? [];

        _todayTotal =
            (summary['todayTotal'] ?? 0).toDouble();

        _todayCount =
            (summary['todayCount'] ?? 0).toInt();

        _weekTotal =
            (summary['weekTotal'] ?? 0).toDouble();

        _weekCount =
            (summary['weekCount'] ?? 0).toInt();

        _loading = false;
      });
    } catch (e) {
      debugPrint(
        '❌ WALLET + EARNINGS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // PERIOD FILTERING (client-side, Monday-based week)
  // ============================================================

  List<dynamic> get _filteredEarnings {
    if (_selectedPeriod == 2) {
      return _earnings;
    }

    final now = DateTime.now();

    final startOfToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final startOfWeek = startOfToday.subtract(
      Duration(days: (startOfToday.weekday - 1) % 7),
    );

    return _earnings.where((row) {
      final createdAt =
          DateTime.tryParse('${row['created_at']}');

      if (createdAt == null) return false;

      if (_selectedPeriod == 0) {
        return !createdAt.isBefore(startOfToday);
      }

      return !createdAt.isBefore(startOfWeek);
    }).toList();
  }

  double get _periodTotal {
    switch (_selectedPeriod) {
      case 0:
        return _todayTotal;
      case 1:
        return _weekTotal;
      default:
        return _totalEarnings;
    }
  }

  int get _periodCount {
    switch (_selectedPeriod) {
      case 0:
        return _todayCount;
      case 1:
        return _weekCount;
      default:
        return _completedDeliveries;
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case 0:
        return 'Earned Today';
      case 1:
        return 'Earned This Week';
      default:
        return 'Earned All Time';
    }
  }

  // ============================================================
  // DATE FORMATTING (no intl dependency)
  // ============================================================

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(
    String iso,
  ) {
    final dt = DateTime.tryParse(iso);

    if (dt == null) return '';

    final now = DateTime.now();

    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;

    final hour12 = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;

    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    final minute =
        dt.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Today, $hour12:$minute $ampm';
    }

    return '${dt.day} ${_months[dt.month - 1]}, $hour12:$minute $ampm';
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _card(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8DC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6B35),
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
                  style: const TextStyle(
                    color: Color(0xFF756864),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
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
  // PERIOD TABS
  // ============================================================

  Widget _periodTabs() {
    final labels = [
      'Today',
      'This Week',
      'All Time',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _selectedPeriod == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFF6B35)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF756864),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // EARNING ROW
  // ============================================================

  Widget _earningRow(
    Map<String, dynamic> row,
  ) {
    final amount =
        double.tryParse('${row['amount'] ?? 0}') ?? 0;

    final orderId =
        row['order_id']?.toString() ?? '';

    final shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    final status =
        row['status']?.toString() ?? 'pending';

    final isPaid = status == 'paid';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8DC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.currency_rupee,
              color: Color(0xFFFF6B35),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // ---------------------------------------------
          // ORDER + DATE
          // ---------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  shortId.isEmpty
                      ? 'Delivery'
                      : 'Order #$shortId',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A1D1A),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _formatDate('${row['created_at']}'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF756864),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------
          // AMOUNT + STATUS
          // ---------------------------------------------

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2A1D1A),
                ),
              ),

              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFFE8F7EE)
                      : const Color(0xFFFFF3D6),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPaid
                        ? const Color(0xFF1D9E55)
                        : const Color(0xFFB7791F),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    final filtered = _filteredEarnings;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F2),
        elevation: 0,
        title: const Text(
          'Wallet & Earnings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAll,
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
              onRefresh: _loadAll,

              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ==========================================
                  // BALANCE HERO
                  // ==========================================

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '₹${_walletBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '₹${_pendingPayout.toStringAsFixed(0)} pending payout',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // LIFETIME CARDS
                  // ==========================================

                  _card(
                    'Total Earnings',
                    '₹${_totalEarnings.toStringAsFixed(0)}',
                    Icons
                        .account_balance_wallet_outlined,
                  ),

                  const SizedBox(height: 12),

                  _card(
                    'Completed Deliveries',
                    '$_completedDeliveries',
                    Icons.check_circle_outline,
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // EARNINGS BY PERIOD
                  // ==========================================

                  _periodTabs(),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                _periodLabel,
                                style:
                                    const TextStyle(
                                  color: Color(
                                    0xFF756864,
                                  ),
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                '₹${_periodTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets
                              .symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFE8DC,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '$_periodCount deliveries',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
                              color: Color(
                                0xFFFF6B35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==========================================
                  // BREAKDOWN LIST
                  // ==========================================

                  if (filtered.isEmpty)
                    Container(
                      padding:
                          const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons
                                .receipt_long_outlined,
                            size: 36,
                            color: Color(0xFFD8CFCB),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No earnings in this period yet',
                            style: TextStyle(
                              color:
                                  Color(0xFF756864),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((row) {
                      if (row is! Map) {
                        return const SizedBox
                            .shrink();
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _earningRow(
                          Map<String, dynamic>
                              .from(row),
                        ),
                      );
                    }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

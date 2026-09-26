import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/partner_orders_service.dart';
import '../../../models/partner_order.dart';

// ============================================================
// REPORTS - EARNINGS
// ============================================================
//
// Real numbers computed from the partner's orders:
// - Earnings  = PAID orders only (payment_status == 'paid')
// - Awaiting  = orders placed whose payment isn't confirmed yet
//
// Full order value - no commission is deducted (no commission
// system exists yet).
// ============================================================

class ReportsDashboard extends StatefulWidget {
  const ReportsDashboard({super.key});

  @override
  State<ReportsDashboard> createState() =>
      _ReportsDashboardState();
}

class _ReportsDashboardState extends State<ReportsDashboard> {
  final PartnerOrdersService _ordersService =
      PartnerOrdersService();

  bool _loading = true;

  String? _error;

  List<PartnerOrder> _orders = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await _ordersService.getOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('REPORTS LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // EARNINGS MATH
  // ============================================================

  List<PartnerOrder> get _paidOrders => _orders
      .where((o) => o.paymentStatus == 'paid')
      .toList();

  List<PartnerOrder> get _pendingPaymentOrders => _orders
      .where((o) => o.paymentStatus == 'pending')
      .toList();

  double get _totalEarnings => _paidOrders.fold(
        0,
        (sum, o) => sum + o.totalAmount,
      );

  double get _awaitingAmount =>
      _pendingPaymentOrders.fold(
        0,
        (sum, o) => sum + o.totalAmount,
      );

  double get _todayEarnings {
    final today = DateTime.now();

    return _paidOrders
        .where(
          (o) =>
              o.createdAt.year == today.year &&
              o.createdAt.month == today.month &&
              o.createdAt.day == today.day,
        )
        .fold(0, (sum, o) => sum + o.totalAmount);
  }

  double get _weekEarnings {
    final weekAgo = DateTime.now().subtract(
      const Duration(days: 7),
    );

    return _paidOrders
        .where((o) => o.createdAt.isAfter(weekAgo))
        .fold(0, (sum, o) => sum + o.totalAmount);
  }

  double get _avgOrderValue =>
      _paidOrders.isEmpty ? 0 : _totalEarnings / _paidOrders.length;

  String _money(double value) =>
      '\u20B9${value.toStringAsFixed(0)}';

  String _dateLabel(DateTime date) {
    const months = [
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

    return '${date.day} ${months[date.month - 1]}';
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      110,
                    ),
                    children: [
                      // ==========================================
                      // HEADER
                      // ==========================================

                      const Text(
                        'Earnings',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),

                      const SizedBox(height: 18),

                      _earningsHero(),

                      const SizedBox(height: 18),

                      _statGrid(),

                      const SizedBox(height: 26),

                      // ==========================================
                      // TRANSACTIONS
                      // ==========================================

                      const Text(
                        'Transactions',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),

                      const SizedBox(height: 14),

                      ..._transactions(),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // HERO - TOTAL EARNINGS
  // ============================================================

  Widget _earningsHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xffFF5A1F),
            Color(0xffFF7A45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffFF5A1F)
                .withValues(alpha: .30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL EARNINGS',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _money(_totalEarnings),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'from ${_paidOrders.length} paid orders',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT GRID
  // ============================================================

  Widget _statGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statTile(
                icon: Icons.today_rounded,
                title: 'Today',
                value: _money(_todayEarnings),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _statTile(
                icon: Icons.date_range_rounded,
                title: 'Last 7 days',
                value: _money(_weekEarnings),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _statTile(
                icon: Icons.schedule_rounded,
                title: 'Awaiting payment',
                value: _money(_awaitingAmount),
                highlight: _pendingPaymentOrders.isNotEmpty,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _statTile(
                icon: Icons.receipt_rounded,
                title: 'Avg order',
                value: _money(_avgOrderValue),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String title,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: highlight
                    ? Colors.amber
                    : AppColors.primary,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  List<Widget> _transactions() {
    if (_orders.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 46,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No orders yet',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your earnings will show up here',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final sorted = [..._orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recent = sorted.take(30).toList();

    return [
      ...recent.map(_transactionRow),

      if (sorted.length > recent.length)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Showing latest 30 of ${sorted.length} orders',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ),
    ];
  }

  Widget _transactionRow(PartnerOrder order) {
    final paid = order.paymentStatus == 'paid';

    final pending = order.paymentStatus == 'pending';

    final color = paid
        ? Colors.green
        : pending
            ? Colors.amber
            : Colors.grey;

    final label = paid
        ? 'PAID'
        : pending
            ? 'PENDING'
            : order.paymentStatus.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          // DATE

          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel(order.createdAt),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '#${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // AMOUNT

          Text(
            _money(order.totalAmount),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),

          const SizedBox(width: 12),

          // STATUS CHIP

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.grey.shade300,
            ),

            const SizedBox(height: 14),

            Text(
              _error ?? 'Could not load earnings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/services/partner_auth_service.dart';
import '../../../core/services/partner_socket_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/partner_orders_service.dart';
import '../../../models/partner_order.dart';

class OrderDashboard extends StatefulWidget {
  const OrderDashboard({
    super.key,
  });

  @override
  State<OrderDashboard> createState() =>
      _OrderDashboardState();
}

class _OrderDashboardState extends State<OrderDashboard> {
  // ============================================================
  // SERVICE
  // ============================================================
  final PartnerSocketService _socketService =
    PartnerSocketService();

  final PartnerOrdersService _ordersService =
      PartnerOrdersService();

  // ============================================================
  // STATE
  // ============================================================

  List<PartnerOrder> orders = [];

  bool isLoading = true;

  String? errorMessage;

  String selectedFilter = 'All';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadOrders();
    _initializeOrders();
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await _ordersService.getOrders();

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

Future<void> _initializeOrders() async {
  await _loadOrders();

  if (!mounted) return;

  final restaurantPartnerId =
      await PartnerAuthService.getRestaurantPartnerId();

  if (restaurantPartnerId == null ||
      restaurantPartnerId.isEmpty) {
    debugPrint(
      '❌ Restaurant Partner ID missing',
    );
    return;
  }

  _socketService.connect(
    restaurantPartnerId: restaurantPartnerId,
    onNewOrder: () async {
      debugPrint(
        '🔄 New order/status received - reloading orders',
      );

      await _loadOrders();
    },
  );
}
  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadOrders();
  }

  // ============================================================
  // FILTERED ORDERS
  // ============================================================

  List<PartnerOrder> get filteredOrders {
    if (selectedFilter == 'All') {
      return orders;
    }

    return orders.where((order) {
      return order.orderStatus.toLowerCase() ==
          selectedFilter.toLowerCase();
    }).toList();
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

Future<void> _updateStatus(
  PartnerOrder order,
  String status,
) async {
  if (!mounted) return;

  try {
    await _ordersService.updateStatus(
      orderId: order.id,
      status: status,
    );

    if (!mounted) return;

    // Reload orders from backend so the dashboard
    // always uses the database as the source of truth.
    await _loadOrders();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          'Order ${_prettyStatus(status).toLowerCase()} successfully',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

  // ============================================================
// CONFIRM CANCEL ORDER
// ============================================================

Future<void> _confirmCancelOrder(
  PartnerOrder order,
) async {
  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(22),
        ),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this order? '
          'This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
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
              'Keep Order',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight:
                    FontWeight.w600,
              ),
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
                  Colors.red,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
            ),
            child: const Text(
              'Cancel Order',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  await _updateStatus(
    order,
    'cancelled',
  );
}

@override
void dispose() {
  _socketService.disconnect();
  super.dispose();
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,

          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            slivers: [
              // ==================================================
              // HEADER
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    0,
                  ),
                  child: _buildHeader(),
                ),
              ),

              // ==================================================
              // FILTERS
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    12,
                  ),
                  child: _buildFilters(),
                ),
              ),

              // ==================================================
              // LOADING
              // ==================================================

              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )

              // ==================================================
              // ERROR
              // ==================================================

              else if (errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _errorView(),
                )

              // ==================================================
              // EMPTY
              // ==================================================

              else if (filteredOrders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyView(),
                )

              // ==================================================
              // ORDERS
              // ==================================================

              else
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    110,
                  ),

                  sliver: SliverList(
                    delegate:
                        SliverChildBuilderDelegate(
                      (context, index) {
                        final order =
                            filteredOrders[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child:
                              _orderCard(order),
                        );
                      },
                      childCount:
                          filteredOrders.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Orders',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '${orders.length} total orders',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    final filters = [
      'All',
      'Pending',
      'Accepted',
      'Ready',
      'Cancelled',
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,

        itemCount: filters.length,

        separatorBuilder:
            (_, _) =>
                const SizedBox(width: 8),

        itemBuilder: (
          context,
          index,
        ) {
          final filter =
              filters[index];

          final selected =
              selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = filter;
              });
            },

            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              alignment:
                  Alignment.center,

              decoration:
                  BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  30,
                ),

                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : Colors.grey.shade200,
                ),
              ),

              child: Text(
                filter,

                style: TextStyle(
                  fontFamily:
                      'Poppins',
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _orderCard(
    PartnerOrder order,
  ) {
    final customer =
        order.customer;

    final customerName =
        customer?.name ??
            'Customer';

    final mobile =
        customer?.mobile ?? '';

    final shortId =
        order.id.length > 8
            ? order.id
                .substring(0, 8)
                .toUpperCase()
            : order.id.toUpperCase();

    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // TOP
          // ======================================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                    BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.10),

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child: Icon(
                  Icons
                      .receipt_long_rounded,
                  color:
                      AppColors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

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
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      _formatDate(
                        order.createdAt,
                      ),

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

              _statusBadge(
                order.orderStatus,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // CUSTOMER
          // ======================================================

          Container(
            padding:
                const EdgeInsets.all(12),

            decoration:
                BoxDecoration(
              color:
                  AppColors.background,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,

                  decoration:
                      BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: const Icon(
                    Icons
                        .person_outline_rounded,
                    size: 20,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        customerName,

                        maxLines: 1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            const TextStyle(
                          fontFamily:
                              'Poppins',
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      if (mobile
                          .isNotEmpty)
                        Text(
                          mobile,

                          style:
                              TextStyle(
                            fontFamily:
                                'Poppins',
                            fontSize: 10,
                            color:
                                AppColors
                                    .grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // ITEMS HEADER
          // ======================================================

          const Text(
            'Order Items',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // ITEMS
          // ======================================================

          ...order.items.map(
            (item) => _itemRow(item),
          ),

          const SizedBox(height: 6),

          const Divider(
            height: 24,
          ),

          // ======================================================
          // PAYMENT + TOTAL
          // ======================================================

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Payment',
                      style:
                          TextStyle(
                        fontFamily:
                            'Poppins',
                        fontSize: 10,
                        color:
                            AppColors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    _paymentStatus(
                      order.paymentStatus,
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style:
                        TextStyle(
                      fontFamily:
                          'Poppins',
                      fontSize: 10,
                      color:
                          AppColors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    '₹${order.totalAmount.toStringAsFixed(0)}',

                    style:
                        const TextStyle(
                      fontFamily:
                          'Poppins',
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // ACTION
          // ======================================================

          _buildStatusAction(order),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM ROW
  // ============================================================

  Widget _itemRow(
    PartnerOrderItem item,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),

      child: Row(
        children: [
          // Quantity

          Container(
            width: 32,
            height: 32,

            alignment:
                Alignment.center,

            decoration:
                BoxDecoration(
              color:
                  AppColors.background,

              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),

            child: Text(
              '${item.quantity}x',

              style:
                  const TextStyle(
                fontFamily:
                    'Poppins',
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Item name

          Expanded(
            child: Text(
              item.name,

              maxLines: 1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontFamily:
                    'Poppins',
                fontSize: 12,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Price

          Text(
            '₹${item.subtotal.toStringAsFixed(0)}',

            style:
                const TextStyle(
              fontFamily:
                  'Poppins',
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT STATUS
  // ============================================================

  Widget _paymentStatus(
    String status,
  ) {
    final normalized =
        status.toLowerCase();

    Color color;

    if (normalized == 'paid') {
      color = Colors.green;
    } else if (normalized ==
        'failed') {
      color = Colors.red;
    } else if (normalized ==
        'refunded') {
      color = Colors.orange;
    } else {
      color = AppColors.grey;
    }

    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          normalized == 'paid'
              ? Icons
                  .check_circle_rounded
              : Icons
                  .radio_button_unchecked,
          size: 14,
          color: color,
        ),

        const SizedBox(width: 5),

        Text(
          _prettyStatus(status),

          style: TextStyle(
            fontFamily:
                'Poppins',
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS ACTION
  // ============================================================

   

Widget _buildStatusAction(
  PartnerOrder order,
) {
  final status =
      order.orderStatus.toLowerCase();

  // ==========================================================
  // FINAL STATES
  // ==========================================================

  if (status == 'cancelled' ||
      status == 'completed') {
    return _finalStatusMessage(status);
  }

  // ==========================================================
  // PENDING
  // ==========================================================

  if (status == 'pending') {
  return Row(
    children: [
      // CANCEL
      Expanded(
        flex: 1,
        child: SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: () {
              _confirmCancelOrder(order);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(
                color: Colors.red.shade200,
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close_rounded,
                  size: 17,
                ),
                SizedBox(width: 5),
                Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      const SizedBox(width: 10),

      // ACCEPT
      Expanded(
        flex: 2,
        child: SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              _updateStatus(
                order,
                'accepted',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 18,
                ),
                SizedBox(width: 7),
                Text(
                  'Accept Order',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
  // ==========================================================
  // NEXT STATUS
  // ==========================================================

 String? nextStatus;

switch (status) {
  case 'accepted':
    nextStatus = 'ready';
    break;
}

  if (nextStatus == null) {
    return const SizedBox.shrink();
  }

  // ==========================================================
  // NEXT ACTION BUTTON
  // ==========================================================

  return SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton(
      onPressed: () {
        _updateStatus(
          order,
          nextStatus!,
        );
      },
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        elevation: 0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            _actionIcon(nextStatus),
            size: 18,
          ),

          const SizedBox(width: 8),

          Text(
            _actionLabel(nextStatus),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

  // ============================================================
  // FINAL STATUS MESSAGE
  // ============================================================

  Widget _finalStatusMessage(
    String status,
  ) {
    final isCompleted =
        status == 'completed';

    return Container(
      width: double.infinity,
      height: 44,

      alignment:
          Alignment.center,

      decoration:
          BoxDecoration(
        color: isCompleted
            ? Colors.green
                .withValues(alpha: 0.08)
            : Colors.red
                .withValues(alpha: 0.08),

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            isCompleted
                ? Icons
                    .check_circle_rounded
                : Icons
                    .cancel_rounded,

            size: 18,

            color: isCompleted
                ? Colors.green
                : Colors.red,
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            isCompleted
                ? 'Order Completed'
                : 'Order Cancelled',

            style: TextStyle(
              fontFamily:
                  'Poppins',
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color: isCompleted
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION ICON
  // ============================================================

 IconData _actionIcon(String status) {
  switch (status.toLowerCase()) {
    case 'ready':
      return Icons.inventory_2_rounded;

    default:
      return Icons.arrow_forward_rounded;
  }
}
  // ============================================================
  // ACTION LABEL
  // ============================================================

  String _actionLabel(String status) {
  switch (status.toLowerCase()) {
    case 'ready':
      return 'Mark Ready';

    default:
      return 'Update Order';
  }
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
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(alpha: 0.10),

        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),

      child: Text(
        _prettyStatus(status)
            .toUpperCase(),

        style: TextStyle(
          fontFamily:
              'Poppins',
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
  // PRETTY STATUS
  // ============================================================

  String _prettyStatus(
    String status,
  ) {
    if (status.isEmpty) {
      return 'Pending';
    }

    return status[0].toUpperCase() +
        status.substring(1)
            .toLowerCase();
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final local =
        date.toLocal();

    final hour =
        local.hour % 12 == 0
            ? 12
            : local.hour % 12;

    final minute =
        local.minute
            .toString()
            .padLeft(2, '0');

    final period =
        local.hour >= 12
            ? 'PM'
            : 'AM';

    return '${local.day}/${local.month}/${local.year} '
        '$hour:$minute $period';
  }

  // ============================================================
  // EMPTY VIEW
  // ============================================================

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Container(
              width: 80,
              height: 80,

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),

              child: Icon(
                Icons
                    .receipt_long_outlined,
                size: 42,
                color:
                    Colors.grey.shade400,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'No orders found',

              style: TextStyle(
                fontFamily:
                    'Poppins',
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              selectedFilter == 'All'
                  ? 'New orders will appear here.'
                  : 'No $selectedFilter orders right now.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontFamily:
                    'Poppins',
                fontSize: 12,
                color:
                    AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
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
              Icons
                  .cloud_off_rounded,
              size: 55,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'Could not load orders',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontFamily:
                    'Poppins',
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              errorMessage ??
                  'Something went wrong.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontFamily:
                    'Poppins',
                fontSize: 12,
                color:
                    AppColors.grey,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  _loadOrders,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,

                foregroundColor:
                    Colors.white,

                elevation: 0,

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
                  fontFamily:
                      'Poppins',
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
import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/partner_auth_service.dart';
import '../../../core/services/partner_orders_service.dart';
import '../../../core/services/partner_restaurant_service.dart';
import '../../../models/partner_order.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
  });

  @override
  State<HomeDashboard> createState() =>
      HomeDashboardState();
}

class HomeDashboardState extends State<HomeDashboard> {
  // ============================================================
  // SERVICES
  // ============================================================

  final PartnerOrdersService _ordersService =
      PartnerOrdersService();


  Future<void> refreshOrders() async {
    await _loadDashboard();
  }

  Future<void> _refresh() async {
    await _loadDashboard();
  }

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;

  String? errorMessage;

  List<PartnerOrder> orders = [];

  String partnerName = 'Partner';
  String restaurantName = 'Restaurant';

  // Real store status (from GET /restaurants/me)

  bool isStoreOpen = true;

  bool isStatusToggling = false;

  // Store hours (null = no schedule, manual toggle only)

  String? openingTime;

  String? closingTime;

  List<int> closedDays = [];

  bool isHoursSaving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboard();
    _loadStoreStatus();
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      // Load logged-in partner information.
      await _loadPartnerInfo();

      // Load orders through the SERVICE.
      final result = await _ordersService.getOrders();

      debugPrint('========================================');
debugPrint('🏠 PARTNER DASHBOARD ORDERS');
debugPrint('Order count: ${result.length}');
debugPrint('Orders: $result');
debugPrint('========================================');

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

  // ============================================================
  // LOAD PARTNER INFO
  // ============================================================

 Future<void> _loadPartnerInfo() async {
  final profile =
      await PartnerAuthService.getPartnerProfile();

  if (!mounted) return;

  if (profile != null) {
    final name =
        profile['name']?.toString();

    final restaurant =
        profile['restaurantName']?.toString();

    setState(() {
      if (name != null &&
          name.trim().isNotEmpty) {
        partnerName = name.trim();
      }

      if (restaurant != null &&
          restaurant.trim().isNotEmpty) {
        restaurantName = restaurant.trim();
      }
    });

    return;
  }

  // Fallback to locally stored data.
  final savedName =
      await PartnerAuthService.getPartnerName();

  final savedRestaurant =
      await PartnerAuthService.getRestaurantName();

  if (!mounted) return;

  setState(() {
    if (savedName != null &&
        savedName.trim().isNotEmpty) {
      partnerName = savedName.trim();
    }

    if (savedRestaurant != null &&
        savedRestaurant.trim().isNotEmpty) {
      restaurantName =
          savedRestaurant.trim();
    }
  });
}

  // ============================================================
  // STORE STATUS - load + toggle (real, from the API)
  // ============================================================

  Future<void> _loadStoreStatus() async {
    try {
      final restaurant =
          await PartnerRestaurantService
              .getMyRestaurant();

      if (!mounted) return;

      setState(() {
        isStoreOpen =
            restaurant['isOpen'] == true;

        final rawOpening =
            restaurant['openingTime'];

        final rawClosing =
            restaurant['closingTime'];

        openingTime =
            rawOpening is String ? rawOpening : null;

        closingTime =
            rawClosing is String ? rawClosing : null;

        final rawDays =
            restaurant['closedDays'];

        closedDays = rawDays is List
            ? rawDays.whereType<int>().toList()
            : [];
      });
    } catch (e) {
      debugPrint(
        'STORE STATUS LOAD ERROR: $e',
      );
    }
  }

  Future<void> _toggleStoreStatus() async {
    if (isStatusToggling) return;

    final previous = isStoreOpen;

    final next = !previous;

    // Flip instantly, revert if the server refuses

    setState(() {
      isStoreOpen = next;
      isStatusToggling = true;
    });

    try {
      await PartnerRestaurantService
          .updateStoreStatus(next);
    } catch (e) {
      debugPrint('STORE STATUS ERROR: $e');

      if (!mounted) return;

      setState(() {
        isStoreOpen = previous;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not update store status'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isStatusToggling = false;
        });
      }
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  // ============================================================
  // TODAY ORDERS
  // ============================================================

  List<PartnerOrder> get todayOrders {
    final now = DateTime.now();

    return orders.where((order) {
      final date = order.createdAt.toLocal();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  // ============================================================
  // TODAY ORDER COUNT
  // ============================================================

  int get todayOrderCount {
    return todayOrders.length;
  }

  // ============================================================
  // TODAY REVENUE
  // ============================================================

  double get todayRevenue {
    double total = 0;

    for (final order in todayOrders) {
      final status =
          order.orderStatus.toLowerCase();

      // Cancelled orders should not count as revenue.
      if (status == 'cancelled') {
        continue;
      }

      total += order.totalAmount;
    }

    return total;
  }

  // ============================================================
  // STATUS COUNTS
  // ============================================================

  int get pendingOrders {
    return orders.where(
      (order) =>
          order.orderStatus.toLowerCase() ==
          'pending',
    ).length;
  }

  int get preparingOrders {
    return orders.where(
      (order) =>
          order.orderStatus.toLowerCase() ==
          'preparing',
    ).length;
  }

  int get completedOrders {
    return orders.where(
      (order) =>
          order.orderStatus.toLowerCase() ==
          'completed',
    ).length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _loadingView();
    }

    if (errorMessage != null) {
      return _errorView();
    }

    return RefreshIndicator(
      onRefresh: _refresh,

      color: AppColors.primary,

      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          110,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(),

            const SizedBox(height: 24),

            // ==================================================
            // RESTAURANT STATUS
            // ==================================================

            _buildRestaurantStatus(),

            const SizedBox(height: 16),

            // ==================================================
            // STORE HOURS
            // ==================================================

            _buildStoreHours(),

            const SizedBox(height: 26),

            // ==================================================
            // TODAY
            // ==================================================

            const Text(
              'Today',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon:
                        Icons.receipt_long_rounded,
                    title: 'Orders',
                    value:
                        todayOrderCount.toString(),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _statCard(
                    icon:
                        Icons.currency_rupee_rounded,
                    title: 'Revenue',
                    value:
                        '₹${todayRevenue.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==================================================
            // ORDER STATUS
            // ==================================================

            const Text(
              'Order Status',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _statusCard(
                    icon:
                        Icons.schedule_rounded,
                    title: 'Pending',
                    value: pendingOrders,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _statusCard(
                    icon:
                        Icons.local_fire_department_rounded,
                    title: 'Preparing',
                    value: preparingOrders,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _statusCard(
                    icon:
                        Icons.check_circle_rounded,
                    title: 'Completed',
                    value: completedOrders,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==================================================
            // RECENT ORDERS
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),

                if (orders.isNotEmpty)
                  Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.primary,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ==================================================
            // ORDERS
            // ==================================================

            if (orders.isEmpty)
              _emptyOrders()
            else
              ...orders
                  .take(5)
                  .map(_orderCard),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'Good ${_greeting()} 👋',

                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 3),

               Text(
  restaurantName,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
  ),
),
            ],
          ),
        ),

        Container(
          width: 52,
          height: 52,

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(17),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.04,
                ),

                blurRadius: 12,

                offset:
                    const Offset(0, 4),
              ),
            ],
          ),

          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.black,
            size: 25,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Morning';
    }

    if (hour < 17) {
      return 'Afternoon';
    }

    return 'Evening';
  }

  // ============================================================
  // RESTAURANT STATUS
  // ============================================================

  Widget _buildRestaurantStatus() {
    // Real status - tap the card to open / close the store

    final statusColor =
        isStoreOpen ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: _toggleStoreStatus,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),

        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,

              decoration: BoxDecoration(
                color: statusColor.withValues(
                  alpha: 0.10,
                ),

                borderRadius:
                    BorderRadius.circular(17),
              ),

              child: isStatusToggling
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      color: statusColor,
                      size: 27,
                    ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    isStoreOpen
                        ? 'Your restaurant is accepting orders'
                        : 'Closed - tap to start accepting orders',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),

              decoration: BoxDecoration(
                color: statusColor.withValues(
                  alpha: 0.10,
                ),

                borderRadius:
                    BorderRadius.circular(30),
              ),

              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: statusColor,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    isStoreOpen
                        ? 'ONLINE'
                        : 'OFFLINE',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STORE HOURS CARD
  // ============================================================

  Widget _buildStoreHours() {
    final hasSchedule =
        openingTime != null && closingTime != null;

    String subtitle;

    if (hasSchedule) {
      final days = closedDays.isEmpty
          ? 'Open all week'
          : 'Closed ${_closedDaysLabel()}';

      subtitle =
          '${_formatDisplay(openingTime!)} - ${_formatDisplay(closingTime!)} - $days';
    } else {
      subtitle =
          'No schedule set - manual toggle only';
    }

    return GestureDetector(
      onTap: _showHoursEditor,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),

        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,

              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.10,
                ),

                borderRadius:
                    BorderRadius.circular(17),
              ),

              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store Hours',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STORE HOURS EDITOR (bottom sheet)
  // ============================================================

  Future<void> _showHoursEditor() async {
    var opening = _parseTime(openingTime);
    var closing = _parseTime(closingTime);
    var days = List<int>.from(closedDays);
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 +
                    MediaQuery.of(sheetContext)
                        .viewInsets
                        .bottom,
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store Hours',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Customers see these hours on your restaurant page.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _hoursTimeRow(
                    label: 'Opens',
                    time: opening,
                    onTap: () async {
                      final picked =
                          await showTimePicker(
                        context: sheetContext,
                        initialTime: opening ??
                            const TimeOfDay(
                              hour: 10,
                              minute: 0,
                            ),
                      );

                      if (picked != null) {
                        setSheetState(() {
                          opening = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  _hoursTimeRow(
                    label: 'Closes',
                    time: closing,
                    onTap: () async {
                      final picked =
                          await showTimePicker(
                        context: sheetContext,
                        initialTime: closing ??
                            const TimeOfDay(
                              hour: 22,
                              minute: 0,
                            ),
                      );

                      if (picked != null) {
                        setSheetState(() {
                          closing = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Closed days',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        List.generate(7, (i) {
                      final selected =
                          days.contains(i);

                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            if (selected) {
                              days.remove(i);
                            } else {
                              days.add(i);
                            }
                          });
                        },

                        child: Container(
                          width: 42,
                          height: 42,
                          alignment:
                              Alignment.center,
                          decoration:
                              BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors
                                    .grey.shade100,
                            borderRadius:
                                BorderRadius
                                    .circular(13),
                          ),
                          child: Text(
                            _dayLetters[i],
                            style: TextStyle(
                              fontFamily:
                                  'Poppins',
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final onlyOne =
                                  (opening == null) !=
                                      (closing ==
                                          null);

                              if (onlyOne) {
                                _hoursError(
                                    'Set both opening and closing time');
                                return;
                              }

                              final invalidRange =
                                  opening !=
                                          null &&
                                      closing !=
                                          null &&
                                      (closing!.hour <
                                              opening!
                                                  .hour ||
                                          (closing!.hour ==
                                                  opening!
                                                      .hour &&
                                              closing!
                                                      .minute <=
                                                  opening!
                                                      .minute));

                              if (invalidRange) {
                                _hoursError(
                                    'Closing time must be after opening time');
                                return;
                              }

                              setSheetState(() {
                                isSaving = true;
                              });

                              try {
                                await PartnerRestaurantService
                                    .updateStoreHours(
                                  openingTime: opening ==
                                          null
                                      ? null
                                      : _formatTimeOfDay(
                                          opening!),
                                  closingTime:
                                      closing == null
                                          ? null
                                          : _formatTimeOfDay(
                                              closing!),
                                  closedDays: days,
                                );

                                if (!mounted) {
                                  return;
                                }

                                setState(() {
                                  openingTime = opening ==
                                          null
                                      ? null
                                      : _formatTimeOfDay(
                                          opening!);
                                  closingTime =
                                      closing == null
                                          ? null
                                          : _formatTimeOfDay(
                                              closing!);
                                  closedDays =
                                      List<int>.from(
                                          days);
                                });

                                if (sheetContext
                                    .mounted) {
                                  Navigator.of(
                                          sheetContext)
                                      .pop();
                                }

                                if (!mounted) {
                                  return;
                                }

                                ScaffoldMessenger
                                        .of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Store hours updated'),
                                  ),
                                );
                              } catch (e) {
                                debugPrint(
                                    'HOURS SAVE ERROR: $e');

                                setSheetState(() {
                                  isSaving = false;
                                });

                                if (!mounted) {
                                  return;
                                }

                                _hoursError(
                                    'Could not save store hours');
                              }
                            },

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(16),
                        ),
                      ),

                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Hours',
                              style: TextStyle(
                                fontFamily:
                                    'Poppins',
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // HOURS HELPERS
  // ============================================================

  static const List<String> _dayLetters = [
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  static const List<String> _dayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  void _hoursError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;

    final parts = value.split(':');

    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatTimeOfDayDisplay(TimeOfDay t) {
    final hour12 =
        t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;

    final minute =
        t.minute.toString().padLeft(2, '0');

    final period =
        t.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour12:$minute $period';
  }

  String _formatDisplay(String value) {
    final t = _parseTime(value);

    return t == null
        ? value
        : _formatTimeOfDayDisplay(t);
  }

  String _closedDaysLabel() {
    final names = closedDays
        .where((d) => d >= 0 && d < 7)
        .map((d) => _dayNames[d])
        .toList()
      ..sort();

    return names.join(', ');
  }

  Widget _hoursTimeRow({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),

        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 20,
              color: AppColors.primary,
            ),

            const SizedBox(width: 12),

            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Text(
              time == null
                  ? 'Not set'
                  : _formatTimeOfDayDisplay(time),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: time == null
                    ? Colors.grey
                    : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 166,

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.10),

              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              color: AppColors.primary,
              size: 25,
            ),
          ),

          const Spacer(),

          Text(
            value,

            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 25,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _statusCard({
    required IconData icon,
    required String title,
    required int value,
  }) {
    return Container(
      height: 120,

      padding:
          const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),

          const SizedBox(height: 7),

          Text(
            value.toString(),

            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _orderCard(
    PartnerOrder order,
  ) {
    final orderId = order.id;

    final shortId =
        orderId.length > 8
            ? orderId
                .substring(0, 8)
                .toUpperCase()
            : orderId.toUpperCase();

    final customerName =
        order.customer?.name ??
            'Customer';

    final itemCount =
        order.items.length;

    final itemText =
        itemCount == 1
            ? '1 item'
            : '$itemCount items';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          // ======================================================
          // ORDER ICON
          // ======================================================

          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.10),

              borderRadius:
                  BorderRadius.circular(15),
            ),

            child: Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 13),

          // ======================================================
          // ORDER INFORMATION
          // ======================================================

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
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  customerName,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    fontFamily:
                        'Poppins',
                    fontSize: 11,
                    color:
                        AppColors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  itemText,

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

          // ======================================================
          // AMOUNT + STATUS
          // ======================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',

                style:
                    const TextStyle(
                  fontFamily:
                      'Poppins',
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 5),

              _statusBadge(
                order.orderStatus,
              ),
            ],
          ),
        ],
      ),
    );
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
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.10),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(
          fontFamily: 'Poppins',
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
  // EMPTY ORDERS
  // ============================================================

  Widget _emptyOrders() {
    return Container(
      width: double.infinity,

      height: 220,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 55,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 15),

          const Text(
            'No orders yet',

            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'New orders will appear here.',

            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _loadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // ============================================================
  // ERROR
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
              Icons.cloud_off_rounded,
              size: 55,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              'Could not load dashboard',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage ??
                  'Something went wrong.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  _loadDashboard,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,

                foregroundColor:
                    Colors.white,

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
                  fontFamily: 'Poppins',
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
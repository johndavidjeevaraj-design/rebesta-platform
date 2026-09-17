import 'package:flutter/material.dart';
import '../../core/services/partner_fcm_service.dart';
import '../../core/services/partner_orders_service.dart';
import '../../core/constants/colors.dart';
import '../../core/services/partner_auth_service.dart';
import 'pages/offers_dashboard.dart';
import '../login/login_screen.dart';
import 'pages/home_dashboard.dart';
import 'pages/order_dashboard.dart';
import 'pages/menu_dashboard.dart';
import 'pages/reports_dashboard.dart';
import 'dart:async';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  String? partnerName;
  String? restaurantPartnerId;

  final homeDashboardKey = GlobalKey<HomeDashboardState>();

  late final List<Widget> pages =  [
    HomeDashboard(key: homeDashboardKey),
    const OrderDashboard(),
    const MenuDashboard(),
    const OffersDashboard(),
    const ReportsDashboard(),
  ];

  @override
  void initState() {
    super.initState();

    _loadPartnerSession();

    PartnerFcmService.initialize(
      onOrder: _onNewOrder,
    );
  }


  Future<void> _loadPartnerSession() async {
  final name =
      await PartnerAuthService.getPartnerName();

  final restaurantId =
      await PartnerAuthService.getRestaurantPartnerId();

  if (!mounted) return;

  setState(() {
    partnerName = name;
    restaurantPartnerId = restaurantId;
  });

  debugPrint('================================');
  debugPrint('PARTNER DASHBOARD SESSION');
  debugPrint('Partner: $name');
  debugPrint('Restaurant Partner ID: $restaurantId');
  debugPrint('================================');
}

Future<void> _onNewOrder(
  Map<String, dynamic> data,
) async {
  debugPrint('================================');
  debugPrint('🚨 NEW PARTNER ORDER RECEIVED');
  debugPrint('Data: $data');
  debugPrint('================================');

  // Immediately refresh dashboard data.
  await homeDashboardKey.currentState?.refreshOrders();

  // Show popup.
  if (!mounted) return;

  await _showNewOrderPopup(data);
}

Future<void> _showNewOrderPopup(
  Map<String, dynamic> data,
) async {
  final orderId =
      data['orderId']?.toString() ?? '';

  if (orderId.isEmpty) {
    return;
  }

  final shortId =
      orderId.length > 8
          ? orderId.substring(0, 8).toUpperCase()
          : orderId.toUpperCase();

  final amount =
      data['amount']?.toString() ??
          data['totalAmount']?.toString() ??
          '0';

  final itemCount =
      data['itemCount']?.toString() ??
          data['item_count']?.toString() ??
          '1';

  final itemName =
      data['itemName']?.toString() ??
          data['item_name']?.toString() ??
          'Order item';

  int remainingSeconds = 300;

  Timer? countdownTimer;

  bool actionTaken = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          context,
          setState,
        ) {
          countdownTimer ??=
              Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              if (!context.mounted) {
                timer.cancel();
                return;
              }

              if (remainingSeconds <= 0) {
                timer.cancel();

                if (!actionTaken) {
                  actionTaken = true;

                  PartnerFcmService
                      .stopOrderAlert(
                    orderId,
                  );

                  Navigator.of(
                    dialogContext,
                  ).pop();
                }

                return;
              }

              setState(() {
                remainingSeconds--;
              });
            },
          );

          final minutes =
              remainingSeconds ~/ 60;

          final seconds =
              remainingSeconds % 60;

          final timeText =
              '${minutes.toString().padLeft(2, '0')}:'
              '${seconds.toString().padLeft(2, '0')}';

          return PopScope(
            canPop: false,
            child: Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  28,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    // ========================================
                    // HEADER
                    // ========================================

                    Container(
                      width: 64,
                      height: 64,
                      decoration:
                          BoxDecoration(
                        color: AppColors.primary
                            .withValues(
                          alpha: 0.10,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        Icons
                            .notifications_active_rounded,
                        color:
                            AppColors.primary,
                        size: 34,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'NEW ORDER',
                      style: TextStyle(
                        fontFamily:
                            'Poppins',
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ========================================
                    // ORDER ID
                    // ========================================

                    Text(
                      'Order #$shortId',
                      style:
                          const TextStyle(
                        fontFamily:
                            'Poppins',
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ========================================
                    // AMOUNT
                    // ========================================

                    Text(
                      '₹$amount',
                      style:
                          const TextStyle(
                        fontFamily:
                            'Poppins',
                        fontSize: 30,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '$itemCount item'
                      '${itemCount == '1' ? '' : 's'}',
                      style:
                          TextStyle(
                        fontFamily:
                            'Poppins',
                        fontSize: 13,
                        color:
                            AppColors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ========================================
                    // ITEM
                    // ========================================

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade50,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .restaurant_menu_rounded,
                            color:
                                AppColors.primary,
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Text(
                              '$itemName × $itemCount',
                              style:
                                  const TextStyle(
                                fontFamily:
                                    'Poppins',
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ========================================
                    // COUNTDOWN
                    // ========================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Icon(
                          Icons
                              .timer_outlined,
                          size: 20,
                        ),

                        const SizedBox(
                          width: 7,
                        ),

                        Text(
                          '$timeText remaining',
                          style:
                              const TextStyle(
                            fontFamily:
                                'Poppins',
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ========================================
                    // ACTIONS
                    // ========================================

                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed:
                                actionTaken
                                    ? null
                                    : () async {
                                        actionTaken =
                                            true;

                                        countdownTimer
                                            ?.cancel();

                                        await PartnerFcmService
                                            .stopOrderAlert(
                                          orderId,
                                        );

                                        if (!context
                                            .mounted) {
                                          return;
                                        }

                                        Navigator.of(
                                          dialogContext,
                                        ).pop();

                                        await _updateOrderStatus(
                                          orderId,
                                          'cancelled',
                                        );
                                      },
                            style:
                                OutlinedButton.styleFrom(
                              minimumSize:
                                  const Size(
                                double.infinity,
                                54,
                              ),
                              side:
                                  const BorderSide(
                                color:
                                    Colors.red,
                              ),
                              foregroundColor:
                                  Colors.red,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'DECLINE',
                              style:
                                  TextStyle(
                                fontFamily:
                                    'Poppins',
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child:
                              ElevatedButton(
                            onPressed:
                                actionTaken
                                    ? null
                                    : () async {
                                        actionTaken =
                                            true;

                                        countdownTimer
                                            ?.cancel();

                                        await PartnerFcmService
                                            .stopOrderAlert(
                                          orderId,
                                        );

                                        if (!context
                                            .mounted) {
                                          return;
                                        }

                                        Navigator.of(
                                          dialogContext,
                                        ).pop();

                                        await _updateOrderStatus(
                                          orderId,
                                          'accepted',
                                        );
                                      },
                            style:
                                ElevatedButton.styleFrom(
                              minimumSize:
                                  const Size(
                                double.infinity,
                                54,
                              ),
                              backgroundColor:
                                  AppColors.primary,
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
                            child:
                                const Text(
                              'ACCEPT',
                              style:
                                  TextStyle(
                                fontFamily:
                                    'Poppins',
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  countdownTimer?.cancel();

  await PartnerFcmService.stopOrderAlert(
    orderId,
  );
}


Future<void> _updateOrderStatus(
  String orderId,
  String status,
) async {
  try {
    debugPrint('================================');
    debugPrint('🚨 NEW ORDER ACTION');
    debugPrint('Order: $orderId');
    debugPrint('Status: $status');
    debugPrint('================================');

    final service =
        PartnerOrdersService();

    await service.updateStatus(
      orderId: orderId,
      status: status,
    );

    debugPrint(
      '✅ ORDER STATUS UPDATED',
    );

    // Refresh dashboard immediately.
    await homeDashboardKey.currentState?.refreshOrders();

    // Also refresh Orders page if needed later.
    setState(() {});
  } catch (e) {
    debugPrint(
      '❌ ORDER STATUS UPDATE ERROR: $e',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Could not update order: $e',
        ),
      ),
    );
  }
}

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout from your partner account?',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await PartnerAuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _openProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner Account',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Manage your account',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _profileAction(
                icon: Icons.person_outline,
                title: 'Partner Profile',
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              _profileAction(
                icon: Icons.storefront_outlined,
                title: 'Restaurant Settings',
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              _profileAction(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Divider(height: 20),

              _profileAction(
                icon: Icons.logout_rounded,
                title: 'Logout',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.black;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: itemColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: itemColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: itemColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // BODY
      // ========================================================

      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),

        child: SafeArea(
          top: false,

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),

            child: BottomNavigationBar(
              currentIndex: currentIndex,

              backgroundColor: Colors.white,

              elevation: 0,

              type: BottomNavigationBarType.fixed,

              selectedItemColor:
                  AppColors.primary,

              unselectedItemColor:
                  Colors.grey.shade500,

              selectedFontSize: 12,

              unselectedFontSize: 11,

              selectedLabelStyle:
                  const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),

              unselectedLabelStyle:
                  const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),

              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },

              items: const [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home_outlined,
                  ),
                  activeIcon: Icon(
                    Icons.home_rounded,
                  ),
                  label: 'Home',
                ),

                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.receipt_long_outlined,
                  ),
                  activeIcon: Icon(
                    Icons.receipt_long_rounded,
                  ),
                  label: 'Orders',
                ),

                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.restaurant_menu_outlined,
                  ),
                  activeIcon: Icon(
                    Icons.restaurant_menu_rounded,
                  ),
                  label: 'Menu',
                ),

                BottomNavigationBarItem(
  icon: Icon(Icons.local_offer_outlined),
  activeIcon: Icon(Icons.local_offer_rounded),
  label: 'Offers',
),

                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.bar_chart_outlined,
                  ),
                  activeIcon: Icon(
                    Icons.bar_chart_rounded,
                  ),
                  label: 'Reports',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
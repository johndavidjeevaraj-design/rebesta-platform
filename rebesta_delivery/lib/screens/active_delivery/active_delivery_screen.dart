import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/delivery_api_client.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const ActiveDeliveryScreen({
    super.key,
    required this.order,
  });

  @override
  State<ActiveDeliveryScreen> createState() =>
      _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState
    extends State<ActiveDeliveryScreen> {

  late Map<String, dynamic> _order;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _order = Map<String, dynamic>.from(
      widget.order,
    );

    debugPrint(
      '=================================',
    );
    debugPrint(
      '🚴 ACTIVE DELIVERY SCREEN',
    );
    debugPrint(
      'ORDER: $_order',
    );
    debugPrint(
      'STATUS: $_status',
    );
    debugPrint(
      '=================================',
    );
  }

  // ============================================================
  // ORDER ID
  // ============================================================

  String get _orderId {
    return _order['id']?.toString() ?? '';
  }

  // ============================================================
  // STATUS
  // ============================================================

  String get _status {
    return _order['order_status']?.toString() ?? '';
  }

  // ============================================================
  // CUSTOMER
  // ============================================================

  String get _customerName {
    final customer = _order['customers'];

    if (customer is Map) {
      return customer['name']?.toString() ?? 'Customer';
    }

    return 'Customer';
  }

  // ============================================================
  // AMOUNT
  // ============================================================

  String get _amount {
    return _order['total_amount']?.toString() ?? '0';
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  String get _address {
    final address = _order['addresses'];

    if (address is! Map) {
      return 'Address unavailable';
    }

    final parts = <String>[];

    final value = address['address']?.toString();
    final landmark = address['landmark']?.toString();
    final city = address['city']?.toString();
    final state = address['state']?.toString();
    final pincode = address['pincode']?.toString();

    if (value != null && value.isNotEmpty) {
      parts.add(value);
    }

    if (landmark != null && landmark.isNotEmpty) {
      parts.add(landmark);
    }

    if (city != null && city.isNotEmpty) {
      parts.add(city);
    }

    if (state != null && state.isNotEmpty) {
      parts.add(state);
    }

    if (pincode != null && pincode.isNotEmpty) {
      parts.add(pincode);
    }

    if (parts.isEmpty) {
      return 'Address unavailable';
    }

    return parts.join(', ');
  }

  // ============================================================
  // REACHED PICKUP
  // ============================================================

  Future<void> _reachedPickup() async {
    if (_orderId.isEmpty) {
      _showMessage('Invalid order');
      return;
    }

    await _runAction(
      title: 'Marking pickup location...',
      endpoint: ApiConstants.reachedPickup(
        _orderId,
      ),
      action: 'REACHED PICKUP',
    );
  }

  // ============================================================
  // PICK UP
  // ============================================================

  Future<void> _pickUp() async {
    if (_orderId.isEmpty) {
      _showMessage('Invalid order');
      return;
    }

    await _runAction(
      title: 'Picking up order...',
      endpoint: ApiConstants.pickUpOrder(
        _orderId,
      ),
      action: 'PICK UP',
    );
  }

  // ============================================================
  // OUT FOR DELIVERY
  // ============================================================

  Future<void> _outForDelivery() async {
    if (_orderId.isEmpty) {
      _showMessage('Invalid order');
      return;
    }

    await _runAction(
      title: 'Starting delivery...',
      endpoint: ApiConstants.outForDelivery(
        _orderId,
      ),
      action: 'OUT FOR DELIVERY',
    );
  }

  // ============================================================
  // REACHED CUSTOMER
  // ============================================================

  Future<void> _reachedCustomer() async {
    if (_orderId.isEmpty) {
      _showMessage('Invalid order');
      return;
    }

    await _runAction(
      title: 'Marking customer location...',
      endpoint: ApiConstants.reachedCustomer(
        _orderId,
      ),
      action: 'REACHED CUSTOMER',
    );
  }

  // ============================================================
  // COMPLETE DELIVERY
  //
  // Backend decides whether OTP is required.
  // ============================================================

  Future<void> _completeDelivery() async {
    if (_orderId.isEmpty) {
      _showMessage('Invalid order');
      return;
    }

    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      debugPrint(
        '=================================',
      );
      debugPrint(
        '🚴 COMPLETE DELIVERY',
      );
      debugPrint(
        'ORDER ID: $_orderId',
      );
      debugPrint(
        'CURRENT STATUS: $_status',
      );
      debugPrint(
        'PATCH: ${ApiConstants.completeOrder(_orderId)}',
      );
      debugPrint(
        '=================================',
      );

      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.patch(
        ApiConstants.completeOrder(
          _orderId,
        ),
        options: options,
      );

      debugPrint(
        'COMPLETE DELIVERY STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'COMPLETE DELIVERY RESPONSE: '
        '${response.data}',
      );

      final data = response.data;

      if (data is! Map ||
          data['success'] != true) {

        final message = data is Map
            ? data['message']?.toString() ??
                'Unable to complete delivery'
            : 'Unable to complete delivery';

        // --------------------------------------------------------
        // OTP REQUIRED
        // --------------------------------------------------------

        if (message
            .toLowerCase()
            .contains(
              'otp verification is required',
            )) {

          if (mounted) {
            setState(() {
              _loading = false;
            });
          }

          await _showOtpDialog();

          return;
        }

        throw Exception(message);
      }

      // ----------------------------------------------------------
      // UPDATE LOCAL ORDER
      // ----------------------------------------------------------

      final updatedOrder = data['order'];

      if (updatedOrder is Map) {
        setState(() {
          _order =
              Map<String, dynamic>.from(
            updatedOrder,
          );
        });
      }

      if (!mounted) {
        return;
      }

      await _showDeliveryCompleted(
        otpUsed: false,
      );

        } catch (e) {
      debugPrint(
        '❌ COMPLETE DELIVERY ERROR: $e',
      );

      final message = _extractErrorMessage(e);

      // --------------------------------------------------------
      // OTP REQUIRED
      // --------------------------------------------------------

      if (message
          .toLowerCase()
          .contains('otp verification is required')) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }

        await _showOtpDialog();

        return;
      }

      _showMessage(message);

    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // GENERIC ACTION
  // ============================================================

Future<bool> _runAction({
  required String title,
  required String endpoint,
  required String action,
}) async {
  if (_loading) {
    return false;
  }

  setState(() {
    _loading = true;
  });

  try {
    debugPrint('=================================');
    debugPrint('🚴 DELIVERY ACTION');
    debugPrint('ACTION: $action');
    debugPrint('ORDER ID: $_orderId');
    debugPrint('CURRENT STATUS: $_status');
    debugPrint('PATCH: $endpoint');
    debugPrint('=================================');

    final options =
        await DeliveryApiClient.authOptions();

    final response =
        await DeliveryApiClient.dio.patch(
      endpoint,
      options: options,
    );

    debugPrint(
      '$action STATUS: ${response.statusCode}',
    );

    debugPrint(
      '$action RESPONSE: ${response.data}',
    );

    final data = response.data;

    if (data is! Map ||
        data['success'] != true) {
      throw Exception(
        data is Map
            ? data['message']?.toString() ??
                'Action failed'
            : 'Action failed',
      );
    }

    final updatedOrder = data['order'];

    if (updatedOrder is Map) {
      setState(() {
        _order =
            Map<String, dynamic>.from(
          updatedOrder,
        );
      });
    }

    _showMessage(
      data['message']?.toString() ??
          '$action successful',
    );

    return true;
  } catch (e) {
    debugPrint(
      '❌ $action ERROR: $e',
    );

    _showMessage(
      _extractErrorMessage(e),
    );

    return false;
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}

  // ============================================================
  // CANCEL DELIVERY
  //
  // Hidden inside AppBar menu.
  // ============================================================

 // ============================================================
// CANCEL DELIVERY
// ============================================================

Future<void> _cancelDelivery() async {
  if (_orderId.isEmpty) {
    _showMessage('Invalid order');
    return;
  }

  if (_loading) {
    return;
  }

  final confirmed =
      await _showCancelConfirmation();

  if (!confirmed) {
    return;
  }

  final success = await _runAction(
    title: 'Cancelling delivery...',
    endpoint: ApiConstants.cancelOrder(
      _orderId,
    ),
    action: 'CANCEL DELIVERY',
  );

  if (!success) {
    return;
  }

  if (!mounted) {
    return;
  }

  Navigator.pop(
    context,
    true,
  );
}
  // ============================================================
  // CANCEL CONFIRMATION
  // ============================================================

  Future<bool> _showCancelConfirmation() async {
    final result =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {

        return AlertDialog(
          title: const Text(
            'Cancel delivery?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          content: const Text(
            'This order will be returned to the delivery pool and another rider can accept it.',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Keep Delivery',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Cancel Delivery',
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  // ============================================================
  // OTP DIALOG
  // ============================================================

  Future<void> _showOtpDialog() async {
    final result =
        await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _DeliveryOtpDialog();
      },
    );

    if (!mounted) {
      return;
    }

    if (result == null ||
        result.isEmpty) {
      return;
    }

    await _verifyOtp(result);
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp(
    String otp,
  ) async {

    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      debugPrint(
        '=================================',
      );
      debugPrint(
        '🚴 VERIFY DELIVERY OTP',
      );
      debugPrint(
        'ORDER ID: $_orderId',
      );
      debugPrint(
        'OTP: $otp',
      );
      debugPrint(
        'POST: ${ApiConstants.verifyDeliveryOtp}',
      );
      debugPrint(
        '=================================',
      );

      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.post(
        ApiConstants.verifyDeliveryOtp,
        data: {
          'orderId': _orderId,
          'otp': otp,
        },
        options: options,
      );

      debugPrint(
        'VERIFY OTP STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'VERIFY OTP RESPONSE: '
        '${response.data}',
      );

      final data = response.data;

      if (data is! Map ||
          data['success'] != true) {

        throw Exception(
          data is Map
              ? data['message']?.toString() ??
                  'OTP verification failed'
              : 'OTP verification failed',
        );
      }

      // ----------------------------------------------------------
      // UPDATE LOCAL ORDER
      // ----------------------------------------------------------

      final updatedOrder =
          data['order'];

      if (updatedOrder is Map) {
        setState(() {
          _order =
              Map<String, dynamic>.from(
            updatedOrder,
          );
        });
      }

      if (!mounted) {
        return;
      }

      await _showDeliveryCompleted(
        otpUsed: true,
      );

    } catch (e) {
      debugPrint(
        '❌ VERIFY OTP ERROR: $e',
      );

      _showMessage(
        _cleanError(e),
      );

    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // DELIVERY COMPLETED
  // ============================================================

  Future<void> _showDeliveryCompleted({
    required bool otpUsed,
  }) async {

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {

        return AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),

          title: const Text(
            'Delivery Completed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text(
                otpUsed
                    ? 'OTP verified successfully.'
                    : 'Delivery completed successfully.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                '₹40 delivery earning added.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          actions: [

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
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
                  'Done',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  // ============================================================
  // ERROR CLEANER
  // ============================================================

  String _cleanError(
    Object error,
  ) {

    final text =
        error.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      return text.substring(11);
    }

    return text;
  }

    // ============================================================
  // EXTRACT ERROR MESSAGE FROM DIO EXCEPTION
  //
  // When the backend returns a 4xx/5xx, Dio throws a
  // DioException instead of returning a normal response. The
  // real error message from the backend lives in
  // e.response?.data['message'], not in e.toString().
  // ============================================================

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return _cleanError(error);
  }
  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _statusLabel() {

    switch (_status) {

      case 'accepted_for_delivery':
        return 'Accepted — Go to Pickup';

      case 'arrived_at_restaurant':
        return 'Reached Pickup Location';

      case 'picked_up':
        return 'Order Picked Up';

      case 'out_for_delivery':
        return 'Out for Delivery';

      case 'arrived_at_customer':
        return 'Reached Customer Location';

      case 'delivered':
        return 'Delivered';

      case 'ready':
        return 'Available';

      default:
        return _status;
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor() {

    switch (_status) {

      case 'accepted_for_delivery':
        return const Color(0xFFFFF0E8);

      case 'arrived_at_restaurant':
        return const Color(0xFFFFF4D6);

      case 'picked_up':
        return const Color(0xFFEAF4FF);

      case 'out_for_delivery':
        return const Color(0xFFFFF4D6);

      case 'arrived_at_customer':
        return const Color(0xFFFFF4D6);

      case 'delivered':
        return const Color(0xFFE8F7EC);

      default:
        return const Color(0xFFF3EFEC);
    }
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {

    return SizedBox(
      width: double.infinity,
      height: 54,

      child: ElevatedButton.icon(
        onPressed:
            _loading
                ? null
                : onPressed,

        icon: Icon(icon),

        label: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFFF6B35),

          foregroundColor:
              Colors.white,

          disabledBackgroundColor:
              Colors.grey.shade300,

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

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFF8F2),

        elevation: 0,

        title: const Text(
          'Active Delivery',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
            color:
                Color(0xFF2A1D1A),
          ),
        ),

        actions: [

          // ----------------------------------------------------
          // CANCEL IS INTENTIONALLY HIDDEN IN MENU
          // ----------------------------------------------------

          if (
            _status != 'picked_up' &&
            _status != 'out_for_delivery' &&
            _status != 'arrived_at_customer' &&
            _status != 'delivered'
          )
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color:
                    Color(0xFF2A1D1A),
              ),

              onSelected: (value) {

                if (value ==
                    'cancel') {
                  _cancelDelivery();
                }
              },

              itemBuilder:
                  (context) {

                return const [

                  PopupMenuItem<String>(
                    value: 'cancel',

                    child: Row(
                      children: [

                        Icon(
                          Icons
                              .cancel_outlined,
                          color:
                              Colors.red,
                        ),

                        SizedBox(
                          width: 10,
                        ),

                        Text(
                          'Cancel delivery',
                          style:
                              TextStyle(
                            color:
                                Colors.red,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Stack(
        children: [

          RefreshIndicator(
            onRefresh: () async {
              // Future:
              // refresh active order from backend
            },

            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.all(20),

              children: [

                // =================================================
                // STATUS CARD
                // =================================================

                Container(
                  padding:
                      const EdgeInsets.all(18),

                  decoration:
                      BoxDecoration(
                    color:
                        _statusColor(),

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),

                  child: Row(
                    children: [

                      const Icon(
                        Icons
                            .delivery_dining,
                        color:
                            Color(0xFFFF6B35),
                        size: 30,
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            const Text(
                              'Delivery Status',
                              style:
                                  TextStyle(
                                fontSize: 13,
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
                              _statusLabel(),
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    Color(
                                  0xFF2A1D1A,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // =================================================
                // ORDER CARD
                // =================================================

                Container(
                  padding:
                      const EdgeInsets.all(20),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),

                    boxShadow: const [

                      BoxShadow(
                        color:
                            Color(0x12000000),
                        blurRadius: 12,
                        offset:
                            Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Row(
                        children: [

                          Container(
                            width: 50,
                            height: 50,

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFFFE8DC,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),

                            child: const Icon(
                              Icons
                                  .receipt_long_outlined,
                              color:
                                  Color(
                                0xFFFF6B35,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                Text(
                                  _customerName,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Order #${_shortId(_orderId)}',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        12,
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
                            '₹$_amount',
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      const Text(
                        'Deliver to',
                        style:
                            TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(
                            0xFF756864,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          const Icon(
                            Icons
                                .location_on_outlined,
                            color:
                                Color(
                              0xFFFF6B35,
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Expanded(
                            child: Text(
                              _address,
                              style:
                                  const TextStyle(
                                fontSize:
                                    14,
                                height:
                                    1.4,
                                color:
                                    Color(
                                  0xFF2A1D1A,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // STEP 1
                // ACCEPTED
                // =================================================

                if (_status ==
                    'accepted_for_delivery')
                  _actionButton(
                    text:
                        'Reached Pickup Location',

                    icon:
                        Icons
                            .storefront_outlined,

                    onPressed:
                        _reachedPickup,
                  ),

                // =================================================
                // STEP 2
                // REACHED RESTAURANT
                // =================================================

                if (_status ==
                    'arrived_at_restaurant')
                  _actionButton(
                    text:
                        'Picked Up Order',

                    icon:
                        Icons
                            .shopping_bag_outlined,

                    onPressed:
                        _pickUp,
                  ),

                // =================================================
                // STEP 3
                // PICKED UP
                // =================================================

                if (_status ==
                    'picked_up')
                  _actionButton(
                    text:
                        'Start Delivery',

                    icon:
                        Icons
                            .delivery_dining,

                    onPressed:
                        _outForDelivery,
                  ),

                // =================================================
                // STEP 4
                // OUT FOR DELIVERY
                //
                // THIS WAS MISSING IN YOUR OLD CODE.
                // =================================================

                if (_status ==
                    'out_for_delivery')
                  _actionButton(
                    text:
                        'Reached Customer Location',

                    icon:
                        Icons
                            .location_on_outlined,

                    onPressed:
                        _reachedCustomer,
                  ),

                // =================================================
                // STEP 5
                // ARRIVED AT CUSTOMER
                // =================================================

                if (_status ==
                    'arrived_at_customer')
                  _actionButton(
                    text:
                        'Complete Delivery',

                    icon:
                        Icons
                            .check_circle_outline,

                    onPressed:
                        _completeDelivery,
                  ),

                  // =================================================
// CANCEL DELIVERY
// Hidden-style cancellation option
// Available only before pickup
// =================================================

if (_status == 'accepted_for_delivery' ||
    _status == 'arrived_at_restaurant')
  Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Center(
      child: TextButton(
        onPressed: _loading
            ? null
            : _cancelDelivery,
        child: const Text(
          'Need to cancel delivery?',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  ),

                // =================================================
                // STEP 6
                // DELIVERED
                // =================================================

                if (_status ==
                    'delivered')
                  Container(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFE8F7EC,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),

                    child: const Column(
                      children: [

                        Icon(
                          Icons
                              .check_circle,
                          color:
                              Colors.green,
                          size: 48,
                        ),

                        SizedBox(
                          height: 10,
                        ),

                        Text(
                          'Delivery Completed',
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),

                        SizedBox(
                          height: 6,
                        ),

                        Text(
                          '₹40 earning added',
                          style:
                              TextStyle(
                            color:
                                Colors.green,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),

          // ========================================================
          // LOADING OVERLAY
          // ========================================================

          if (_loading)
            Container(
              color:
                  Colors.black.withValues(
                alpha: 0.08,
              ),

              child:
                  const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      Color(0xFFFF6B35),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SHORT ID
  // ============================================================

  String _shortId(
    String id,
  ) {

    if (id.length <= 8) {
      return id;
    }

    return id.substring(
      0,
      8,
    );
  }
}

// ================================================================
// DELIVERY OTP DIALOG
// ================================================================

class _DeliveryOtpDialog
    extends StatefulWidget {

  const _DeliveryOtpDialog();

  @override
  State<_DeliveryOtpDialog>
      createState() =>
          _DeliveryOtpDialogState();
}

class _DeliveryOtpDialogState
    extends State<_DeliveryOtpDialog> {

  late final TextEditingController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // VERIFY
  // ============================================================

  void _verify() {

    final otp =
        _controller.text.trim();

    if (otp.length != 4) {

      ScaffoldMessenger.of(context)
        .showSnackBar(
          const SnackBar(
            content: Text(
              'Enter the 4-digit OTP',
            ),
          ),
        );

      return;
    }

    Navigator.of(context)
        .pop(otp);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return AlertDialog(

      title: const Text(
        'Verify Delivery OTP',
        style: TextStyle(
          fontWeight:
              FontWeight.w800,
        ),
      ),

      content: Column(
        mainAxisSize:
            MainAxisSize.min,

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            'Ask the customer for the 4-digit delivery OTP.',
          ),

          const SizedBox(
            height: 18,
          ),

          TextField(
            controller:
                _controller,

            keyboardType:
                TextInputType.number,

            maxLength: 4,

            autofocus: true,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: 8,
            ),

            decoration:
                InputDecoration(
              hintText:
                  '0000',

              counterText:
                  '',

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),

            onSubmitted: (_) {
              _verify();
            },
          ),
        ],
      ),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop();
          },

          child: const Text(
            'Cancel',
          ),
        ),

        ElevatedButton(
          onPressed:
              _verify,

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                const Color(
              0xFFFF6B35,
            ),

            foregroundColor:
                Colors.white,
          ),

          child: const Text(
            'Verify',
          ),
        ),
      ],
    );
  }
}
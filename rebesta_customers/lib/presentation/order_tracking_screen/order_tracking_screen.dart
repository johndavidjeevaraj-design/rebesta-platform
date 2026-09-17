import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/delivery_socket_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';

import './widgets/driver_info_card_widget.dart';
import './widgets/eta_hero_widget.dart';
import './widgets/order_status_stepper_widget.dart';
import './widgets/order_summary_widget.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState
    extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // ORDER STEPS
  //
  // 0 = Placed
  // 1 = Confirmed
  // 2 = Preparing
  // 3 = Out for Delivery
  // 4 = Delivered
  // ============================================================

  final DeliverySocketService _deliverySocket =
      DeliverySocketService();

  final OrderService _orderService = OrderService();

  Timer? _routeRefreshTimer;

  // ============================================================
  // RIDER LIVE LOCATION
  // ============================================================

  double? _riderLatitude;
  double? _riderLongitude;

  // ============================================================
  // ROAD ROUTE
  // ============================================================

  List<LatLng> _routePoints = [];

  // ============================================================
  // ORDER STATE
  // ============================================================

  int _currentStep = 0;

  bool _isOrderSummaryExpanded = true;

  Map<String, dynamic>? _tracking;

  bool _loading = true;

  String? _error;

  // ============================================================
  // ANIMATION
  // ============================================================

  late AnimationController _pulseController;

  late Animation<double> _pulseAnimation;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _loadTracking(
      initialLoad: true,
    );
  }

  // ============================================================
  // LOAD TRACKING
  // ============================================================

  Future<void> _loadTracking({
    bool initialLoad = false,
  }) async {
    try {
      debugPrint('================================');
      debugPrint('📦 LOAD ORDER TRACKING');
      debugPrint('Order ID: ${widget.orderId}');
      debugPrint(
        'Initial Load: $initialLoad',
      );
      debugPrint('================================');

      final response =
          await _orderService.trackOrder(
        widget.orderId,
      );

      debugPrint(
        'TRACKING RESPONSE: $response',
      );

      if (!mounted) return;

      final tracking =
          Map<String, dynamic>.from(
        response['tracking'] ?? {},
      );

      // ========================================================
      // RIDER
      // ========================================================

      final rider =
          tracking['rider']
              as Map<String, dynamic>?;

      final riderLatitude =
          double.tryParse(
        rider?['currentLatitude']
                ?.toString() ??
            '',
      );

      final riderLongitude =
          double.tryParse(
        rider?['currentLongitude']
                ?.toString() ??
            '',
      );

      debugPrint('================================');
      debugPrint('📍 RIDER LOCATION FROM API');
      debugPrint(
        'Latitude: $riderLatitude',
      );
      debugPrint(
        'Longitude: $riderLongitude',
      );
      debugPrint('================================');

      // ========================================================
      // CURRENT STEP
      // ========================================================

      final currentStep =
          _getCurrentStep(
        tracking,
      );

      debugPrint('================================');
      debugPrint('📦 CURRENT ORDER STEP');
      debugPrint(
        'Status: ${tracking['status']}',
      );
      debugPrint(
        'Step: $currentStep',
      );
      debugPrint(
        'Label: ${_statusLabelForStep(currentStep)}',
      );
      debugPrint('================================');

      // ========================================================
      // ROAD ROUTE
      // ========================================================

      final eta =
          tracking['eta']
              as Map<String, dynamic>?;

      final routePoints =
          _decodeRouteGeometry(
        eta?['polyline'],
      );

      debugPrint('================================');
      debugPrint('🛣️ ROAD ROUTE');
      debugPrint(
        'Route points: ${routePoints.length}',
      );
      debugPrint(
        'Distance: ${eta?['distance']} km',
      );
      debugPrint(
        'Duration: ${eta?['duration']} minutes',
      );
      debugPrint('================================');

      // ========================================================
      // UPDATE UI
      // ========================================================

      setState(() {
        _tracking = tracking;

        _currentStep = currentStep;

        _riderLatitude = riderLatitude;

        _riderLongitude = riderLongitude;

        _routePoints = routePoints;

        _loading = false;

        _error = null;
      });

      // ========================================================
      // CONNECT SOCKET ONLY ON FIRST LOAD
      // ========================================================

      if (initialLoad) {
        await _connectLiveLocation();

        _startRouteRefresh();
      }
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('❌ TRACKING ERROR');
      debugPrint('ERROR: $e');
      debugPrint(
        'STACK: $stackTrace',
      );
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        _loading = false;

        _error = e.toString();
      });
    }
  }

  // ============================================================
  // ROUTE REFRESH
  //
  // We DO NOT call ORS on every GPS socket update.
  //
  // Instead:
  //
  // GPS → marker updates immediately
  //
  // Every 15 seconds:
  //
  // REST → backend → ORS → new road route
  // ============================================================

  void _startRouteRefresh() {
    _routeRefreshTimer?.cancel();

    _routeRefreshTimer =
        Timer.periodic(
      const Duration(
        seconds: 15,
      ),
      (_) {
        if (!mounted) return;

        // Only refresh route while delivery
        // is actually moving.

        if (_currentStep >= 3 &&
            _currentStep < 4) {
          debugPrint(
            '🔄 Refreshing road route...',
          );

          _loadTracking(
            initialLoad: false,
          );
        }
      },
    );
  }

  // ============================================================
  // CONNECT CUSTOMER LIVE LOCATION SOCKET
  // ============================================================

  Future<void> _connectLiveLocation() async {
    try {
      debugPrint('================================');
      debugPrint(
        '📡 CONNECT CUSTOMER LIVE SOCKET',
      );
      debugPrint(
        'Order ID: ${widget.orderId}',
      );
      debugPrint('================================');

      await _deliverySocket.connect(
        orderId: widget.orderId,
        onLocationUpdate: (location) {
          if (!mounted) return;

          // ======================================================
          // ORDER ID
          // ======================================================

          final incomingOrderId =
              location['orderId']
                  ?.toString();

          debugPrint('================================');
          debugPrint(
            '📍 LIVE DELIVERY LOCATION',
          );
          debugPrint(
            'DATA: $location',
          );
          debugPrint('================================');

          // ======================================================
          // IGNORE OTHER ORDERS
          // ======================================================

          if (incomingOrderId !=
              widget.orderId) {
            debugPrint(
              '⚠️ Ignoring socket location for another order: '
              '$incomingOrderId',
            );

            return;
          }

          // ======================================================
          // LATITUDE
          // ======================================================

          final latitude =
              double.tryParse(
            location['latitude']
                    ?.toString() ??
                '',
          );

          // ======================================================
          // LONGITUDE
          // ======================================================

          final longitude =
              double.tryParse(
            location['longitude']
                    ?.toString() ??
                '',
          );

          if (latitude == null ||
              longitude == null) {
            debugPrint(
              '⚠️ Invalid rider coordinates',
            );

            return;
          }

          // ======================================================
          // LIVE RIDER
          // ======================================================

          debugPrint(
            '🚴 RIDER LOCATION: '
            '$latitude, $longitude',
          );

          debugPrint(
            '📦 Rider belongs to order: '
            '$incomingOrderId',
          );

          // ======================================================
          // UPDATE RIDER MARKER
          // ======================================================

          setState(() {
            _riderLatitude = latitude;

            _riderLongitude = longitude;

            // ==================================================
            // IMPORTANT
            //
            // Move the beginning of the current route to the
            // latest rider position.
            //
            // The complete road route gets recalculated every
            // 15 seconds by the backend.
            // ==================================================

            if (_routePoints.length >= 2) {
              _routePoints = [
                LatLng(
                  latitude,
                  longitude,
                ),
                ..._routePoints.skip(1),
              ];
            }
          });
        },
      );
    } catch (e) {
      debugPrint(
        '❌ LIVE LOCATION SOCKET ERROR: $e',
      );
    }
  }

  // ============================================================
  // DECODE ORS ROUTE
  //
  // OpenRouteService returns an encoded polyline.
  //
  // This converts:
  //
  // encoded string
  //        ↓
  // List<LatLng>
  //        ↓
  // FlutterMap Polyline
  // ============================================================

  List<LatLng> _decodeRouteGeometry(
    dynamic geometry,
  ) {
    if (geometry == null) {
      return [];
    }

    // ==========================================================
    // STRING ENCODED POLYLINE
    // ==========================================================

    if (geometry is String) {
      if (geometry.isEmpty) {
        return [];
      }

      return _decodePolyline(
        geometry,
      );
    }

    // ==========================================================
    // SUPPORT GEOJSON-STYLE COORDINATES
    //
    // In case backend later returns:
    //
    // [
    //   [longitude, latitude],
    //   [longitude, latitude]
    // ]
    // ==========================================================

    if (geometry is List) {
      final points = <LatLng>[];

      for (final coordinate
          in geometry) {
        if (coordinate is List &&
            coordinate.length >= 2) {
          final longitude =
              double.tryParse(
            coordinate[0].toString(),
          );

          final latitude =
              double.tryParse(
            coordinate[1].toString(),
          );

          if (latitude != null &&
              longitude != null) {
            points.add(
              LatLng(
                latitude,
                longitude,
              ),
            );
          }
        }
      }

      return points;
    }

    return [];
  }

  // ============================================================
  // GOOGLE / ORS ENCODED POLYLINE DECODER
  // ============================================================

  List<LatLng> _decodePolyline(
    String encoded,
  ) {
    final points = <LatLng>[];

    int index = 0;

    int latitude = 0;

    int longitude = 0;

    while (index < encoded.length) {
      // ========================================================
      // LATITUDE
      // ========================================================

      int result = 0;

      int shift = 0;

      int byte;

      do {
        if (index >= encoded.length) {
          return points;
        }

        byte =
            encoded.codeUnitAt(
                  index++,
                ) -
                63;

        result |=
            (byte & 0x1f) << shift;

        shift += 5;
      } while (byte >= 0x20);

      final deltaLatitude =
          (result & 1) != 0
              ? ~(result >> 1)
              : (result >> 1);

      latitude +=
          deltaLatitude;

      // ========================================================
      // LONGITUDE
      // ========================================================

      result = 0;

      shift = 0;

      do {
        if (index >= encoded.length) {
          return points;
        }

        byte =
            encoded.codeUnitAt(
                  index++,
                ) -
                63;

        result |=
            (byte & 0x1f) << shift;

        shift += 5;
      } while (byte >= 0x20);

      final deltaLongitude =
          (result & 1) != 0
              ? ~(result >> 1)
              : (result >> 1);

      longitude +=
          deltaLongitude;

      // ========================================================
      // PRECISION 5
      // ========================================================

      points.add(
        LatLng(
          latitude / 100000.0,
          longitude / 100000.0,
        ),
      );
    }

    return points;
  }

  // ============================================================
  // CONVERT BACKEND STATUS → UI STEP
  // ============================================================

  int _getCurrentStep(
    Map<String, dynamic> tracking,
  ) {
    final status =
        tracking['status']
            ?.toString()
            .toLowerCase()
            .trim();

    debugPrint(
      '📦 TRACKING STATUS: $status',
    );

    switch (status) {
      // ========================================================
      // STEP 0
      // ========================================================

      case 'placed':
      case 'pending':
      case 'order_placed':
        return 0;

      // ========================================================
      // STEP 1
      // ========================================================

      case 'confirmed':
      case 'accepted':
        return 1;

      // ========================================================
      // STEP 2
      // ========================================================

      case 'accepted_for_delivery':
      case 'arrived_at_restaurant':
      case 'preparing':
        return 2;

      // ========================================================
      // STEP 3
      // ========================================================

      case 'picked_up':
      case 'picked-up':
      case 'out_for_delivery':
      case 'out-for-delivery':
      case 'out for delivery':
      case 'on_the_way':
      case 'on the way':
      case 'arrived_at_customer':
        return 3;

      // ========================================================
      // STEP 4
      // ========================================================

      case 'delivered':
      case 'completed':
        return 4;

      // ========================================================
      // UNKNOWN
      // ========================================================

      default:
        debugPrint(
          '⚠️ UNKNOWN ORDER STATUS: $status',
        );

        return 0;
    }
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _statusLabelForStep(
    int step,
  ) {
    switch (step) {
      case 0:
        return 'Order placed';

      case 1:
        return 'Confirmed';

      case 2:
        return 'Preparing';

      case 3:
        return 'On the way';

      case 4:
        return 'Delivered';

      default:
        return 'Order placed';
    }
  }

  String _getStatusLabel() {
    return _statusLabelForStep(
      _currentStep,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _routeRefreshTimer?.cancel();

    _deliverySocket.disconnect();

    _pulseController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final isTablet =
        MediaQuery.of(context).size.width >=
            600;

    // ==========================================================
    // LOADING
    // ==========================================================

    if (_loading) {
      return Scaffold(
        backgroundColor:
            AppTheme.backgroundLight,
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_error != null) {
      return Scaffold(
        backgroundColor:
            AppTheme.backgroundLight,
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons
                      .error_outline_rounded,
                  size: 48,
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Unable to load order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  _error!,
                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(
                  height: 20,
                ),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });

                    _loadTracking(
                      initialLoad: true,
                    );
                  },
                  child:
                      const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // MAIN SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor:
          AppTheme.backgroundLight,
      body: isTablet
          ? _buildTabletLayout(
              context,
            )
          : _buildPhoneLayout(
              context,
            ),
    );
  }

  // ============================================================
  // PHONE LAYOUT
  // ============================================================

  Widget _buildPhoneLayout(
    BuildContext context,
  ) {
    return CustomScrollView(
      slivers: [
        // ======================================================
        // APP BAR
        // ======================================================

        SliverToBoxAdapter(
          child:
              _buildAppBar(context),
        ),

        // ======================================================
        // ETA HERO
        // ======================================================

        SliverToBoxAdapter(
          child:
              EtaHeroWidget(
            currentStep:
                _currentStep,
            pulseAnimation:
                _pulseAnimation,
          ),
        ),

        // ======================================================
        // LIVE MAP
        // ======================================================

        SliverToBoxAdapter(
          child:
              _buildLiveMap(context),
        ),

        // ======================================================
        // ORDER STATUS
        // ======================================================

        SliverToBoxAdapter(
          child:
              OrderStatusStepperWidget(
            currentStep:
                _currentStep,
          ),
        ),


        // ======================================================
// DELIVERY OTP
// ======================================================

SliverToBoxAdapter(
  child: _buildDeliveryOtpCard(),
),

        // ======================================================
        // DRIVER
        // ======================================================

        SliverToBoxAdapter(
          child:
              DriverInfoCardWidget(
            rider:
                _tracking?['rider']
                    as Map<String, dynamic>?,
            eta:
                _tracking?['eta']
                    as Map<String, dynamic>?,
          ),
        ),

        // ======================================================
        // ORDER SUMMARY
        // ======================================================

        SliverToBoxAdapter(
          child:
              OrderSummaryWidget(
            items:
                (_tracking?['items']
                        as List<dynamic>?) ??
                    [],

            totalAmount:
                (_tracking?['totalAmount']
                            as num?)
                        ?.toDouble() ??
                    0,

            discountAmount:
                (_tracking?[
                            'discountAmount']
                        as num?)
                    ?.toDouble() ??
                0,

            deliveryFee:
                (_tracking?[
                            'deliveryFee']
                        as num?)
                    ?.toDouble() ??
                0,

            paymentStatus:
                _tracking?[
                            'paymentStatus']
                        ?.toString() ??
                    'pending',

            isExpanded:
                _isOrderSummaryExpanded,

            onToggle: () {
              setState(() {
                _isOrderSummaryExpanded =
                    !_isOrderSummaryExpanded;
              });
            },
          ),
        ),

        // ======================================================
        // BOTTOM SPACE
        // ======================================================

        const SliverToBoxAdapter(
          child:
              SizedBox(
            height: 100,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TABLET LAYOUT
  // ============================================================

  Widget _buildTabletLayout(
    BuildContext context,
  ) {
    return Row(
      children: [
        // ======================================================
        // LEFT — LIVE MAP
        // ======================================================

        Expanded(
          flex: 55,
          child:
              _buildLiveMap(context),
        ),

        // ======================================================
        // RIGHT — STATUS PANEL
        // ======================================================

        Expanded(
          flex: 45,
          child:
              SingleChildScrollView(
            child: Column(
              children: [
                _buildAppBar(
                  context,
                ),

                EtaHeroWidget(
                  currentStep:
                      _currentStep,
                  pulseAnimation:
                      _pulseAnimation,
                ),

                OrderStatusStepperWidget(
                  currentStep:
                      _currentStep,
                ),

                DriverInfoCardWidget(
                  rider:
                      _tracking?[
                              'rider']
                          as Map<String, dynamic>?,

                  eta:
                      _tracking?[
                              'eta']
                          as Map<String, dynamic>?,
                ),

                OrderSummaryWidget(
                  isExpanded:
                      _isOrderSummaryExpanded,

                  onToggle: () {
                    setState(() {
                      _isOrderSummaryExpanded =
                          !_isOrderSummaryExpanded;
                    });
                  },

                  items:
                      (_tracking?[
                                  'items']
                              as List?) ??
                          [],

                  totalAmount:
                      (_tracking?[
                                  'totalAmount'] ??
                              0.0)
                          .toDouble(),

                  discountAmount:
                      (_tracking?[
                                  'discountAmount'] ??
                              0.0)
                          .toDouble(),

                  deliveryFee:
                      (_tracking?[
                                  'deliveryFee'] ??
                              0.0)
                          .toDouble(),

                  paymentStatus:
                      _tracking?[
                                  'paymentStatus']
                              ?.toString() ??
                          'pending',
                ),

                const SizedBox(
                  height: 32,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LIVE MAP
  // ============================================================

  Widget _buildLiveMap(
    BuildContext context,
  ) {
    final tracking =
        _tracking;

    // ==========================================================
    // DESTINATION
    // ==========================================================

    final destination =
        tracking?['destination']
            as Map<String, dynamic>?;

    final destinationLat =
        double.tryParse(
      destination?['latitude']
              ?.toString() ??
          '',
    );

    final destinationLng =
        double.tryParse(
      destination?['longitude']
              ?.toString() ??
          '',
    );

    // ==========================================================
    // RIDER
    // ==========================================================

    final riderLat =
        _riderLatitude;

    final riderLng =
        _riderLongitude;

    // ==========================================================
    // INITIAL MAP CENTER
    // ==========================================================

    final initialLat =
        riderLat ??
            destinationLat ??
            12.735;

    final initialLng =
        riderLng ??
            destinationLng ??
            77.829;

    // ==========================================================
    // HAS ROAD ROUTE
    // ==========================================================

    final hasRoute =
        _routePoints.length >= 2;

    debugPrint(
      '🗺️ MAP ROUTE POINTS: '
      '${_routePoints.length}',
    );

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        0,
      ),
      height: 300,
      clipBehavior:
          Clip.antiAlias,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        boxShadow:
            AppTheme.cardShadow,
      ),
      child: Stack(
        children: [
          // ====================================================
          // OPENSTREETMAP
          // ====================================================

          FlutterMap(
            options:
                MapOptions(
              initialCenter:
                  LatLng(
                initialLat,
                initialLng,
              ),
              initialZoom:
                  14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.rebesta_customers',
              ),

              // ==================================================
              // ACTUAL ROAD ROUTE
              //
              // IMPORTANT:
              //
              // This is NOT:
              //
              // rider → customer
              //
              // This is:
              //
              // rider → road → road → road → customer
              // ==================================================

              if (hasRoute)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points:
                          _routePoints,
                      strokeWidth:
                          5,
                    ),
                  ],
                ),

              // ==================================================
              // MARKERS
              // ==================================================

              MarkerLayer(
                markers: [
                  // ============================================
                  // RIDER
                  // ============================================

                  if (riderLat != null &&
                      riderLng != null)
                    Marker(
                      point:
                          LatLng(
                        riderLat,
                        riderLng,
                      ),
                      width: 64,
                      height: 64,
                      child:
                          ScaleTransition(
                        scale:
                            _pulseAnimation,
                        child:
                            Container(
                          decoration:
                              BoxDecoration(
                            color:
                                AppTheme.primary,
                            shape:
                                BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme
                                    .primary
                                    .withAlpha(
                                  90,
                                ),
                                blurRadius:
                                    18,
                                spreadRadius:
                                    4,
                              ),
                            ],
                          ),
                          child:
                              const Icon(
                            Icons
                                .delivery_dining_rounded,
                            color:
                                Colors.white,
                            size:
                                30,
                          ),
                        ),
                      ),
                    ),

                  // ============================================
                  // CUSTOMER
                  // ============================================

                  if (destinationLat !=
                          null &&
                      destinationLng !=
                          null)
                    Marker(
                      point:
                          LatLng(
                        destinationLat,
                        destinationLng,
                      ),
                      width: 50,
                      height: 60,
                      child:
                          Column(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  8,
                              vertical:
                                  5,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              boxShadow:
                                  AppTheme
                                      .cardShadow,
                            ),
                            child:
                                const Text(
                              'You',
                              style:
                                  TextStyle(
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons
                                .location_on,
                            color:
                                Colors.red,
                            size:
                                30,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ====================================================
          // LIVE STATUS
          // ====================================================

          Positioned(
            top: 20,
            left: 20,
            child:
                Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                boxShadow:
                    AppTheme.cardShadow,
              ),
              child:
                  Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.green,
                      shape:
                          BoxShape.circle,
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    riderLat != null &&
                            riderLng !=
                                null
                        ? 'Rider is live'
                        : 'Waiting for rider...',
                    style:
                        const TextStyle(
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====================================================
          // ROUTE STATUS
          // ====================================================

          if (hasRoute)
            Positioned(
              bottom: 16,
              left: 16,
              child:
                  Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  boxShadow:
                      AppTheme
                          .cardShadow,
                ),
                child:
                    const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .route_rounded,
                      size: 15,
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Text(
                      'Live road route',
                      style:
                          TextStyle(
                        fontSize:
                            11,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildDeliveryOtpCard() {
  final otp = _tracking?['delivery_otp']?.toString();

  if (otp == null || otp.isEmpty) {
    return const SizedBox.shrink();
  }

  // Show OTP only once the order is actually out for delivery.
  if (_currentStep < 3 || _currentStep >= 4) {
    return const SizedBox.shrink();
  }

  return Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: AppTheme.cardShadow,
      border: Border.all(
        color: AppTheme.primary.withAlpha(40),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.primary,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Give this code to your rider',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              otp.split('').join(' '),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppTheme.mutedText,
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                'Only share this OTP when your delivery partner reaches you.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppTheme.mutedText,
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
  // APP BAR
  // ============================================================

  Widget _buildAppBar(
    BuildContext context,
  ) {
    final restaurant =
        _tracking?['restaurant']
            as Map<String, dynamic>?;

    final restaurantName =
        restaurant?[
                    'restaurant_name']
                ?.toString() ??
            'Restaurant';

    return SafeArea(
      child:
          Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          0,
        ),
        child:
            Row(
          children: [
            // ==================================================
            // BACK
            // ==================================================

            GestureDetector(
              onTap: () =>
                  context.pop(),

              child:
                  Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  boxShadow:
                      AppTheme
                          .cardShadow,
                ),
                child:
                    Center(
                  child:
                      CustomIconWidget(
                    iconName:
                        'arrow_back_ios_new_rounded',
                    color:
                        AppTheme
                            .headlineText,
                    size:
                        18,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // ==================================================
            // ORDER TITLE
            // ==================================================

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'Order #${widget.orderId.substring(0, 8)}',
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .titleMedium,
                  ),

                  Text(
                    restaurantName,
                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .bodySmall,
                  ),
                ],
              ),
            ),

            // ==================================================
            // STATUS PILL
            // ==================================================

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme
                        .warningContainer,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child:
                  Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(
                      color:
                          AppTheme
                              .warning,
                      shape:
                          BoxShape.circle,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    _getStatusLabel(),
                    style:
                        TextStyle(
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight
                              .w600,
                      color:
                          AppTheme
                              .warning,
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
}
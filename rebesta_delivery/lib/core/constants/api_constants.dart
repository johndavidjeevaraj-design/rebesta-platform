class ApiConstants {
  /// Single source of truth for the backend URL.
  ///
  /// Switch environment without editing code:
  ///   emulator      flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  ///   physical/LAN  flutter run --dart-define=API_BASE_URL=http://172.16.255.167:3000
  ///   production    flutter build apk --release --dart-define=API_BASE_URL=https://api.rebesta.com
  ///
  /// The default is only a dev fallback - always pass --dart-define for release.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );


  // ============================================================
  // DELIVERY AUTH
  // ============================================================

  static const String deliveryAuth =
      '$baseUrl/delivery-auth';

  static const String login =
      '$deliveryAuth/login';

  static const String register =
      '$deliveryAuth/register';

  static const String profile =
      '$deliveryAuth/profile';

  // ============================================================
  // DELIVERY
  // ============================================================

  static const String delivery =
      '$baseUrl/delivery';

  // ============================================================
  // DASHBOARD
  // ============================================================

  static const String dashboard =
      '$delivery/dashboard';

  // ============================================================
  // AVAILABLE ORDERS
  // ============================================================

  static const String availableOrders =
      '$delivery/available-orders';

  // ============================================================
  // ACTIVE ORDERS
  // ============================================================

  static const String activeOrders =
      '$delivery/active-orders';

  // ============================================================
  // ORDER ACTIONS
  // ============================================================

  // ------------------------------------------------------------
  // ACCEPT ORDER
  // ------------------------------------------------------------

  static String acceptOrder(
    String orderId,
  ) =>
      '$delivery/orders/$orderId/accept';

  // ------------------------------------------------------------
  // REACHED PICKUP LOCATION
  // ------------------------------------------------------------

  static String reachedPickup(
    String orderId,
  ) =>
      '$delivery/orders/$orderId/reached-pickup';

  // ------------------------------------------------------------
  // PICKED UP ORDER
  // ------------------------------------------------------------

  static String pickUpOrder(
    String orderId,
  ) =>
      '$delivery/orders/$orderId/pick-up';

  // ------------------------------------------------------------
  // REACHED CUSTOMER LOCATION
  // ------------------------------------------------------------

  static String reachedCustomer(
    String orderId,
  ) =>
      '$delivery/orders/$orderId/reached-customer';

  // ------------------------------------------------------------
  // OUT FOR DELIVERY
  // ------------------------------------------------------------

  // Keep this only if the backend still uses this stage.
  // If the new flow does not use it, we can remove it later.
  static String outForDelivery(
    String orderId,
  ) =>
      '$delivery/orders/$orderId/out-for-delivery';

  // ------------------------------------------------------------
  // CANCEL DELIVERY
  // ------------------------------------------------------------

  static String cancelOrder(
    String orderId,
  ) =>
      '$delivery/orders/$orderId/cancel';

  // ============================================================
  // DELIVERY STATUS
  // ============================================================

  static const String updateStatus =
      '$delivery/status';

  // ============================================================
  // DELIVERY LOCATION
  // ============================================================

  static const String updateLocation =
      '$delivery/location';

  // ============================================================
  // DELIVERY OTP
  // ============================================================

  static const String verifyDeliveryOtp =
      '$delivery/verify-otp';

  // ============================================================
  // DELIVERY COMPLETION
  // ============================================================

  static String completeOrder(
    String orderId,
  ) =>
      '$delivery/orders/$orderId/complete';

  // ============================================================
  // HISTORY
  // ============================================================

  static const String history =
      '$delivery/history';

  // ============================================================
  // WALLET
  // ============================================================

  static const String wallet =
      '$delivery/wallet';

  // ============================================================
  // EARNINGS
  // ============================================================

  static const String earnings =
      '$delivery/earnings';
}
import 'package:flutter_test/flutter_test.dart';

// ============================================================
// COMPILE SMOKE TEST
// ============================================================
//
// Importing the app entry point forces the compiler to
// type-check the ENTIRE app tree (main -> router -> screens ->
// services -> ...). A broken file anywhere in the import graph
// fails HERE in CI, instead of failing on a customer's phone.
//
// Note: `flutter analyze` in CI is continue-on-error, so this
// test is the real compile guard for this app.
// ============================================================

// ignore: unused_import
import 'package:rebesta_customers/main.dart' as app;

// ignore: unused_import
import 'package:rebesta_customers/presentation/order_tracking_screen/order_tracking_screen.dart'
    as tracking;

void main() {
  test('app tree compiles', () {
    expect(app.MyApp, isNotNull);
    expect(tracking.OrderTrackingScreen, isNotNull);
  });
}

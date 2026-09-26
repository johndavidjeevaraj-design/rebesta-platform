import 'package:flutter_test/flutter_test.dart';

// ============================================================
// COMPILE SMOKE TEST
// ============================================================
//
// Importing the app entry point forces the compiler to
// type-check the ENTIRE app tree (main -> dashboard ->
// orders -> active delivery -> ...). A broken file anywhere
// in the import graph fails HERE in CI, instead of failing
// on a rider's phone.
//
// Note: `flutter analyze` in CI is continue-on-error, so this
// test is the real compile guard for this app.
// ============================================================

// ignore: unused_import
import 'package:rebesta_delivery/main.dart' as app;

// ignore: unused_import
import 'package:rebesta_delivery/core/services/delivery_socket_service.dart'
    as socket_service;

void main() {
  test('app tree compiles', () {
    expect(app.RebestaDeliveryApp, isNotNull);
    expect(socket_service.DeliverySocketService, isNotNull);
  });
}

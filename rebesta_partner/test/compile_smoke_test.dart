import 'package:flutter_test/flutter_test.dart';

// ============================================================
// COMPILE SMOKE TEST
// ============================================================
//
// Importing the app entry point forces the compiler to
// type-check the ENTIRE app tree (main -> dashboard -> orders
// -> menu -> ...). A broken file anywhere in the import graph
// fails HERE in CI, instead of failing on a restaurant's
// device.
//
// Note: `flutter analyze` in CI is continue-on-error, so this
// test is the real compile guard for this app.
// ============================================================

// ignore: unused_import
import 'package:rebesta_partner/main.dart' as entry;

// ignore: unused_import
import 'package:rebesta_partner/app.dart' as app;

// ignore: unused_import
import 'package:rebesta_partner/core/services/partner_socket_service.dart'
    as partner_socket;

void main() {
  test('app tree compiles', () {
    expect(app.RebestaPartnerApp, isNotNull);
    expect(partner_socket.PartnerSocketService, isNotNull);
    expect(entry.main, isNotNull);
  });
}

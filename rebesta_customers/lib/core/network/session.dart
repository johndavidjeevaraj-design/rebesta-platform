import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';

// ============================================================
// SESSION EXPIRY
// ============================================================
//
// Any authenticated API call that comes back 401 means the
// customer's token is missing, expired or invalid. Instead
// of dumping raw DioExceptions on screen, we wipe the stored
// session and send the customer back to the login screen.
// ============================================================

class Session {
  static bool _expiring = false;

  static Future<void> expire() async {
    // Several calls can 401 at the same time (home fires
    // profile + orders + addresses in parallel) - only run
    // the logout once.

    if (_expiring) return;

    _expiring = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('token');
      await prefs.remove('customerName');

      appRouter.go(AppRoutes.loginScreen);
    } finally {
      _expiring = false;
    }
  }
}

// ============================================================
// DIO INTERCEPTOR
// ============================================================
//
// Attach to every authenticated service's Dio instance.
// The error still propagates to the calling screen (so its
// own try/catch keeps working) - this just triggers the
// session cleanup + redirect in the background.
// ============================================================

InterceptorsWrapper authExpiredInterceptor() {
  return InterceptorsWrapper(
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        Session.expire();
      }

      return handler.next(error);
    },
  );
}

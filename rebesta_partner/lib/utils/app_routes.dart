import 'package:flutter/material.dart';

import '../screens/login/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
    }
  }
}
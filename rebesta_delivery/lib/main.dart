import 'package:flutter/material.dart';

import 'core/storage/delivery_auth_storage.dart';
import 'screens/auth/delivery_login_screen.dart';
import 'screens/dashboard/delivery_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RebestaDeliveryApp());
}

class RebestaDeliveryApp extends StatelessWidget {
  const RebestaDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'REBESTA Delivery',

      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor:
            const Color(0xFFFFF8F2),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF8F2),
          foregroundColor: Color(0xFF2A1D1A),
          elevation: 0,
        ),
      ),

      home: const _StartupScreen(),
    );
  }
}

// ============================================================
// STARTUP SCREEN
// ============================================================

class _StartupScreen extends StatefulWidget {
  const _StartupScreen();

  @override
  State<_StartupScreen> createState() =>
      _StartupScreenState();
}

class _StartupScreenState
    extends State<_StartupScreen> {

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn =
        await DeliveryAuthStorage.isLoggedIn();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => loggedIn
            ? const DeliveryDashboardScreen()
            : const DeliveryLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF8F2),

      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      ),
    );
  }
}
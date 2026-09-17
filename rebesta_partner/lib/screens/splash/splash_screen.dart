import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/partner_auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkSession();
  }

  // ============================================================
  // CHECK LOGIN SESSION
  // ============================================================

  Future<void> _checkSession() async {
    // Keep splash visible for 3 seconds.
    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    try {
      final isLoggedIn =
          await PartnerAuthService.isLoggedIn();

      if (!mounted) return;

      debugPrint('================================');
      debugPrint('🔐 PARTNER AUTH CHECK');
      debugPrint(
        'Logged In: $isLoggedIn',
      );
      debugPrint('================================');

      if (isLoggedIn) {
        debugPrint(
          '✅ Partner session found',
        );
        debugPrint(
          '➡️ Opening Partner Dashboard',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const DashboardScreen(),
          ),
        );
      } else {
        debugPrint(
          '❌ No partner session found',
        );
        debugPrint(
          '➡️ Opening Login',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '❌ PARTNER AUTH CHECK ERROR: $e',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffFF5A1F),
              Color(0xffFF7A00),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/logo/rebesta_logo.png",
              width: 170,
            ),

            const SizedBox(height: 28),

            const Text(
              "Partner",
              style: TextStyle(
                fontFamily: "Poppins",
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Manage your restaurant smarter",
              style: TextStyle(
                fontFamily: "Poppins",
                color: Colors.white70,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 70),

            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
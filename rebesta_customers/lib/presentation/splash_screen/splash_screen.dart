import '../../services/auth_service.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _floatController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );

    _floatAnimation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations.
    _fadeController.forward();
    _scaleController.forward();
    _floatController.repeat(reverse: true);

    // Navigate to Login after splash.
    _navigateToLogin();
  }
Future<void> _navigateToLogin() async {
  await Future.delayed(
    const Duration(milliseconds: 2500),
  );

  if (!mounted) return;

  final authService = AuthService();

  final isLoggedIn = await authService.isLoggedIn();

  if (!mounted) return;

  if (isLoggedIn) {
    context.go(AppRoutes.homeScreen);
  } else {
    context.go(AppRoutes.loginScreen);
  }
}

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _floatController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8A00),
              Color(0xFFFF5A1F),
              Color(0xFFFF3D00),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _fadeController,
            _scaleController,
            _floatController,
          ]),
          builder: (context, child) {
            return Center(
              child: Transform.translate(
                offset: Offset(
                  0,
                  _floatAnimation.value,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Text(
                      'Rebesta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 74,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        shadows: [
                          Shadow(
                            color: Colors.white24,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


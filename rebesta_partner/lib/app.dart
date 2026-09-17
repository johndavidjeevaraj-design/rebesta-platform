import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class RebestaPartnerApp extends StatelessWidget {
  const RebestaPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Rebesta Partner",
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
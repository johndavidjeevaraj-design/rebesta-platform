// THEME LOCK: light — source: domain signal (consumer food app)
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryContainer = Color(0xFFFFE8DC);
  static const Color secondary = Color(0xFF2D9CDB);
  static const Color secondaryContainer = Color(0xFFD6EEFA);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color errorColor = Color(0xFFEF4444);

  // Light surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF7F8FA);
  static const Color backgroundLight = Color(0xFFF2F4F7);
  static const Color outlineLight = Color(0xFFE5E7EB);
  static const Color mutedText = Color(0xFF9CA3AF);
  static const Color bodyText = Color(0xFF374151);
  static const Color headlineText = Color(0xFF111827);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF1E2028);
  static const Color backgroundDark = Color(0xFF13141A);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF7A2800),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF0A3D5C),
      surface: surfaceLight,
      onSurface: headlineText,
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: bodyText,
      error: errorColor,
      onError: Colors.white,
      outline: outlineLight,
      outlineVariant: Color(0xFFF3F4F6),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: headlineText,
      ),
      displayMedium: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: headlineText,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: headlineText,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: headlineText,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: headlineText,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: headlineText,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: headlineText,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: headlineText,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: bodyText,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: bodyText,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedText,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: headlineText,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: headlineText,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: headlineText,
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: headlineText,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primary,
      labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outlineLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outlineLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    extensions: [],
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF7A2800),
      onPrimaryContainer: Color(0xFFFFDBCC),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF0A3D5C),
      onSecondaryContainer: Color(0xFFD6EEFA),
      surface: surfaceDark,
      onSurface: Color(0xFFE8E8E8),
      surfaceContainerHighest: Color(0xFF2A2B35),
      onSurfaceVariant: Color(0xFFB0B4BE),
      error: Color(0xFFCF6679),
      onError: Colors.white,
      outline: Color(0xFF3A3D4A),
      outlineVariant: Color(0xFF2A2B35),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
  );

  // Helper: card shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(15),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withAlpha(8),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get pillNavShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(31),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
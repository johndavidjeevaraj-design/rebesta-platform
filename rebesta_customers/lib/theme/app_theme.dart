// Customer app theme — Rebesta food delivery design system.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand
  static const Color primary = Color(0xFFF45A24);
  static const Color primaryContainer = Color(0xFFFFE7DC);
  static const Color secondary = Color(0xFF18794E);
  static const Color secondaryContainer = Color(0xFFDDF3E7);

  // Semantic
  static const Color success = Color(0xFF18794E);
  static const Color successContainer = Color(0xFFDDF3E7);
  static const Color warning = Color(0xFFA96508);
  static const Color warningContainer = Color(0xFFFFF1D6);
  static const Color errorColor = Color(0xFFC93636);

  // Light surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F2ED);
  static const Color backgroundLight = Color(0xFFF7F7F2);
  static const Color outlineLight = Color(0xFFE5E9E4);
  static const Color mutedText = Color(0xFF68736D);
  static const Color bodyText = Color(0xFF46514B);
  static const Color headlineText = Color(0xFF17211D);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF202923);
  static const Color backgroundDark = Color(0xFF111914);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF762B0C),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF104C31),
      surface: surfaceLight,
      onSurface: headlineText,
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: bodyText,
      error: errorColor,
      onError: Colors.white,
      outline: outlineLight,
      outlineVariant: Color(0xFFF0F2ED),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w700, color: headlineText),
      displayMedium: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w700, color: headlineText),
      headlineLarge: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: headlineText),
      headlineMedium: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w600, color: headlineText),
      headlineSmall: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: headlineText),
      titleLarge: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: headlineText),
      titleMedium: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: headlineText),
      titleSmall: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: headlineText),
      bodyLarge: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: bodyText),
      bodyMedium: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: bodyText),
      bodySmall: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: mutedText),
      labelLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: headlineText),
      labelMedium: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: headlineText),
      labelSmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: headlineText),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: headlineText),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: outlineLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: outlineLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.transparent, elevation: 0),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF762B0C),
      onPrimaryContainer: Color(0xFFFFE7DC),
      secondary: Color(0xFF65C58E),
      onSecondary: Color(0xFF082B19),
      secondaryContainer: Color(0xFF104C31),
      onSecondaryContainer: Color(0xFFDDF3E7),
      surface: surfaceDark,
      onSurface: Color(0xFFEAF0EB),
      surfaceContainerHighest: Color(0xFF2B362F),
      onSurfaceVariant: Color(0xFFC0CBC3),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      outline: Color(0xFF59665D),
      outlineVariant: Color(0xFF39463D),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 18, offset: const Offset(0, 5)),
    BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get pillNavShadow => [
    BoxShadow(color: Colors.black.withAlpha(28), blurRadius: 24, offset: const Offset(0, 8)),
  ];
}

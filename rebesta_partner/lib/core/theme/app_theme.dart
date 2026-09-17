import 'package:flutter/material.dart';


class AppTheme {
  static const Color primary = Color(0xFFFF5A1F);
  static const Color secondary = Color(0xFFFF6A00);

  static const Color background = Color(0xFFF8F9FB);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
    ),

    textTheme: const TextTheme().apply(
      fontFamily: 'Poppins',
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: background,
      foregroundColor: Colors.black,
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    ),
  );
}
/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF00FF); // Magenta Neon
  static const Color secondaryColor = Colors.cyanAccent;
  static const Color backgroundDark = Color(0xFF0F0425); // Premium Divine Background
  static const Color backgroundLight = Color(0xFF1A1A1A);
  static const Color surfaceDark = Color(0xFF121212);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  static const Color backgroundGradientStart = Color(0xFF2D0036); // Deep Purple
  static const Color backgroundGradientEnd = Colors.black;

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Colors.purpleAccent, Colors.deepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const BoxDecoration meshGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2D0036), Colors.black, Color(0xFF001220)],
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
    ),
    useMaterial3: true,
    fontFamily: 'Poppins',
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textPrimary,
    ),
    useMaterial3: true,
    fontFamily: 'Poppins', // Assuming font
  );

  static final OutlineInputBorder inputBorderActive = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: primaryColor, width: 2),
  );

  static ButtonStyle ctaElevated(Color bg, Color shadow) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 10,
      shadowColor: shadow,
    );
  }

  static ButtonStyle ctaOutlined(Color fg) {
    return OutlinedButton.styleFrom(
      foregroundColor: fg,
      side: BorderSide(color: fg),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}

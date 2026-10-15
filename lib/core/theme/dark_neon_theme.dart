import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DarkNeonTheme {
  // Brand Palette
  static const Color scaffoldBackground = Color(0xFF0A0A10);
  static const Color cardSurface = Color(0xFF12121E);
  static const Color cardSurfaceLight = Color(0xFF1A1A2E);
  static const Color primaryNeon = Color(0xFF00E5FF);      // Electric Cyan
  static const Color secondaryNeon = Color(0xFFFF007F);    // Cyber Magenta
  static const Color creatorAccent = Color(0xFF00FF87);    // Neon Lime
  static const Color warningNeon = Color(0xFFFFB800);      // Neon Amber
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8E95B3);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Box Shadows
  static List<BoxShadow> neonGlow(Color accentColor, {double blur = 20, double spread = 2, double opacity = 0.65}) {
    return [
      BoxShadow(
        color: accentColor.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> subtleGlow(Color accentColor) {
    return [
      BoxShadow(
        color: accentColor.withOpacity(0.25),
        blurRadius: 12,
        spreadRadius: 1,
      ),
    ];
  }

  // Theme Data
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: cardSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: primaryNeon),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardSurface,
        selectedItemColor: primaryNeon,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder, width: 1.2),
        ),
      ),
    );
  }
}

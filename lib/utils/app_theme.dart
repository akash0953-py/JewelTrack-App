// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Dark theme palette (maroon + gold) ────────────────────────
  static const Color primaryMaroon = Color(0xFF6A0D25);
  static const Color deepMaroon    = Color(0xFF4A0A1A);
  static const Color lightMaroon   = Color(0xFF8A1C3A);

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGold   = Color(0xFFFFE082);

  static const Color darkBg    = Color(0xFF14090C);
  static const Color cardBg    = Color(0xFF1F0D12);
  static const Color surfaceBg = Color(0xFF2A1419);

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFDDDDDD);

  static const Color greenDot  = Color(0xFF4CAF7D);
  static const Color yellowDot = Color(0xFFFFC107);
  static const Color redDot    = Color(0xFFE05252);

  static const Color divider = Color(0xFF3A1A22);

  // ── Light theme palette (white + blue) ────────────────────────
  static const Color lightPrimary       = Color(0xFF1565C0); // deep blue
  static const Color lightAccent        = Color(0xFF1E88E5); // medium blue
  static const Color lightBg            = Color(0xFFFFFFFF);
  static const Color lightCardBg        = Color(0xFFFFFFFF);
  static const Color lightSurfaceBg     = Color(0xFFF3F6FB);
  static const Color lightDivider       = Color(0xFFDDE5F0);
  static const Color lightTextPrimary   = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF5A6A85);

  // ── Dark ThemeData ─────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryGold,
      secondary: lightGold,
      surface: cardBg,
      background: darkBg,
      onPrimary: darkBg,
      onSurface: textPrimary,
      error: redDot,
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge:  GoogleFonts.lato(color: textPrimary),
      bodyMedium: GoogleFonts.lato(color: textSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryMaroon,
      elevation: 0,
      titleTextStyle: GoogleFonts.roboto(
          color: primaryGold, fontSize: 20, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: primaryGold),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryGold.withOpacity(0.2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceBg,
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: darkBg,
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryMaroon,
      selectedItemColor: primaryGold,
      unselectedItemColor: textSecondary,
    ),
  );

  // ── Light ThemeData (WHITE + BLUE) ─────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightAccent,
      surface: lightCardBg,
      background: lightBg,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      error: redDot,
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme).copyWith(
      bodyLarge:  GoogleFonts.lato(color: lightTextPrimary),
      bodyMedium: GoogleFonts.lato(color: lightTextSecondary),
      bodySmall:  GoogleFonts.lato(color: lightTextSecondary, fontSize: 12),
      titleSmall: GoogleFonts.lato(color: lightTextPrimary, fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightPrimary,
      elevation: 0,
      titleTextStyle: GoogleFonts.roboto(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: lightCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightDivider),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceBg,
      labelStyle: const TextStyle(color: lightTextSecondary),
      hintStyle: const TextStyle(color: lightTextSecondary),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary, width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightPrimary,
        side: const BorderSide(color: lightPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1, space: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightPrimary,
      selectedItemColor: Colors.white,
      unselectedItemColor: Color(0xAAFFFFFF),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
    ),
  );

  // ── Context-aware helpers ─────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? cardBg : lightCardBg;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? surfaceBg : lightSurfaceBg;

  static Color dividerColor(BuildContext context) =>
      isDark(context) ? divider : lightDivider;

  /// The "accent/primary" colour: gold in dark, blue in light.
  static Color accentColor(BuildContext context) =>
      isDark(context) ? primaryGold : lightPrimary;
}

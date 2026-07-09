import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Primary ──
  static const primary = Color(0xFF02929A);
  static const primaryDark = Color(0xFF017179);
  static const primaryLight = Color(0xFFDAEFF0);

  // ── Aliases for backward compatibility ──
  static const blue = primary;
  static const blueLight = primaryLight;

  // ── Backgrounds ──
  static const background = Color(0xFFF5F6F8);
  static const ice = background;
  static const white = Color(0xFFFFFFFF);

  // ── Text ──
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF475467);
  static const muted = Color(0xFF98A2B3);
  static const navy = Color(0xFF1D2939);
  static const slate = Color(0xFF344054);

  // ── Borders & Dividers ──
  static const line = Color(0xFFD0D5DD);

  // ── Status badges ──
  // Diterima
  static const amber = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFEF3C7);
  // Diproses
  static const proses = Color(0xFF3B82F6);
  static const prosesBg = Color(0xFFDBEAFE);
  // Selesai
  static const green = Color(0xFF10B981);
  static const greenBg = Color(0xFFD1FAE5);
  // Darurat
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEE2E2);

  // ── Gradients ──
  static const buttonTop = Color(0xFF00BECA);
  static const headerEnd = Color(0xFF71B8BC);

  // ── Field ──
  static const fieldBorder = Color(0xFFBACECF);

  // ── Misc ──
  static const star = Color(0xFFF2B200);
  static const overlay = Color(0x1A000000);
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double pill = 999;

  static BorderRadius get smBr => BorderRadius.circular(sm);
  static BorderRadius get mdBr => BorderRadius.circular(md);
  static BorderRadius get lgBr => BorderRadius.circular(lg);
  static BorderRadius get xlBr => BorderRadius.circular(xl);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,

      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.slate,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13.5,
          color: AppColors.slate,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11.5,
          color: AppColors.muted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 0.6,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgBr,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlBr,
          side: const BorderSide(color: AppColors.line),
        ),
        margin: const EdgeInsets.only(bottom: 10),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: GoogleFonts.inter(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

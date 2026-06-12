import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette
  // Primary: Indigo/Slate for a professional, deep look
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF818CF8); // Indigo 400
  
  // Secondary: Coral/Salmon for warmth and call-to-actions
  static const Color secondaryLight = Color(0xFFFF7F50);
  static const Color secondaryDark = Color(0xFFFFAB91);

  // Backgrounds: Soft, not stark white/black
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Colors.white;
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E293B); // Slate 800
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  // Status Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Quadrant Colors (Pastel/Soft)
  static const Color q1ImportantUrgent = Color(0xFFFF6B6B);
  static const Color q2ImportantNotUrgent = Color(0xFF4ECDC4);
  static const Color q3NotImportantUrgent = Color(0xFFFFD93D);
  static const Color q4NotImportantNotUrgent = Color(0xFF95A5A6);

  static TextTheme _buildTextTheme(TextTheme base, Color primary, Color secondary) {
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 32,
        letterSpacing: -1.0,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      bodyLarge: GoogleFonts.inter(
        color: primary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: secondary,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    
    return base.copyWith(
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        onError: Colors.white,
        outline: Color(0xFFE2E8F0), // Slate 200
      ),
      textTheme: _buildTextTheme(
        base.textTheme,
        textPrimaryLight,
        textSecondaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimaryLight),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: primaryLight,
        unselectedItemColor: textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
        color: Color(0xFFE2E8F0),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    
    return base.copyWith(
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        onError: Colors.white,
        outline: Color(0xFF334155), // Slate 700
      ),
      textTheme: _buildTextTheme(
        base.textTheme,
        textPrimaryDark,
        textSecondaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimaryDark),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimaryDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        elevation: 0,
        selectedItemColor: primaryDark,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
       dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
        color: Color(0xFF334155),
      ),
    );
  }
}
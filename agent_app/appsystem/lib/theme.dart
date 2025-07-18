import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional Real Estate App Theme
/// Features:
/// - Dark gradient background
/// - White text for contrast
/// - Green accent color (#4CAF50)
/// - Arabic RTL support
/// - Professional and clean design
/// - Responsive layout support

class AppTheme {
  // Professional color scheme
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color cardBackground = Color(0xFF2A2A2A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF404040);

  // Border radius for consistent design
  static const double borderRadius = 12.0;

  // Safe Google Fonts text theme with Arabic support
  static TextTheme getSafeTextTheme() {
    try {
      return GoogleFonts.notoSansTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSans(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displayMedium: GoogleFonts.notoSans(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        displaySmall: GoogleFonts.notoSans(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        titleLarge: GoogleFonts.notoSans(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        titleMedium: GoogleFonts.notoSans(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: textWhite,
        ),
        titleSmall: GoogleFonts.notoSans(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: textWhite,
        ),
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: textWhite,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: textWhite,
        ),
        bodySmall: GoogleFonts.notoSans(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: textGrey,
        ),
        labelLarge: GoogleFonts.notoSans(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        labelMedium: GoogleFonts.notoSans(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: textWhite,
        ),
        labelSmall: GoogleFonts.notoSans(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: textGrey,
        ),
      );
    } catch (e) {
      // Fallback to system fonts if Google Fonts fails
      return const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        displayMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        displaySmall: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        titleLarge: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        titleMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        titleSmall: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        bodySmall: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: textGrey,
          fontFamily: 'Roboto',
        ),
        labelLarge: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        labelMedium: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: textWhite,
          fontFamily: 'Roboto',
        ),
        labelSmall: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: textGrey,
          fontFamily: 'Roboto',
        ),
      );
    }
  }

  ThemeData getTheme() {
    final textTheme = getSafeTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: textTheme,

      // Dark gradient scaffold background
      scaffoldBackgroundColor: darkBackground,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textWhite,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textWhite),
        toolbarHeight: 64,
      ),

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: primaryGreen,
        surface: cardBackground,
        background: darkBackground,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textWhite,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textWhite,
          elevation: 2,
          shadowColor: primaryGreen.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(120, 48),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(120, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textGrey),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textGrey),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: textWhite, size: 24),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        tileColor: cardBackground,
        textColor: textWhite,
        iconColor: textWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: cardBackground,
        selectedColor: primaryGreen.withOpacity(0.2),
        disabledColor: cardBackground,
        labelStyle: textTheme.bodySmall?.copyWith(color: textWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: textWhite,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textWhite,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textWhite),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBackground,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        actionTextColor: primaryGreen,
      ),
    );
  }
}

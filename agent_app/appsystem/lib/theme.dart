import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blue and Orange Theme Colors
class AppColors {
  // Primary Blue Colors
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryBlueLight = Color(0xFF42A5F5);
  static const Color primaryBlueDark = Color(0xFF0D47A1);
  
  // Secondary Orange Colors
  static const Color secondaryOrange = Color(0xFFFF9800);
  static const Color secondaryOrangeLight = Color(0xFFFFB74D);
  static const Color secondaryOrangeDark = Color(0xFFE65100);
  
  // Accent Colors
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentOrange = Color(0xFFFF5722);
  
  // Neutral Colors
  static const Color neutralGrey = Color(0xFF757575);
  static const Color neutralLightGrey = Color(0xFFBDBDBD);
  static const Color neutralDarkGrey = Color(0xFF424242);
  
  // Success/Error Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color infoBlue = Color(0xFF2196F3);
}

/// Theme Provider for managing dark/light mode
class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;
  ThemeProvider._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}

class AppTheme {
  var borderRadius = BorderRadius.circular(12);
  
  InputBorder getBorder({Color color = AppColors.primaryBlue, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Get the complete theme based on brightness
  ThemeData getTheme({Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      
      // Color Scheme
      colorScheme: isDark ? _getDarkColorScheme() : _getLightColorScheme(),
      
      // Primary Color
      primaryColor: AppColors.primaryBlue,
      primarySwatch: _createMaterialColor(AppColors.primaryBlue),
      
      // Text Theme
      textTheme: _getTextTheme(brightness),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: isDark ? 4 : 2,
        shadowColor: isDark ? Colors.black : Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        border: getBorder(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        enabledBorder: getBorder(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        focusedBorder: getBorder(color: AppColors.primaryBlue, width: 2),
        errorBorder: getBorder(color: AppColors.errorRed),
        focusedErrorBorder: getBorder(color: AppColors.errorRed, width: 2),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(64, 48),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: BorderSide(color: AppColors.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(64, 48),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(64, 48),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
        disabledColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        secondaryLabelStyle: TextStyle(
          color: AppColors.primaryBlue,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedTileColor: AppColors.primaryBlue.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }
          return isDark ? Colors.grey.shade400 : Colors.grey.shade300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue.withValues(alpha: 0.5);
          }
          return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryBlue,
        inactiveTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        thumbColor: AppColors.primaryBlue,
        overlayColor: AppColors.primaryBlue.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.primaryBlue,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
        linearTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        circularTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        elevation: 6,
        actionTextColor: AppColors.primaryBlue,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          fontSize: 14,
        ),
      ),
      
      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        scrimColor: Colors.black54,
        elevation: 16,
      ),
      
      // Navigation Rail Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedIconTheme: IconThemeData(color: AppColors.primaryBlue),
        unselectedIconTheme: IconThemeData(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  /// Get light color scheme
  ColorScheme _getLightColorScheme() {
    return const ColorScheme.light(
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryOrange,
      onSecondary: Colors.white,
      tertiary: AppColors.accentBlue,
      onTertiary: Colors.white,
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1C1B1F),
      surfaceContainerHighest: Color(0xFFF5F5F5),
      onSurfaceVariant: Color(0xFF49454F),
      outline: Color(0xFF79747E),
      outlineVariant: Color(0xFFCAC4D0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF313033),
      onInverseSurface: Color(0xFFF4EFF4),
      inversePrimary: AppColors.primaryBlueLight,
      surfaceTint: AppColors.primaryBlue,
    );
  }

  /// Get dark color scheme
  ColorScheme _getDarkColorScheme() {
    return const ColorScheme.dark(
      primary: AppColors.primaryBlueLight,
      onPrimary: Colors.black,
      secondary: AppColors.secondaryOrangeLight,
      onSecondary: Colors.black,
      tertiary: AppColors.accentBlue,
      onTertiary: Colors.white,
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF2A2A2A),
      onSurfaceVariant: Color(0xFFCAC4D0),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6E1E5),
      onInverseSurface: Color(0xFF313033),
      inversePrimary: AppColors.primaryBlueDark,
      surfaceTint: AppColors.primaryBlueLight,
    );
  }

  /// Get text theme based on brightness
  TextTheme _getTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
    );
  }

  /// Create Material Color from a single color
  MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = (color.r * 255.0).round() & 0xff;
    final int g = (color.g * 255.0).round() & 0xff;
    final int b = (color.b * 255.0).round() & 0xff;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }

  /// Legacy method for backward compatibility
  ThemeData getLegacyTheme({
    Brightness brightness = Brightness.light,
    Color color = AppColors.primaryBlue,
  }) {
    return getTheme(brightness: brightness);
  }
}

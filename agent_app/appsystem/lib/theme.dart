import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  var borderRadius = BorderRadius.circular(12);
  InputBorder getBorder({Color color = Colors.green, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static final lightModeTheme = ThemeData(
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: Colors.green,
    hintColor: Color(0x4681DD),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      //   displayLarge: TextStyle(
      //     fontSize: 22.0,
      //     fontWeight: FontWeight.w500,
      //     color: Colors.black,
      //   ),
      //   displayMedium: TextStyle(
      //     fontSize: 20.0,
      //     fontWeight: FontWeight.w600,
      //     color: Colors.black87,
      //   ),
      //   displaySmall: TextStyle(
      //     fontSize: 18.0,
      //     fontWeight: FontWeight.w600,
      //     color: Colors.black54,
      //   ),
      //   titleMedium: TextStyle(
      //     fontSize: 14.0,
      //     fontWeight: FontWeight.w500,
      //     color: Colors.black87,
      //   ),
      //   bodyLarge: TextStyle(
      //     fontSize: 14.0,
      //     fontWeight: FontWeight.normal,
      //     color: Colors.grey,
      //   ),
      //   labelLarge: TextStyle(
      //     fontSize: 16.0,
      //     fontWeight: FontWeight.w600,
      //     color: Colors.white,
      //   ),
      //   labelMedium: TextStyle(
      //     fontSize: 12.0,
      //     fontWeight: FontWeight.normal,
      //     color: Colors.white,
      //   ),
      //   bodySmall: TextStyle(
      //     fontSize: 12.0,
      //     fontWeight: FontWeight.normal,
      //     color: Colors.grey,
      //   ),
      // ),
    ),
  );

  getTheme({
    Brightness brightness = Brightness.dark,
    Color color = Colors.green,
  }) {
    var g = ColorScheme.fromSeed(seedColor: color, brightness: brightness);
    return ThemeData(
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        // Ensure proper text colors for good contrast
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: brightness == Brightness.dark
              ? Colors.white60
              : Colors.black45,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: brightness == Brightness.dark
              ? Colors.white60
              : Colors.black45,
        ),
      ),
      // snackbar
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: GoogleFonts.balooBhaijaan2TextTheme(
          const TextTheme(
            bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
          ),
        ).bodyLarge,
        behavior: SnackBarBehavior.floating,
        width: 350,
        insetPadding: const EdgeInsets.all(16),
        showCloseIcon: true,
        closeIconColor: Colors.grey,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
      ),
      // color scheme
      colorScheme: g,
      // colorScheme: brightness == Brightness.light
      //     ? ColorScheme.light(
      //         primary: color,
      //         onPrimary: Colors.white,
      //         secondary: color,
      //         onSecondary: Colors.white,
      //       )
      //     : ColorScheme.dark(
      //         // primary: Colors.white,
      //         primary: color,
      //         onPrimary: Colors.black,
      //       ),
      // // inputs
      inputDecorationTheme: InputDecorationTheme(
        alignLabelWithHint: true,
        // contentPadding: EdgeInsets.zero,
        constraints: const BoxConstraints(minHeight: 0),
        errorStyle: GoogleFonts.balooBhaijaan2TextTheme(
          const TextTheme(
            bodyLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          ),
        ).bodyLarge,
        enabledBorder: getBorder(color: Colors.grey.withOpacity(.1)),
        focusedBorder: getBorder(color: color, width: 2),
        errorBorder: getBorder(color: Colors.red),
        focusedErrorBorder: getBorder(color: Colors.red, width: 2),
        // outlineBorder: BorderSide(color: color),
        disabledBorder: getBorder(color: Colors.grey.withOpacity(0.1)),
        activeIndicatorBorder: BorderSide(color: Colors.red),
        filled: true,
        fillColor: Colors.grey.withOpacity(.2),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: Colors.transparent,
      ),
      dividerColor: Colors.grey.withOpacity(0.25),
      dividerTheme: DividerThemeData(
        space: 0,
        thickness: 1,
        color: Colors.grey.withOpacity(0.25),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: color,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      // floatingActionButtonTheme: FloatingActionButtonThemeData(
      //   backgroundColor: color,
      //   foregroundColor: Colors.white,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: borderRadius,
      //   ),
      // ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 3,
      ),
      // chips
      chipTheme: ChipThemeData(
        pressElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        brightness: brightness,
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
    );
  }
}

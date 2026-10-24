import 'package:flutter/material.dart';

class AppTheme {
  // Brand Palette from User Specification:
  static const Color yinMnBlue = Color(0xFF3D5A80);     // #3D5A80 - Deep Slate / YInMn Blue (Primary)
  static const Color powderBlue = Color(0xFF98C1D9);    // #98C1D9 - Soft Powder Blue (Secondary)
  static const Color lightCyan = Color(0xFFE0FBFC);     // #E0FBFC - Fresh Light Cyan (Surface/Pill Highlight)
  static const Color burntSienna = Color(0xFFEE6C4D);   // #EE6C4D - Warm Terracotta / Burnt Sienna (Accent/Alert)
  static const Color gunmetal = Color(0xFF293241);      // #293241 - Deep Gunmetal (Typography & Dark)

  // Primary semantic roles:
  static const Color primary = yinMnBlue;
  static const Color secondary = powderBlue;
  static const Color accent = burntSienna;
  static const Color surfaceAccent = lightCyan;
  static const Color dark = gunmetal;

  // Status & payment semantics:
  static const Color targetReachedColor = yinMnBlue;
  static const Color targetShortfallColor = burntSienna;
  static const Color cashColor = yinMnBlue;
  static const Color electronicColor = Color(0xFF3A506B);

  // Status badges:
  static const Color statusPaid = yinMnBlue;
  static const Color statusPartial = Color(0xFF5B8296);
  static const Color statusUnpaid = burntSienna;

  // Backgrounds & Surfaces:
  static const Color backgroundLight = Color(0xFFF3F8FB); // Pristine light surface with subtle cyan undertone
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = gunmetal;          // #293241 for superior contrast and elegance
  static const Color textSecondaryLight = Color(0xFF5B6E7A);
  static const Color cardBorderLight = Color(0xFFD6E4EB);

  static const Color backgroundDark = Color(0xFF1E2530);    // Deep gunmetal shade
  static const Color cardDark = Color(0xFF242E3D);
  static const Color textPrimaryDark = lightCyan;          // #E0FBFC
  static const Color textSecondaryDark = powderBlue;       // #98C1D9
  static const Color cardBorderDark = Color(0xFF364456);

  // Backward compatibility aliases:
  static const Color primaryGreen = yinMnBlue;
  static const Color primaryLight = powderBlue;
  static const Color primaryDark = gunmetal;
  static const Color secondaryGold = burntSienna;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: yinMnBlue,
        onPrimary: Colors.white,
        secondary: burntSienna,
        onSecondary: Colors.white,
        surface: cardLight,
        onSurface: gunmetal,
        error: burntSienna,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: gunmetal,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: gunmetal,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: gunmetal),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0.5,
        shadowColor: gunmetal.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderLight, width: 1.0),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: burntSienna,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yinMnBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: yinMnBlue,
          side: const BorderSide(color: powderBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: yinMnBlue, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: lightCyan,
        side: const BorderSide(color: cardBorderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 13, color: gunmetal),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: lightCyan,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: yinMnBlue);
          }
          return const IconThemeData(color: Color(0xFF64748B));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: yinMnBlue,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Color(0xFF64748B),
          );
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: powderBlue,
        onPrimary: gunmetal,
        secondary: burntSienna,
        onSecondary: Colors.white,
        surface: cardDark,
        onSurface: lightCyan,
        error: burntSienna,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: lightCyan,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightCyan,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderDark, width: 0.8),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: burntSienna,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: powderBlue,
          foregroundColor: gunmetal,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

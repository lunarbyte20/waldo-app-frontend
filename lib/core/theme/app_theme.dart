import 'package:flutter/material.dart';

class AppTheme {
  // Backend waldoLight Color Palette
  static const Color primaryLight = Color(0xFF2C4A7C);
  static const Color secondaryLight = Color(0xFF5B6B7C);
  static const Color accentLight = Color(0xFF3E6FA8);
  static const Color neutralLight = Color(0xFF2D333B);
  static const Color base100Light = Color(0xFFFFFFFF);
  static const Color base200Light = Color(0xFFF3F4F6);
  static const Color base300Light = Color(0xFFE5E7EB);
  static const Color successLight = Color(0xFF3D7A5C);
  static const Color warningLight = Color(0xFFB8863D);
  static const Color errorLight = Color(0xFFB8493D);

  // Backend waldoDark Color Palette
  static const Color primaryDark = Color(0xFF4A72AC);
  static const Color secondaryDark = Color(0xFF8A97A6);
  static const Color accentDark = Color(0xFF6B9AD1);
  static const Color neutralDark = Color(0xFF1C2128);
  static const Color base100Dark = Color(0xFF1A1E24);
  static const Color base200Dark = Color(0xFF12161C);
  static const Color base300Dark = Color(0xFF2D333B);
  static const Color successDark = Color(0xFF5A9B79);
  static const Color warningDark = Color(0xFFD1A05C);
  static const Color errorDark = Color(0xFFD1685C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: base100Light,
        error: errorLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: neutralLight,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: base200Light,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base100Light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: base300Light),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: base300Light),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: base100Light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: base300Light, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: base300Light,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: base100Dark,
        error: errorDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: base200Dark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: base100Dark,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base100Dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: base300Dark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: base300Dark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: base100Dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: base300Dark, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: base300Dark,
        thickness: 1,
      ),
    );
  }
}

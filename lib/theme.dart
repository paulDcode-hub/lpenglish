import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF121212);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color text = Color(0xFFE6E6E6);
  static const Color muted = Color(0xFF9A9A9A);
  static const Color accent = Color(0xFF4FC3F7);
  static const Color error = Color(0xFFE57373);
  static const Color ok = Color(0xFF81C784);

  static final ThemeData dark = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    cardColor: card,
    dividerColor: border,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: card,
      error: error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: text,
      onError: Colors.black,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: text, fontSize: 20),
      titleMedium: TextStyle(color: text, fontSize: 16),
      bodyLarge: TextStyle(color: text, fontSize: 16),
      bodyMedium: TextStyle(color: text, fontSize: 16),
      bodySmall: TextStyle(color: muted, fontSize: 14),
      labelLarge: TextStyle(color: text, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: _inputBorder(border),
      enabledBorder: _inputBorder(border),
      focusedBorder: _inputBorder(accent),
      errorBorder: _inputBorder(error),
      focusedErrorBorder: _inputBorder(error),
      hintStyle: const TextStyle(color: muted, fontSize: 14),
      labelStyle: const TextStyle(color: muted, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(accent),
        foregroundColor: const WidgetStatePropertyAll(Colors.black),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(accent),
        elevation: const WidgetStatePropertyAll(0),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(accent),
        side: const WidgetStatePropertyAll(BorderSide(color: border, width: 1)),
        elevation: const WidgetStatePropertyAll(0),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: accent,
      unselectedItemColor: muted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: accent.withValues(alpha: 0.16),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, color: muted),
      ),
      iconTheme: const WidgetStatePropertyAll(IconThemeData(color: muted)),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: color, width: 1),
      );
}
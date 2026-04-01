import 'package:flutter/material.dart';

class NexusColors {
  // Brand Colors
  static const Color teal = Color(0xFF0EC4A0);
  static const Color amber = Color(0xFFF5A524);
  
  // Dark Mode
  static const Color darkBg = Color(0xFF0D0E10);
  static const Color darkSurface = Color(0xFF141519);
  static const Color darkMuted = Color(0xFF1E1F24);
  static const Color darkBorder = Color(0xFF2A2B31);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  
  // Light Mode
  static const Color lightBg = Color(0xFFF7F5F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFFE8E6E1);
  static const Color lightBorder = Color(0xFFE0DED9);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
}

class NexusTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NexusColors.darkBg,
    primaryColor: NexusColors.teal,
    colorScheme: const ColorScheme.dark(
      primary: NexusColors.teal,
      secondary: NexusColors.amber,
      surface: NexusColors.darkSurface,
      background: NexusColors.darkBg,
      onPrimary: NexusColors.darkBg,
      onSecondary: NexusColors.darkBg,
      onSurface: NexusColors.darkTextPrimary,
      onBackground: NexusColors.darkTextPrimary,
    ),
    fontFamily: 'DM Sans',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: NexusColors.darkTextPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: NexusColors.darkTextPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: NexusColors.darkTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: NexusColors.darkTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: NexusColors.darkTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: NexusColors.darkTextSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: NexusColors.darkTextPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: NexusColors.darkTextSecondary,
      ),
    ),
    cardTheme: CardThemeData(
      color: NexusColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NexusColors.darkBg,
      elevation: 0,
      iconTheme: IconThemeData(color: NexusColors.darkTextPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: NexusColors.darkTextPrimary,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: NexusColors.darkSurface,
      selectedItemColor: NexusColors.teal,
      unselectedItemColor: NexusColors.darkTextSecondary,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: NexusColors.lightBg,
    primaryColor: NexusColors.teal,
    colorScheme: const ColorScheme.light(
      primary: NexusColors.teal,
      secondary: NexusColors.amber,
      surface: NexusColors.lightSurface,
      background: NexusColors.lightBg,
      onPrimary: Colors.white,
      onSecondary: NexusColors.lightTextPrimary,
      onSurface: NexusColors.lightTextPrimary,
      onBackground: NexusColors.lightTextPrimary,
    ),
    fontFamily: 'DM Sans',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: NexusColors.lightTextPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: NexusColors.lightTextPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: NexusColors.lightTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: NexusColors.lightTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: NexusColors.lightTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: NexusColors.lightTextSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: NexusColors.lightTextPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: NexusColors.lightTextSecondary,
      ),
    ),
    cardTheme: CardThemeData(
      color: NexusColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NexusColors.lightBg,
      elevation: 0,
      iconTheme: IconThemeData(color: NexusColors.lightTextPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: NexusColors.lightTextPrimary,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: NexusColors.lightSurface,
      selectedItemColor: NexusColors.teal,
      unselectedItemColor: NexusColors.lightTextSecondary,
    ),
  );
}

// Dynamic color helper - returns appropriate color based on theme
class DynamicColors {
  final bool isDark;
  
  DynamicColors(this.isDark);
  
  Color get textPrimary => isDark 
      ? NexusColors.darkTextPrimary 
      : NexusColors.lightTextPrimary;
  
  Color get textSecondary => isDark 
      ? NexusColors.darkTextSecondary 
      : NexusColors.lightTextSecondary;
  
  Color get background => isDark 
      ? NexusColors.darkBg 
      : NexusColors.lightBg;
  
  Color get surface => isDark 
      ? NexusColors.darkSurface 
      : NexusColors.lightSurface;
  
  Color get muted => isDark 
      ? NexusColors.darkMuted 
      : NexusColors.lightMuted;
  
  Color get border => isDark 
      ? NexusColors.darkBorder 
      : NexusColors.lightBorder;
}

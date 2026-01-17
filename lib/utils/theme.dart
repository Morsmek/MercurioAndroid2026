import 'package:flutter/material.dart';

/// Mercurio Dark Theme with Orange/Amber Accent
/// Inspired by the Mercurio logo - privacy-focused design
class AppTheme {
  // Colors - Orange/Amber Theme (from Mercurio logo)
  static const Color primaryBlack = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceVariant = Color(0xFF2C2C2C);
  static const Color primaryOrange = Color(0xFFFF8C00);      // Main orange from logo
  static const Color secondaryAmber = Color(0xFFFFB300);     // Lighter amber accent
  static const Color glowOrange = Color(0xFFFF7700);         // Neon glow effect
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFFB0B0B0);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color warningAmber = Color(0xFFFFC107);
  
  // Legacy color aliases (for backward compatibility)
  static const Color primaryCyan = primaryOrange;            // Map cyan to orange
  static const Color secondaryCyan = secondaryAmber;         // Map cyan to amber

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBlack,
      primaryColor: primaryOrange,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: secondaryAmber,
        surface: surfaceDark,
        surfaceContainerHighest: surfaceVariant,
        error: errorRed,
        onPrimary: primaryBlack,
        onSecondary: primaryBlack,
        onSurface: textWhite,
        onError: textWhite,
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlack,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textWhite,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textWhite,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textWhite,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textGray,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: textWhite,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCyan, width: 2),
        ),
        hintStyle: const TextStyle(color: textGray),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: primaryBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryCyan,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: textWhite,
        size: 24,
      ),
      
      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryBlack,
        selectedItemColor: primaryCyan,
        unselectedItemColor: textGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryCyan,
        foregroundColor: primaryBlack,
        elevation: 4,
      ),
    );
  }

  // Message Bubble Colors
  static const Color sentMessageBubble = Color(0xFF1E1E1E);
  static const Color receivedMessageBubble = surfaceVariant;
  
  // Status Colors
  static const Color onlineStatus = successGreen;
  static const Color offlineStatus = textGray;
  
  // Special UI Elements
  static const Color qrCodeBackground = textWhite;
  static const Color sessionIdBackground = surfaceVariant;
  static const Color recoveryPhraseBorder = warningAmber;
}

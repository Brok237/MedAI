// lib/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Primary gradient colors (blue to teal)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryTeal = Color(0xFF06B6D4);
  static const Color primaryGreen = Color(0xFF10B981);

  // Shorthand alias used throughout new screens
  static const Color primary = primaryBlue;

  // Background shorthand alias
  static const Color background = bgLight;

  // Risk colors
  static const Color highRisk = Color(0xFFEF4444);
  static const Color mediumRisk = Color(0xFFF59E0B);
  static const Color lowRisk = Color(0xFF10B981);

  // Background
  static const Color bgLight = Color(0xFFF0F4F8);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgDark = Color(0xFF1E293B);

  // Text
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Card
  static const Color cardBg = Color(0xFFFFFFFF);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryBlue, primaryTeal],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get headerGradientBlue => const LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get headerGradientPurple => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get headerGradientRed => const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get headerGradientGreen => const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: bgLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
}

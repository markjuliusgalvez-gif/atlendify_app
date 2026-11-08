import 'package:flutter/material.dart';

/// Brand colors sampled from the Atlendify logo.
/// The dominant non-white blue is approximately #1E439B (RGB: 30, 67, 155).
class BrandColors {
  static const Color primary = Color(0xFF1E439B);
  static const Color primaryLight = Color(0xFF4A6FA5);
  static const Color primaryDark = Color(0xFF143070);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Status colors (fixed, AA-readable in both themes)
  static const Color presentGreen = Color(0xFF1B8A3A);
  static const Color lateAmber = Color(0xFFF5A623);
  static const Color absentRed = Color(0xFFD0021B);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F2F5);
  static const Color lightOutline = Color(0xFFE0E4EB);
  static const Color lightTextPrimary = Color(0xFF1A1D21);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0E1116);
  static const Color darkSurface = Color(0xFF151A21);
  static const Color darkSurfaceVariant = Color(0xFF1C232D);
  static const Color darkOutline = Color(0xFF2A313B);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Logo tint colors
  static const Color logoTintLight = primary;
  static const Color logoTintDark = Color(0xFF7AA2E8); // lighter blue for dark mode

  static ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryLight.withValues(alpha: 0.15),
    onPrimaryContainer: primaryDark,
    secondary: primaryLight,
    onSecondary: onPrimary,
    tertiary: primaryDark,
    onTertiary: onPrimary,
    error: absentRed,
    onError: onPrimary,
    surface: lightSurface,
    onSurface: lightTextPrimary,
    surfaceContainerHighest: lightBackground,
    outline: lightOutline,
    outlineVariant: lightOutline,
  );

  static ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: primaryLight,
    brightness: Brightness.dark,
    primary: primaryLight,
    onPrimary: Color(0xFF0E1116),
    primaryContainer: primaryDark.withValues(alpha: 0.3),
    onPrimaryContainer: primaryLight,
    secondary: primaryLight,
    onSecondary: Color(0xFF0E1116),
    tertiary: primaryDark,
    onTertiary: onPrimary,
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF0E1116),
    surface: darkSurface,
    onSurface: darkTextPrimary,
    surfaceContainerHighest: darkBackground,
    outline: darkOutline,
    outlineVariant: darkOutline,
  );
}
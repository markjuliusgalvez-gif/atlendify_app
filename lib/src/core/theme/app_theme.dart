import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'brand_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: BrandColors.lightScheme,
      scaffoldBackgroundColor: BrandColors.lightBackground,
      fontFamily: 'Roboto',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: BrandColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.primary,
          side: const BorderSide(color: BrandColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.absentRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.absentRed, width: 2),
        ),
        labelStyle: const TextStyle(color: BrandColors.lightTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: BrandColors.lightTextSecondary, fontSize: 14),
        errorStyle: const TextStyle(color: BrandColors.absentRed, fontSize: 12),
        floatingLabelStyle: const TextStyle(color: BrandColors.primary, fontSize: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: BrandColors.lightTextPrimary),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: BrandColors.lightTextPrimary),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: BrandColors.lightTextPrimary),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: BrandColors.lightTextPrimary),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: BrandColors.lightTextPrimary),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: BrandColors.lightTextPrimary),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: BrandColors.lightTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: BrandColors.lightTextPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: BrandColors.lightTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: BrandColors.lightTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: BrandColors.lightTextPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: BrandColors.lightTextSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BrandColors.lightTextPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BrandColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: BrandColors.lightTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BrandColors.lightSurface,
        selectedItemColor: BrandColors.primary,
        unselectedItemColor: BrandColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandColors.lightOutline,
        selectedColor: BrandColors.primary.withValues(alpha: 0.12),
        disabledColor: BrandColors.lightOutline.withValues(alpha: 0.5),
        labelStyle: const TextStyle(color: BrandColors.lightTextPrimary, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: BrandColors.onPrimary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: const BorderSide(color: BrandColors.lightOutline),
      ),
      dividerTheme: const DividerThemeData(
        color: BrandColors.lightOutline,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BrandColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BrandColors.lightTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: BrandColors.lightTextPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BrandColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        modalBarrierColor: Colors.black54,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BrandColors.darkSurface,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actionTextColor: BrandColors.primaryLight,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: BrandColors.darkScheme,
      scaffoldBackgroundColor: BrandColors.darkBackground,
      fontFamily: 'Roboto',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: BrandColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primaryLight,
          foregroundColor: BrandColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.primaryLight,
          side: const BorderSide(color: BrandColors.primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        labelStyle: const TextStyle(color: BrandColors.darkTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: BrandColors.darkTextSecondary, fontSize: 14),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
        floatingLabelStyle: const TextStyle(color: BrandColors.primaryLight, fontSize: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: BrandColors.darkTextPrimary),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: BrandColors.darkTextPrimary),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: BrandColors.darkTextPrimary),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: BrandColors.darkTextPrimary),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: BrandColors.darkTextPrimary),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: BrandColors.darkTextPrimary),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: BrandColors.darkTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: BrandColors.darkTextPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: BrandColors.darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: BrandColors.darkTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: BrandColors.darkTextPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: BrandColors.darkTextSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BrandColors.darkTextPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BrandColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: BrandColors.darkTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BrandColors.darkSurface,
        selectedItemColor: BrandColors.primaryLight,
        unselectedItemColor: BrandColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandColors.darkOutline,
        selectedColor: BrandColors.primaryLight.withValues(alpha: 0.2),
        disabledColor: BrandColors.darkOutline.withValues(alpha: 0.5),
        labelStyle: const TextStyle(color: BrandColors.darkTextPrimary, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: BrandColors.darkBackground, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: const BorderSide(color: BrandColors.darkOutline),
      ),
      dividerTheme: const DividerThemeData(
        color: BrandColors.darkOutline,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BrandColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BrandColors.darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: BrandColors.darkTextPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BrandColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        modalBarrierColor: Colors.black54,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BrandColors.darkSurface,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actionTextColor: BrandColors.primaryLight,
      ),
    );
  }
}
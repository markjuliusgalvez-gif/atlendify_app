import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'brand_colors.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: BrandColors.lightScheme,
      scaffoldBackgroundColor: BrandColors.lightBackground,
      fontFamily: DesignTokens.fontFamilyPrimary,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
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
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          side: BorderSide.none,
        ),
        margin: EdgeInsets.zero,
        shadowColor: DesignTokens.lightCardShadows.first.color,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          textStyle: DesignTokens.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, DesignTokens.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.primary,
          side: const BorderSide(color: BrandColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space5,
            vertical: DesignTokens.space2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          textStyle: DesignTokens.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, DesignTokens.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          textStyle: DesignTokens.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space5,
          vertical: DesignTokens.space4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: BrandColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: BrandColors.absentRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: BrandColors.absentRed, width: 2),
        ),
        labelStyle: DesignTokens.bodyMedium.copyWith(
          color: BrandColors.lightTextSecondary,
        ),
        hintStyle: DesignTokens.bodyMedium.copyWith(
          color: BrandColors.lightTextSecondary,
        ),
        errorStyle: DesignTokens.labelSmall.copyWith(
          color: BrandColors.absentRed,
        ),
        floatingLabelStyle: DesignTokens.labelMedium.copyWith(
          color: BrandColors.primary,
        ),
        floatingLabelAlignment: FloatingLabelAlignment.start,
      ),
      textTheme: _lightTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: DesignTokens.headlineSmall.copyWith(
          color: BrandColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: BrandColors.lightTextPrimary,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: BrandColors.lightTextPrimary,
          size: 24,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BrandColors.lightSurface,
        selectedItemColor: BrandColors.primary,
        unselectedItemColor: BrandColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: DesignTokens.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: DesignTokens.labelSmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BrandColors.lightSurface,
        indicatorColor: BrandColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.labelSmall.copyWith(
              color: BrandColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return DesignTokens.labelSmall.copyWith(
            color: BrandColors.lightTextSecondary,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: BrandColors.primary,
              size: 24,
            );
          }
          return IconThemeData(
            color: BrandColors.lightTextSecondary,
            size: 24,
          );
        }),
        height: DesignTokens.bottomBarHeight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandColors.lightOutline,
        selectedColor: BrandColors.primary.withValues(alpha: 0.12),
        disabledColor: BrandColors.lightOutline.withValues(alpha: 0.5),
        labelStyle: DesignTokens.labelMedium.copyWith(
          color: BrandColors.lightTextPrimary,
        ),
        secondaryLabelStyle: DesignTokens.labelMedium.copyWith(
          color: BrandColors.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        ),
        side: BorderSide.none,
        pressElevation: 0,
        selectedShadowColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: BrandColors.lightOutline,
        thickness: DesignTokens.dividerHeight,
        space: DesignTokens.dividerHeight,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BrandColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: DesignTokens.lightFloatingShadows.first.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: const BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        titleTextStyle: DesignTokens.headlineSmall.copyWith(
          color: BrandColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: DesignTokens.bodyMedium.copyWith(
          color: BrandColors.lightTextPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: BrandColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: DesignTokens.lightFloatingShadows.first.color,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusSheet),
          ),
          side: const BorderSide(color: BrandColors.lightOutline, width: 1),
        ),
        modalBarrierColor: Colors.black54,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BrandColors.darkSurface,
        contentTextStyle: DesignTokens.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        ),
        actionTextColor: BrandColors.primaryLight,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: BrandColors.primary,
        foregroundColor: BrandColors.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFloatingButton),
        ),
      ),
      iconTheme: IconThemeData(
        color: BrandColors.lightTextPrimary,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: BrandColors.onPrimary,
        size: 24,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: BrandColors.primary,
        unselectedLabelColor: BrandColors.lightTextSecondary,
        indicatorColor: BrandColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: BrandColors.lightSurface,
        hourMinuteTextColor: BrandColors.lightTextPrimary,
        hourMinuteColor: BrandColors.lightBackground,
        dialHandColor: BrandColors.primary,
        dialBackgroundColor: BrandColors.lightBackground,
        dayPeriodTextColor: BrandColors.lightTextSecondary,
        dayPeriodColor: BrandColors.lightBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: BrandColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: BrandColors.primary,
        headerForegroundColor: Colors.white,
        weekdayStyle: DesignTokens.labelMedium.copyWith(
          color: BrandColors.lightTextSecondary,
        ),
        dayStyle: DesignTokens.bodyMedium.copyWith(
          color: BrandColors.lightTextPrimary,
        ),
        todayBackgroundColor: WidgetStateProperty.all(
          BrandColors.primary.withValues(alpha: 0.12),
        ),
        todayForegroundColor: WidgetStateProperty.all(BrandColors.primary),
        rangePickerHeaderBackgroundColor: BrandColors.lightBackground,
        rangePickerHeaderForegroundColor: BrandColors.lightTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: BrandColors.darkScheme,
      scaffoldBackgroundColor: BrandColors.darkBackground,
      fontFamily: DesignTokens.fontFamilyPrimary,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
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
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          side: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: DesignTokens.darkCardShadows.first.color,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primaryLight,
          foregroundColor: BrandColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          textStyle: DesignTokens.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, DesignTokens.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.primaryLight,
          side: const BorderSide(color: BrandColors.primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space5,
            vertical: DesignTokens.space2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          textStyle: DesignTokens.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, DesignTokens.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          textStyle: DesignTokens.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space5,
          vertical: DesignTokens.space4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: BrandColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        labelStyle: DesignTokens.bodyMedium.copyWith(
          color: BrandColors.darkTextSecondary,
        ),
        hintStyle: DesignTokens.bodyMedium.copyWith(
          color: BrandColors.darkTextSecondary,
        ),
        errorStyle: DesignTokens.labelSmall.copyWith(
          color: Color(0xFFFF6B6B),
        ),
        floatingLabelStyle: DesignTokens.labelMedium.copyWith(
          color: BrandColors.primaryLight,
        ),
        floatingLabelAlignment: FloatingLabelAlignment.start,
      ),
      textTheme: _darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: DesignTokens.headlineSmall.copyWith(
          color: BrandColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: BrandColors.darkTextPrimary,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: BrandColors.darkTextPrimary,
          size: 24,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BrandColors.darkSurface,
        selectedItemColor: BrandColors.primaryLight,
        unselectedItemColor: BrandColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: DesignTokens.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: DesignTokens.labelSmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BrandColors.darkSurface,
        indicatorColor: BrandColors.primaryLight.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.labelSmall.copyWith(
              color: BrandColors.primaryLight,
              fontWeight: FontWeight.w600,
            );
          }
          return DesignTokens.labelSmall.copyWith(
            color: BrandColors.darkTextSecondary,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: BrandColors.primaryLight,
              size: 24,
            );
          }
          return IconThemeData(
            color: BrandColors.darkTextSecondary,
            size: 24,
          );
        }),
        height: DesignTokens.bottomBarHeight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandColors.darkOutline,
        selectedColor: BrandColors.primaryLight.withValues(alpha: 0.2),
        disabledColor: BrandColors.darkOutline.withValues(alpha: 0.5),
        labelStyle: DesignTokens.labelMedium.copyWith(
          color: BrandColors.darkTextPrimary,
        ),
        secondaryLabelStyle: DesignTokens.labelMedium.copyWith(
          color: BrandColors.darkBackground,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        ),
        side: BorderSide.none,
        pressElevation: 0,
        selectedShadowColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: BrandColors.darkOutline,
        thickness: DesignTokens.dividerHeight,
        space: DesignTokens.dividerHeight,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BrandColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: DesignTokens.darkFloatingShadows.first.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        titleTextStyle: DesignTokens.headlineSmall.copyWith(
          color: BrandColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: DesignTokens.bodyMedium.copyWith(
          color: BrandColors.darkTextPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: BrandColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: DesignTokens.darkFloatingShadows.first.color,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusSheet),
          ),
          side: const BorderSide(color: BrandColors.darkOutline, width: 1),
        ),
        modalBarrierColor: Colors.black54,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BrandColors.darkSurface,
        contentTextStyle: DesignTokens.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        ),
        actionTextColor: BrandColors.primaryLight,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: BrandColors.primaryLight,
        foregroundColor: BrandColors.darkBackground,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFloatingButton),
        ),
      ),
      iconTheme: IconThemeData(
        color: BrandColors.darkTextPrimary,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: BrandColors.darkBackground,
        size: 24,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: BrandColors.primaryLight,
        unselectedLabelColor: BrandColors.darkTextSecondary,
        indicatorColor: BrandColors.primaryLight,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: BrandColors.darkSurface,
        hourMinuteTextColor: BrandColors.darkTextPrimary,
        hourMinuteColor: BrandColors.darkBackground,
        dialHandColor: BrandColors.primaryLight,
        dialBackgroundColor: BrandColors.darkBackground,
        dayPeriodTextColor: BrandColors.darkTextSecondary,
        dayPeriodColor: BrandColors.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: BrandColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: BrandColors.primaryLight,
        headerForegroundColor: BrandColors.darkBackground,
        weekdayStyle: DesignTokens.labelMedium.copyWith(
          color: BrandColors.darkTextSecondary,
        ),
        dayStyle: DesignTokens.bodyMedium.copyWith(
          color: BrandColors.darkTextPrimary,
        ),
        todayBackgroundColor: WidgetStateProperty.all(
          BrandColors.primaryLight.withValues(alpha: 0.15),
        ),
        todayForegroundColor: WidgetStateProperty.all(BrandColors.primaryLight),
        rangePickerHeaderBackgroundColor: BrandColors.darkBackground,
        rangePickerHeaderForegroundColor: BrandColors.darkTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
        ),
      ),
    );
  }

  // =========================================================================
  // TEXT THEMES
  // =========================================================================
  static TextTheme get _lightTextTheme => TextTheme(
    displayLarge: DesignTokens.displayLarge,
    displayMedium: DesignTokens.displayMedium,
    headlineLarge: DesignTokens.headlineLarge,
    headlineMedium: DesignTokens.headlineMedium,
    headlineSmall: DesignTokens.headlineSmall,
    titleLarge: DesignTokens.titleLarge,
    titleMedium: DesignTokens.titleMedium,
    titleSmall: DesignTokens.titleSmall,
    bodyLarge: DesignTokens.bodyLarge,
    bodyMedium: DesignTokens.bodyMedium,
    bodySmall: DesignTokens.bodySmall,
    labelLarge: DesignTokens.labelLarge,
    labelMedium: DesignTokens.labelMedium,
    labelSmall: DesignTokens.labelSmall,
  ).apply(
    bodyColor: BrandColors.lightTextPrimary,
    displayColor: BrandColors.lightTextPrimary,
  );

  static TextTheme get _darkTextTheme => TextTheme(
    displayLarge: DesignTokens.displayLarge,
    displayMedium: DesignTokens.displayMedium,
    headlineLarge: DesignTokens.headlineLarge,
    headlineMedium: DesignTokens.headlineMedium,
    headlineSmall: DesignTokens.headlineSmall,
    titleLarge: DesignTokens.titleLarge,
    titleMedium: DesignTokens.titleMedium,
    titleSmall: DesignTokens.titleSmall,
    bodyLarge: DesignTokens.bodyLarge,
    bodyMedium: DesignTokens.bodyMedium,
    bodySmall: DesignTokens.bodySmall,
    labelLarge: DesignTokens.labelLarge,
    labelMedium: DesignTokens.labelMedium,
    labelSmall: DesignTokens.labelSmall,
  ).apply(
    bodyColor: BrandColors.darkTextPrimary,
    displayColor: BrandColors.darkTextPrimary,
  );
}
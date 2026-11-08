import 'package:flutter/material.dart';
import 'brand_colors.dart';

/// Design tokens for the Atlendify soft blue airy card style.
/// All tokens are derived from the brand blue and work in both light/dark themes.
class DesignTokens {
  DesignTokens._();

  // =========================================================================
  // RADII
  // =========================================================================
  static const double radiusCard = 20.0;
  static const double radiusTile = 22.0;
  static const double radiusPill = 999.0;
  static const double radiusBottomBar = 28.0;
  static const double radiusSheet = 24.0;
  static const double radiusDialog = 24.0;
  static const double radiusButton = 14.0;
  static const double radiusInput = 14.0;
  static const double radiusChip = 8.0;
  static const double radiusBadge = 10.0;
  static const double radiusAvatar = 24.0;
  static const double radiusFloatingButton = 32.0;
  static const double radiusCircle = 999.0;

  // =========================================================================
  // SPACING SCALE (4dp base)
  // =========================================================================
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space7 = 28.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;

  // =========================================================================
  // ELEVATION / SHADOWS
  // =========================================================================
  // Light mode: soft diffuse shadows (neumorphic-lite)
  static const List<BoxShadow> lightCardShadows = [
    BoxShadow(
      color: Color(0x140E1116), // navy @ 8%
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A0E1116), // navy @ 4%
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> lightTileShadows = [
    BoxShadow(
      color: Color(0x0D0E1116), // navy @ 5%
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x080E1116), // navy @ 3%
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> lightFloatingShadows = [
    BoxShadow(
      color: Color(0x1A0E1116), // navy @ 10%
      offset: Offset(0, 12),
      blurRadius: 32,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0D0E1116), // navy @ 5%
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // Dark mode: 1px outline instead of shadows
  static const List<BoxShadow> darkCardShadows = [
    BoxShadow(
      color: Color(0xFF2A313B), // dark outline color
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
  ];

  static const List<BoxShadow> darkTileShadows = [
    BoxShadow(
      color: Color(0xFF2A313B),
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
  ];

  static const List<BoxShadow> darkFloatingShadows = [
    BoxShadow(
      color: Color(0xFF2A313B),
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
  ];

  // =========================================================================
  // DURATION & CURVES
  // =========================================================================
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationPage = Duration(milliseconds: 300);
  static const Duration durationStaggerBase = Duration(milliseconds: 40);
  static const int maxStaggerItems = 8;

  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeInOutCubic;
  static const Curve curveSpring = Curves.elasticOut;

  // =========================================================================
  // ANIMATION HELPERS (for const contexts)
  // =========================================================================
  static const Interval intervalEntrance = Interval(0.0, 0.5, curve: Curves.easeInOutCubic);
  static const Interval intervalFadeOut = Interval(0.8, 1.0, curve: Curves.easeInOutCubic);

  // =========================================================================
  // TYPOGRAPHY (fallback to Roboto if custom font not available)
  // =========================================================================
  static const String fontFamilyPrimary = 'PlusJakartaSans';
  static const String fontFamilyFallback = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // =========================================================================
  // STATUS COLORS (fixed, AA-readable in both themes)
  // =========================================================================
  static const Color statusOpen = BrandColors.primary; // Blue
  static const Color statusScheduled = Color(0xFF7C3AED); // Purple
  static const Color statusClosed = BrandColors.presentGreen; // Green
  static const Color statusLate = BrandColors.lateAmber; // Amber
  static const Color statusAbsent = BrandColors.absentRed; // Red
  static const Color statusRejected = Color(0xFF9CA3AF); // Grey

  static const Color liveDotColor = Color(0xFFEF4444); // Red for LIVE pulse

  // =========================================================================
  // ANIMATION HELPERS
  // =========================================================================
  static Duration staggerDelay(int index) =>
      Duration(milliseconds: (index * durationStaggerBase.inMilliseconds).clamp(0, 300));

  static Curve get defaultCurve => curveStandard;
  static Curve get emphasizedCurve => curveEmphasized;

  // =========================================================================
  // LAYOUT CONSTANTS
  // =========================================================================
  static const double bottomBarHeight = 72.0;
  static const double centerButtonDiameter = 64.0;
  static const double centerButtonOverlap = 24.0;
  static const double minTapTarget = 48.0;
  static const double maxContentWidth = 480.0;
  static const double calendarCellSize = 40.0;
  static const double avatarSize = 40.0;
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeLarge = 56.0;
  static const double chipHeight = 24.0;
  static const double pillHeight = 36.0;
  static const double inputHeight = 48.0;
  static const double buttonHeight = 48.0;
  static const double dividerHeight = 1.0;

  // =========================================================================
  // HELPER METHODS
  // =========================================================================
  static List<BoxShadow> cardShadows(bool isDark) => isDark ? darkCardShadows : lightCardShadows;
  static List<BoxShadow> tileShadows(bool isDark) => isDark ? darkTileShadows : lightTileShadows;
  static List<BoxShadow> floatingShadows(bool isDark) => isDark ? darkFloatingShadows : lightFloatingShadows;

  static Color statusColor(String status) {
    switch (status) {
      case 'open':
        return statusOpen;
      case 'scheduled':
        return statusScheduled;
      case 'closed':
        return statusClosed;
      case 'late':
        return statusLate;
      case 'absent':
        return statusAbsent;
      case 'rejected':
        return statusRejected;
      default:
        return BrandColors.primary;
    }
  }

  static Color statusColorFromAttendance(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return statusClosed; // Green
      case 'late':
        return statusLate; // Amber
      case 'absent':
        return statusAbsent; // Red
      default:
        return BrandColors.primary;
    }
  }
}
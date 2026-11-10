import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/design_tokens.dart';
import '../theme/brand_colors.dart';

/// ===========================================================================
/// SOFT CARD - Base card widget with theme-aware shadows/outlines
/// ===========================================================================
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final List<BoxShadow>? shadows;
  final Border? border;
  final BorderRadius? borderRadius;
  final bool isDark;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.shadows,
    this.border,
    this.borderRadius,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isDark ? BrandColors.darkSurface : BrandColors.lightSurface);
    final effectiveShadows = shadows ?? DesignTokens.cardShadows(isDark);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard);

    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: effectiveBorderRadius,
          boxShadow: effectiveShadows,
          border: border,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(DesignTokens.space6),
          child: child,
        ),
      ),
    );
  }
}

/// SoftCard with subtle hover/tap feedback
class SoftTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool highlighted;
  final bool isDark;
  final BorderRadius? borderRadius;

  const SoftTile({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.highlighted = false,
    required this.isDark,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isDark ? BrandColors.darkSurface : BrandColors.lightSurface);
    final effectiveShadows = highlighted
        ? (isDark
            ? [const BoxShadow(color: Color(0xFF2A313B), spreadRadius: 2)]
            : DesignTokens.lightCardShadows)
        : DesignTokens.tileShadows(isDark);

    final tile = RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: highlighted
              ? (isDark
                  ? BrandColors.primary.withValues(alpha: 0.15)
                  : BrandColors.primary.withValues(alpha: 0.08))
              : effectiveColor,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusTile),
          boxShadow: effectiveShadows,
          border: Border.all(
            color: highlighted
                ? BrandColors.primary
                : (isDark ? BrandColors.darkOutline : BrandColors.lightOutline),
            width: highlighted ? 1.5 : (isDark ? 1 : 0),
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(DesignTokens.space5),
          child: child,
        ),
      ),
    );

    if (onTap == null) return tile;

    return _TapScaleWidget(
      onTap: onTap!,
      child: tile,
    );
  }
}

/// ===========================================================================
/// STATUS LABEL - Small colored status pill
/// ===========================================================================
class StatusLabel extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusLabel({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    this.fontSize = 10,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space1,
          ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: DesignTokens.fontFamilyPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }
}

/// ===========================================================================
/// ACCENT BAR CARD - Card with a vertical accent bar on the left
/// ===========================================================================
class AccentBarCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double barWidth;
  final bool isDark;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AccentBarCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.padding,
    this.margin,
    this.barWidth = 4,
    required this.isDark,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor ?? (isDark ? BrandColors.darkSurface : BrandColors.lightSurface),
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
          boxShadow: DesignTokens.cardShadows(isDark),
          border: Border.all(
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
            width: isDark ? 1 : 0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: barWidth,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.only(
                  topLeft: (borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard)).topLeft,
                  bottomLeft: (borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard)).bottomLeft,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(DesignTokens.space5),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return _TapScaleWidget(onTap: onTap!, child: card);
  }
}

/// ===========================================================================
/// MONTH PILLS - Horizontal scrollable month selector with sliding indicator
/// ===========================================================================
class MonthPills extends StatefulWidget {
  final List<DateTime> months;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final Color? accentColor;

  const MonthPills({
    super.key,
    required this.months,
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
    this.accentColor,
  });

  @override
  State<MonthPills> createState() => _MonthPillsState();
}

class _MonthPillsState extends State<MonthPills> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _indicatorPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _indicatorPosition = Tween<double>(
      begin: widget.selectedIndex.toDouble(),
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: DesignTokens.emphasizedCurve));
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant MonthPills oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _indicatorPosition = Tween<double>(
        begin: oldWidget.selectedIndex.toDouble(),
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: DesignTokens.emphasizedCurve));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? BrandColors.primary;
    final pillWidth = 80.0;

    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedBuilder(
            animation: _indicatorPosition,
            builder: (context, child) {
              return Positioned(
                left: _indicatorPosition.value * (pillWidth + DesignTokens.space2) + DesignTokens.space2,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Pills
          ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
            itemCount: widget.months.length,
            separatorBuilder: (context, index) => const SizedBox(width: DesignTokens.space2),
            itemBuilder: (context, index) {
              final month = widget.months[index];
              final isSelected = index == widget.selectedIndex;
              final label = _monthLabel(month);

              return GestureDetector(
                onTap: () => widget.onChanged(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: pillWidth,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: DesignTokens.durationNormal,
                      curve: DesignTokens.emphasizedCurve,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamilyPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (widget.isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary),
                        height: 1.3,
                      ),
                      child: Text(label),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// ===========================================================================
/// CALENDAR CARD - Month grid with accent dates and selection
/// ===========================================================================
class CalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<int, Color> dayDots; // day -> color
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onMonthChange;
  final bool isDark;
  final Color? accentColor;

  const CalendarCard({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.dayDots,
    required this.onDayTap,
    required this.onMonthChange,
    required this.isDark,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? BrandColors.primary;
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;
    final prevMonthDays = DateTime(focusedMonth.year, focusedMonth.month, 0).day;

    final weeks = <List<DateTime?>>[];
    var currentWeek = <DateTime?>[];

    // Previous month days
    for (int i = firstWeekday - 1; i >= 0; i--) {
      currentWeek.add(DateTime(focusedMonth.year, focusedMonth.month - 1, prevMonthDays - i));
    }

    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(DateTime(focusedMonth.year, focusedMonth.month, day));
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Next month days
    if (currentWeek.isNotEmpty) {
      int nextDay = 1;
      while (currentWeek.length < 7) {
        currentWeek.add(DateTime(focusedMonth.year, focusedMonth.month + 1, nextDay++));
      }
      weeks.add(currentWeek);
    }

    return SoftCard(
      isDark: isDark,
      padding: const EdgeInsets.all(DesignTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header with prev/next
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthYearLabel(focusedMonth),
                style: DesignTokens.headlineSmall.copyWith(
                  color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  _CalendarNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => onMonthChange(DateTime(focusedMonth.year, focusedMonth.month - 1)),
                    isDark: isDark,
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  _CalendarNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => onMonthChange(DateTime(focusedMonth.year, focusedMonth.month + 1)),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          // Weekday labels
          Row(
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: DesignTokens.labelSmall.copyWith(
                      color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.space3),
          // Calendar grid
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space2),
              child: Row(
                children: week.map((day) {
                  if (day == null) return const Expanded(child: SizedBox());
                  final isCurrentMonth = day.month == focusedMonth.month;
                  final isSelected = selectedDay != null &&
                      selectedDay!.year == day.year &&
                      selectedDay!.month == day.month &&
                      selectedDay!.day == day.day;
                  final hasDot = dayDots.containsKey(day.day) && isCurrentMonth;
                  final dotColor = hasDot ? dayDots[day.day]! : null;

                  return Expanded(
                    child: _CalendarDayCell(
                      day: day.day,
                      isCurrentMonth: isCurrentMonth,
                      isSelected: isSelected,
                      dotColor: dotColor,
                      accentColor: accent,
                      isDark: isDark,
                      onTap: isCurrentMonth ? () => onDayTap(day) : null,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _monthYearLabel(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _CalendarNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _CalendarNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? BrandColors.darkBackground : BrandColors.lightBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            border: Border.all(
              color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatefulWidget {
  final int day;
  final bool isCurrentMonth;
  final bool isSelected;
  final Color? dotColor;
  final Color accentColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _CalendarDayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.dotColor,
    required this.accentColor,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<_CalendarDayCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final hasDot = widget.dotColor != null;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: DesignTokens.calendarCellSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? widget.accentColor
                    : (hasDot
                        ? widget.dotColor!.withValues(alpha: 0.15)
                        : Colors.transparent),
                border: hasDot && !isSelected
                    ? Border.all(
                        color: widget.dotColor!.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      '${widget.day}',
                      style: DesignTokens.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : widget.isCurrentMonth
                                ? (widget.isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary)
                                : (widget.isDark ? BrandColors.darkTextSecondary.withValues(alpha: 0.4) : BrandColors.lightTextSecondary.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                  if (hasDot && !isSelected)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: widget.dotColor!,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ===========================================================================
/// AVATAR CIRCLE - Circular avatar with initials or image
/// ===========================================================================
class AvatarCircle extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isDark;

  const AvatarCircle({
    super.key,
    this.name,
    this.imageUrl,
    this.size = DesignTokens.avatarSize,
    this.backgroundColor,
    this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (isDark ? BrandColors.primary.withValues(alpha: 0.2) : BrandColors.primary.withValues(alpha: 0.1));
    final fgColor = textColor ?? (isDark ? BrandColors.primaryLight : BrandColors.primary);

    Widget child;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ____) => _initialsAvatar(bgColor, fgColor),
        ),
      );
    } else {
      child = _initialsAvatar(bgColor, fgColor);
    }

    return SizedBox(
      width: size,
      height: size,
      child: child,
    );
  }

  Widget _initialsAvatar(Color bg, Color fg) {
    String initials = '?';
    if (name != null && name!.isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else {
        initials = parts.first.substring(0, 2).toUpperCase();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: DesignTokens.titleMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ===========================================================================
/// COUNT BADGE - Small circular badge with count
/// ===========================================================================
class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final bool isDark;
  final double size;

  const CountBadge({
    super.key,
    required this.count,
    this.color,
    required this.isDark,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final badgeColor = color ?? BrandColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusBadge),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontFamily: DesignTokens.fontFamilyPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// ===========================================================================
/// FLOATING NAV BAR - Clean 3-tab bottom navigation bar
/// ===========================================================================
class FloatingNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final bool isDark;
  final Color? backgroundColor;
  final Color? accentColor;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.isDark,
    this.backgroundColor,
    this.accentColor,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = widget.accentColor ?? BrandColors.primary;
    final bgColor = widget.backgroundColor ?? (isDark ? BrandColors.darkSurface : BrandColors.lightSurface);
    final itemCount = widget.destinations.length;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      bottom: true,
      minimum: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: DesignTokens.bottomBarHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusBottomBar)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : BrandColors.primary.withValues(alpha: 0.08),
              offset: const Offset(0, -4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
              width: isDark ? 1 : 0,
            ),
          ),
        ),
        child: Row(
          children: List.generate(itemCount, (index) {
            final destination = widget.destinations[index];
            final isSelected = index == widget.selectedIndex;
            return Expanded(
              child: _NavBarItem(
                destination: destination,
                isSelected: isSelected,
                isDark: isDark,
                accentColor: accent,
                onTap: () => widget.onDestinationSelected(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final NavigationDestination destination;
  final bool isSelected;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.destination,
    required this.isSelected,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant _NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected && widget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final color = isSelected ? widget.accentColor : (widget.isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: SizedBox(
              height: DesignTokens.bottomBarHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(size: 24, color: color),
                    child: widget.destination.icon,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.destination.label,
                    style: DesignTokens.labelSmall.copyWith(
                      color: color,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ===========================================================================
/// SECTION TITLE - Consistent section header
/// ===========================================================================
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool isDark;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTokens.headlineMedium.copyWith(
                    color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    subtitle!,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[trailing!],
        ],
      ),
    );
  }
}

/// ===========================================================================
/// EMPTY STATE
/// ===========================================================================
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool isDark;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDark ? BrandColors.primary.withValues(alpha: 0.15) : BrandColors.primary.withValues(alpha: 0.08)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark ? BrandColors.primaryLight : BrandColors.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            Text(
              title,
              style: DesignTokens.headlineMedium.copyWith(
                color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              message,
              style: DesignTokens.bodyMedium.copyWith(
                color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: DesignTokens.space5),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ===========================================================================
/// ERROR STATE
/// ===========================================================================
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isDark;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: BrandColors.absentRed,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Something went wrong',
              style: DesignTokens.headlineSmall.copyWith(
                color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              message,
              style: DesignTokens.bodyMedium.copyWith(
                color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DesignTokens.space5),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6, vertical: DesignTokens.space3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ===========================================================================
/// SKELETON LOADER
/// ===========================================================================
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isDark;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    required this.isDark,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? BrandColors.darkOutline : BrandColors.lightOutline;
    final highlightColor = widget.isDark
        ? BrandColors.darkOutline.withValues(alpha: 0.5)
        : BrandColors.lightOutline.withValues(alpha: 0.5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(baseColor, highlightColor, _animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
          ),
        );
      },
    );
  }
}

/// ===========================================================================
/// PIL BUTTON - Pill-shaped button
/// ===========================================================================
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isDark;
  final bool outlined;
  final bool loading;
  final double height;
  final double borderRadius;

  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    required this.isDark,
    this.outlined = false,
    this.loading = false,
    this.height = DesignTokens.pillHeight,
    this.borderRadius = DesignTokens.radiusPill,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? (isDark ? BrandColors.primaryLight : BrandColors.primary);
    final fgColor = foregroundColor ?? Colors.white;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16),
          const SizedBox(width: DesignTokens.space2),
        ],
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else
          Flexible(
            child: Text(
              label,
              style: DesignTokens.labelLarge.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: bgColor,
          side: BorderSide(color: bgColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space5, vertical: DesignTokens.space2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          minimumSize: Size(0, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: buttonChild,
      );
    }

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space5, vertical: DesignTokens.space2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        minimumSize: Size(0, height),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: buttonChild,
    );
  }
}

/// ===========================================================================
/// TAP SCALE WRAPPER - Scale animation on tap
/// ===========================================================================
class _TapScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScaleWidget({
    required this.child,
    this.onTap,
  });

  @override
  State<_TapScaleWidget> createState() => _TapScaleWidgetState();
}

class _TapScaleWidgetState extends State<_TapScaleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// ===========================================================================
/// LIVE DOT - Pulsing indicator for live sessions
/// ===========================================================================
class LiveDot extends StatefulWidget {
  final double size;
  final Color color;

  const LiveDot({
    super.key,
    this.size = 8,
    this.color = DesignTokens.liveDotColor,
  });

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + 0.6 * _controller.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5 * _controller.value),
                  blurRadius: 8 * _controller.value,
                  spreadRadius: 2 * _controller.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ===========================================================================
/// STAGGERED LIST - Animated entrance for lists
/// ===========================================================================
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const StaggeredList({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return StaggeredItem(
          key: ValueKey(index),
          index: index,
          child: children[index],
        );
      },
    );
  }
}

class StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredItem({super.key, required this.index, required this.child});

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index * DesignTokens.durationStaggerBase.inMilliseconds).clamp(0, 300));
    _controller = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    ));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// ===========================================================================
/// KEYBOARD SAFE DIALOG - Dialog that handles keyboard avoidance and safe areas
/// ===========================================================================
class KeyboardSafeDialog extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget content;
  final List<Widget> actions;

  const KeyboardSafeDialog({
    super.key,
    required this.isDark,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;

    return AnimatedPadding(
      duration: DesignTokens.durationNormal,
      curve: DesignTokens.emphasizedCurve,
      padding: MediaQuery.of(context).viewInsets,
      child: AlertDialog(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(color: outlineColor, width: 1),
        ),
        title: Text(
          title,
          style: DesignTokens.headlineSmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: content,
        ),
        actions: actions,
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space2,
        ),
      ),
    );
  }
}

/// ===========================================================================
/// GLASS NAV BAR - Frozen glass navigation bar for bottomNavigationBar
/// ===========================================================================
class GlassNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final bool isDark;
  final Color? accentColor;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.isDark,
    this.accentColor,
  });

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = widget.accentColor ?? BrandColors.primary;
    final itemCount = widget.destinations.length;

    // Glassmorphic colors
    final glassBgColor = isDark ? const Color(0xCC1A1F26) : const Color(0xCCF0F4F8);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.6);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: DesignTokens.bottomBarHeight,
          decoration: BoxDecoration(
            color: glassBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border(
              top: BorderSide(
                color: glassBorderColor,
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, -4),
                blurRadius: 20,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, -2),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: List.generate(itemCount, (index) {
              final destination = widget.destinations[index];
              final isSelected = index == widget.selectedIndex;
              return Expanded(
                child: _GlassNavBarItem(
                  destination: destination,
                  isSelected: isSelected,
                  isDark: isDark,
                  accentColor: accent,
                  onTap: () => widget.onDestinationSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _GlassNavBarItem extends StatefulWidget {
  final NavigationDestination destination;
  final bool isSelected;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassNavBarItem({
    required this.destination,
    required this.isSelected,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_GlassNavBarItem> createState() => _GlassNavBarItemState();
}

class _GlassNavBarItemState extends State<_GlassNavBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _iconScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant _GlassNavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;
    final accent = widget.accentColor;

    final inactiveIconColor = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;
    final inactiveLabelColor = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: SizedBox(
              height: DesignTokens.bottomBarHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon container - only for active tab
                  AnimatedContainer(
                    duration: DesignTokens.durationNormal,
                    curve: DesignTokens.emphasizedCurve,
                    width: isSelected ? 44 : 24,
                    height: isSelected ? 32 : 24,
                    decoration: isSelected
                        ? BoxDecoration(
                            color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(16),
                          )
                        : null,
                    child: Center(
                      child: Transform.scale(
                        scale: isSelected ? _iconScale.value : 1.0,
                        child: IconTheme(
                          data: IconThemeData(
                            size: 24,
                            color: isSelected ? accent : inactiveIconColor,
                          ),
                          child: isSelected
                              ? widget.destination.selectedIcon ?? widget.destination.icon
                              : widget.destination.icon,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: DesignTokens.durationNormal,
                    curve: DesignTokens.emphasizedCurve,
                    style: DesignTokens.labelSmall.copyWith(
                      color: isSelected ? accent : inactiveLabelColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(
                      widget.destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
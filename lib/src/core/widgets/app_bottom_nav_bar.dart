import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/design_tokens.dart';
import '../theme/brand_colors.dart';

/// ===========================================================================
/// APP BOTTOM NAV BAR - Floating glass navigation bar for Admin & Student
/// ===========================================================================
class AppBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Color? accentColor;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.accentColor,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: DesignTokens.emphasizedCurve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
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
    final accent = widget.accentColor ?? BrandColors.primary;
    final itemCount = widget.destinations.length;

    // Glassmorphic colors - dark theme only
    final glassBgColor = const Color(0xCC1A1F26);
    final glassBorderColor = Colors.white.withValues(alpha: 0.12);

    // Bottom offset for safe area (gesture bar, home indicator, etc.)
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: DesignTokens.emphasizedCurve,
            )),
            child: SafeArea(
              top: false,
              bottom: true,
              minimum: EdgeInsets.only(bottom: bottomInset + 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: DesignTokens.bottomBarHeight,
                      decoration: BoxDecoration(
                        color: glassBgColor,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: glassBorderColor,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            offset: const Offset(0, -4),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
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
                            child: _NavBarItem(
                              destination: destination,
                              isSelected: isSelected,
                              accentColor: accent,
                              onTap: () => widget.onDestinationSelected(index),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final NavigationDestination destination;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.destination,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _iconScale;
  late Animation<double> _labelScale;

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
    _labelScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant _NavBarItem oldWidget) {
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
    final accent = widget.accentColor;
    final inactiveColor = BrandColors.darkTextSecondary;

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
                  // Icon with animation
                  AnimatedBuilder(
                    animation: _iconScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected ? _iconScale.value : 1.0,
                        child: IconTheme(
                          data: IconThemeData(
                            size: 24,
                            color: isSelected ? accent : inactiveColor,
                          ),
                          child: isSelected
                              ? widget.destination.selectedIcon ?? widget.destination.icon
                              : widget.destination.icon,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  // Label with animation
                  AnimatedBuilder(
                    animation: _labelScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected ? _labelScale.value : 1.0,
                        child: AnimatedDefaultTextStyle(
                          duration: DesignTokens.durationNormal,
                          curve: DesignTokens.emphasizedCurve,
                          style: DesignTokens.labelSmall.copyWith(
                            color: isSelected ? accent : inactiveColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          child: Text(
                            widget.destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
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
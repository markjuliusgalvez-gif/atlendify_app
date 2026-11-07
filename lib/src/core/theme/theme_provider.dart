import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModePreference {
  system,
  light,
  dark,
}

const String _themeModeKey = 'theme_mode_preference';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeModePreference>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeModePreference> {
  ThemeModeNotifier() : super(ThemeModePreference.system) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    if (value != null) {
      state = ThemeModePreference.values.byName(value);
    }
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  ThemeMode get themeMode {
    switch (state) {
      case ThemeModePreference.light:
        return ThemeMode.light;
      case ThemeModePreference.dark:
        return ThemeMode.dark;
      case ThemeModePreference.system:
        return ThemeMode.system;
    }
  }
}

/// A widget that wraps the app with theme animation support
class AppAnimatedTheme extends ConsumerStatefulWidget {
  final Widget child;

  const AppAnimatedTheme({super.key, required this.child});

  @override
  ConsumerState<AppAnimatedTheme> createState() => _AppAnimatedThemeState();
}

class _AppAnimatedThemeState extends ConsumerState<AppAnimatedTheme> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _crossFade;
  ThemeModePreference _previousMode = ThemeModePreference.system;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _crossFade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.value = 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentMode = ref.watch(themeModeProvider);
    if (!_initialized) {
      _initialized = true;
      _previousMode = currentMode;
    } else if (_previousMode != currentMode) {
      _previousMode = currentMode;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _crossFade,
      builder: (context, child) {
        return widget.child;
      },
    );
  }
}

/// Theme toggle button with animated sun/moon icon cross-fade
class ThemeToggleButton extends ConsumerWidget {
  final double size;
  final EdgeInsetsGeometry? padding;

  const ThemeToggleButton({
    super.key,
    this.size = 24,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: IconButton(
        key: ValueKey(themeMode),
        onPressed: () async {
          final notifier = ref.read(themeModeProvider.notifier);
          final newMode = switch (themeMode) {
            ThemeModePreference.light => ThemeModePreference.dark,
            ThemeModePreference.dark => ThemeModePreference.system,
            ThemeModePreference.system => ThemeModePreference.light,
          };
          await notifier.setThemeMode(newMode);
        },
        icon: _buildIcon(isDark, colorScheme),
        iconSize: size,
        padding: padding ?? EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: _tooltipForMode(themeMode),
      ),
    );
  }

  Widget _buildIcon(bool isDark, ColorScheme colorScheme) {
    final iconColor = colorScheme.onSurface;

    if (isDark) {
      return Icon(
        Icons.dark_mode_rounded,
        color: iconColor,
        size: 24,
      );
    }
    return Icon(
      Icons.light_mode_rounded,
      color: iconColor,
      size: 24,
    );
  }

  String _tooltipForMode(ThemeModePreference mode) {
    return switch (mode) {
      ThemeModePreference.light => 'Switch to dark mode',
      ThemeModePreference.dark => 'Switch to system mode',
      ThemeModePreference.system => 'Switch to light mode',
    };
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/auth_provider.dart';

/// Clock interface for testability
abstract class SplashClock {
  Future<void> delay(Duration duration);
  DateTime now();
}

class SystemSplashClock implements SplashClock {
  @override
  Future<void> delay(Duration duration) => Future.delayed(duration);

  @override
  DateTime now() => DateTime.now();
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    this.clock,
  });

  final SplashClock? clock;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late AnimationController _markController;
  late AnimationController _fadeOutController;
  late Animation<double> _markScale;
  late Animation<double> _markOpacity;
  late Animation<double> _fadeOut;

  bool _initComplete = false;
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();

    _markController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _markScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _markController, curve: Curves.easeOutCubic),
    );
    _markOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _markController, curve: Curves.easeOutCubic),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );

    _startAnimation();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    // Wait for auth state to be ready
    await (widget.clock ?? SystemSplashClock()).delay(const Duration(milliseconds: 100));
    if (!mounted) return;
    _initComplete = true;
    _maybeNavigate();
  }

  void _startAnimation() async {
    await _markController.forward();
    if (!mounted) return;
    await (widget.clock ?? SystemSplashClock()).delay(const Duration(milliseconds: 500)); // Hold
    if (!mounted) return;
    await _fadeOutController.forward();
    if (!mounted) return;
    _animationComplete = true;
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (!_initComplete || !_animationComplete) return;

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      final session = authState.session;
      if (session.isAdmin) {
        context.go(AppRoutes.pinGate);
      } else {
        context.go(AppRoutes.studentHome);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _markController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoTint = isDark ? BrandColors.logoTintDark : BrandColors.logoTintLight;

    return Scaffold(
      backgroundColor: isDark ? BrandColors.darkBackground : Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_markController, _fadeOutController]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo mark only
                  ScaleTransition(
                    scale: _markScale,
                    child: FadeTransition(
                      opacity: _markOpacity,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(logoTint, BlendMode.srcIn),
                        child: Image.asset(
                          'assets/images/logo_mark.png',
                          width: 80,
                          height: 80,
                        ),
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
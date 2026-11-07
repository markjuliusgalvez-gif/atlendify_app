import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late AnimationController _markController;
  late AnimationController _textController;
  late AnimationController _fadeOutController;
  late Animation<double> _markScale;
  late Animation<double> _markOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
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
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    _textSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );

    _startAnimation();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    // Wait for auth state to be ready
    await Future.delayed(const Duration(milliseconds: 100));
    _initComplete = true;
    _maybeNavigate();
  }

  void _startAnimation() async {
    await _markController.forward();
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 500)); // Hold
    await _fadeOutController.forward();
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
    _textController.dispose();
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
        animation: Listenable.merge([_markController, _textController, _fadeOutController]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo mark
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
                  // Wordmark (full logo)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_textSlide),
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(logoTint, BlendMode.srcIn),
                          child: Image.asset(
                            'assets/images/logo_full.png',
                            width: 200,
                            fit: BoxFit.contain,
                          ),
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
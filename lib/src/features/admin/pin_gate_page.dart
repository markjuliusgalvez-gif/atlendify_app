import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/pin_service.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/pin_boxes.dart';

class PinGatePage extends ConsumerStatefulWidget {
  const PinGatePage({super.key});

  @override
  ConsumerState<PinGatePage> createState() => _PinGatePageState();
}

class _PinGatePageState extends ConsumerState<PinGatePage>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  PinLockoutState? _lockoutState;

  late AnimationController _shakeController;
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _entranceController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: DesignTokens.emphasizedCurve,
          ),
        );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: DesignTokens.emphasizedCurve,
      ),
    );

    _checkLockout();
    _entranceController.forward();
  }

  Future<void> _checkLockout() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final userId = authState.session.user.id!;
    final pinService = PinService();
    final state = await pinService.getLockoutState(userId);
    if (mounted) {
      setState(() {
        _lockoutState = state;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _shakeController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handlePinSubmit(String pin) async {
    if (_isLoading) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final user = authState.session.user;
    if (user.pinHash == null || user.pinSalt == null) {
      // No PIN set - navigate to setup
      if (mounted) context.go(AppRoutes.adminHome);
      return;
    }

    final userId = user.id!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pinService = PinService();
    final result = await pinService.verifyPin(
      enteredPin: pin,
      storedPinHash: user.pinHash!,
      storedPinSalt: user.pinSalt!,
      userId: userId,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      _pinController.clear();
      ref.read(authProvider.notifier).unlockPin();
      if (mounted) context.go(AppRoutes.adminHome);
    } else if (!result.isSuccess && result.attemptsRemaining != null) {
      setState(() {
        _errorMessage =
            'Incorrect PIN. ${result.attemptsRemaining} attempts remaining.';
      });
      _triggerShake();
      await _checkLockout();
    } else if (!result.isSuccess && result.lockedOutRemaining != null) {
      setState(() {
        _errorMessage =
            'Too many failed attempts. Try again in ${result.lockedOutRemaining!.inSeconds} seconds.';
      });
      await _checkLockout();
    }
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  void _showForgotPinDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark
        ? BrandColors.darkTextPrimary
        : BrandColors.lightTextPrimary;
    final textSecondary = isDark
        ? BrandColors.darkTextSecondary
        : BrandColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
            width: 1,
          ),
        ),
        title: Text(
          'Reset PIN',
          style: DesignTokens.headlineSmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'To reset your PIN, please verify your account password first. This feature will be implemented soon.',
          style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: DesignTokens.labelLarge.copyWith(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement password verification and PIN reset
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
            ),
            child: Text(
              'Verify Password',
              style: DesignTokens.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? BrandColors.darkBackground
        : BrandColors.lightBackground;
    final logoTint = isDark
        ? BrandColors.logoTintDark
        : BrandColors.logoTintLight;
    final textPrimary = isDark
        ? BrandColors.darkTextPrimary
        : BrandColors.lightTextPrimary;
    final textSecondary = isDark
        ? BrandColors.darkTextSecondary
        : BrandColors.lightTextSecondary;

    // Accent color for buttons in dark mode (lighter, more visible)
    final accentColor = isDark ? BrandColors.primaryLight : BrandColors.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // System back button pressed - sign out and go to login
        await ref.read(authProvider.notifier).signOut();
        if (mounted) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space6),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  DesignTokens.space12,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      // Theme toggle
                      Align(
                        alignment: Alignment.topRight,
                        child: ThemeToggleButton(),
                      ),
                      const SizedBox(height: DesignTokens.space6),

                      // Logo mark
                      Center(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            logoTint,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/logo_mark.png',
                            width: 88,
                            height: 88,
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space8),

                      // Title
                      Text(
                        'Admin PIN',
                        style: DesignTokens.headlineLarge.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        'Enter your 4-digit PIN to access the admin dashboard',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.space8),

                      // PIN Boxes - no outer card, constrained width
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: PinBoxes(
                            controller: _pinController,
                            disabled: _isLoading ||
                                _lockoutState?.isLockedOut == true,
                            errorText: _errorMessage,
                            lockoutState: _lockoutState,
                            semanticLabel: 'Admin PIN',
                            autofocus: true,
                            onSubmit: _handlePinSubmit,
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space5),

                      // Forgot PIN? - uses accent color for visibility in dark mode
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : _showForgotPinDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.space3,
                              vertical: DesignTokens.space1,
                            ),
                          ),
                          child: Text(
                            'Forgot PIN?',
                            style: DesignTokens.labelLarge.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space3),

                      // Back to Login button - outlined pill, full width of box row
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    await ref.read(authProvider.notifier).signOut();
                                    if (mounted) {
                                      context.go(AppRoutes.login);
                                    }
                                  },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: Text(
                              'Back to Login',
                              style: DesignTokens.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentColor,
                              side: BorderSide(color: accentColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.space5,
                                vertical: DesignTokens.space2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusPill,
                                ),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
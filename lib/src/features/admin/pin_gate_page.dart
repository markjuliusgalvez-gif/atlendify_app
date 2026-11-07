import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../core/services/pin_service.dart';
import '../../core/router/app_router.dart';

class PinGatePage extends ConsumerStatefulWidget {
  const PinGatePage({super.key});

  @override
  ConsumerState<PinGatePage> createState() => _PinGatePageState();
}

class _PinGatePageState extends ConsumerState<PinGatePage> with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  PinLockoutState? _lockoutState;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    _checkLockout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocus.requestFocus();
    });
  }

  Future<void> _checkLockout() async {
    final pinService = PinService();
    final state = await pinService.getLockoutState();
    if (mounted) {
      setState(() {
        _lockoutState = state;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handlePinSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final user = authState.session.user;
    if (user.pinHash == null || user.pinSalt == null) {
      // No PIN set - navigate to setup
      // For now, just proceed to admin home
      if (mounted) context.go(AppRoutes.adminHome);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pinService = PinService();
    final result = await pinService.verifyPin(
      enteredPin: _pinController.text,
      storedPinHash: user.pinHash!,
      storedPinSalt: user.pinSalt!,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      _pinController.clear();
      if (mounted) context.go(AppRoutes.adminHome);
    } else if (!result.isSuccess && result.attemptsRemaining != null) {
      setState(() {
        _errorMessage = 'Incorrect PIN. ${result.attemptsRemaining} attempts remaining.';
      });
      _triggerShake();
      await _checkLockout();
    } else if (!result.isSuccess && result.lockedOutRemaining != null) {
      setState(() {
        _errorMessage = 'Too many failed attempts. Try again in ${result.lockedOutRemaining!.inSeconds} seconds.';
      });
      await _checkLockout();
    }
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoTint = isDark ? BrandColors.logoTintDark : BrandColors.logoTintLight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Theme toggle
                  Align(
                    alignment: Alignment.topRight,
                    child: ThemeToggleButton(),
                  ),
                  const SizedBox(height: 24),

                  // Logo mark
                  Center(
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(logoTint, BlendMode.srcIn),
                      child: Image.asset(
                        'assets/images/logo_mark.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Admin PIN',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your 4-digit PIN to access the admin dashboard',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // PIN dots
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value * 20 * (1 - _shakeAnimation.value), 0),
                              child: child,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final filled = index < _pinController.text.length;
                              return Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: filled
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Hidden input field
                        Opacity(
                          opacity: 0,
                          child: TextFormField(
                            controller: _pinController,
                            focusNode: _pinFocus,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            showCursor: false,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'PIN required';
                              if (value.length != 4) return 'Enter 4 digits';
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                              if (value.length == 4) {
                                _handlePinSubmit();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Lockout countdown
                        if (_lockoutState != null && _lockoutState!.isLockedOut)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Locked for ${_lockoutState!.remainingLockout!.inSeconds} seconds',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                      ),
                                ),
                              ],
                            ),
                          ),

                        if (_lockoutState != null && _lockoutState!.isLockedOut)
                          const SizedBox(height: 16),

                        // Error message
                        if (_errorMessage != null && !(_lockoutState != null && _lockoutState!.isLockedOut))
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),

                        if (_errorMessage != null && !(_lockoutState != null && _lockoutState!.isLockedOut))
                          const SizedBox(height: 16),

                        // Forgot PIN
                        TextButton(
                          onPressed: _isLoading ? null : _showForgotPinDialog,
                          child: const Text('Forgot PIN?'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN'),
        content: const Text(
          'To reset your PIN, please verify your account password first. This feature will be implemented soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement password verification and PIN reset
            },
            child: const Text('Verify Password'),
          ),
        ],
      ),
    );
  }
}
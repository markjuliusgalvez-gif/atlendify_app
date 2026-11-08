import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pin_service.dart';
import '../../core/database/repositories.dart';
import '../../core/widgets/pin_boxes.dart';
import '../../core/widgets/shared_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: DesignTokens.emphasizedCurve));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: DesignTokens.emphasizedCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ref.read(authProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState is AuthError) {
      setState(() {
        _isLoading = false;
        _errorMessage = authState.message;
      });
    }
    // Navigation handled by router redirect
  }

  Future<void> _handleAdminLogin() async {
    final pinController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AdminPinDialog(
        pinController: pinController,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onSubmit: (pin) => Navigator.pop(context, pin),
      ),
    );

    if (result == null || result.isEmpty) return;

    // Verify PIN against stored admin PIN
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated && authState.session.isAdmin) {
      // Already logged in as admin, verify PIN
      final user = authState.session.user;
      if (user.pinHash == null || user.pinSalt == null) {
        _showError('PIN not set up for this admin');
        return;
      }

      final pinService = PinService();
      final pinResult = await pinService.verifyPin(
        enteredPin: result,
        storedPinHash: user.pinHash!,
        storedPinSalt: user.pinSalt!,
        userId: user.id!,
      );

      if (!pinResult.isSuccess) {
        if (pinResult.lockedOutRemaining != null) {
          _showError('Too many failed attempts. Try again in ${pinResult.lockedOutRemaining!.inSeconds} seconds.');
        } else {
          _showError('Incorrect PIN. ${pinResult.attemptsRemaining} attempts remaining.');
        }
        return;
      }

      if (mounted) {
        context.go(AppRoutes.adminHome);
      }
      return;
    }

    // Not logged in - find admin user by email
    final adminEmail = _emailController.text.trim();
    if (adminEmail.isEmpty) {
      _showError('Please enter your admin email first');
      return;
    }

    final userRepo = UserRepository();
    final adminUser = await userRepo.getByEmail(adminEmail);
    if (adminUser == null || adminUser.role != 'admin') {
      _showError('Admin account not found');
      return;
    }

    if (adminUser.pinHash == null || adminUser.pinSalt == null) {
      _showError('PIN not set up for this admin');
      return;
    }

    final pinService = PinService();
    final pinResult = await pinService.verifyPin(
      enteredPin: result,
      storedPinHash: adminUser.pinHash!,
      storedPinSalt: adminUser.pinSalt!,
      userId: adminUser.id!,
    );

    if (!pinResult.isSuccess) {
      if (pinResult.lockedOutRemaining != null) {
        _showError('Too many failed attempts. Try again in ${pinResult.lockedOutRemaining!.inSeconds} seconds.');
      } else {
        _showError('Incorrect PIN. ${pinResult.attemptsRemaining} attempts remaining.');
      }
      return;
    }

    // PIN verified - now login with password
    final password = _passwordController.text;
    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    await ref.read(authProvider.notifier).login(
      email: adminEmail,
      password: password,
    );

    // Navigation handled by router redirect
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space6),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  DesignTokens.space12,
            ).normalize(),
            child: IntrinsicHeight(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Theme toggle
                      Align(
                        alignment: Alignment.topRight,
                        child: ThemeToggleButton(),
                      ),
                      const SizedBox(height: DesignTokens.space6),

                      // Logo full - responsive
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: (MediaQuery.of(context).size.width - 48).clamp(200.0, double.infinity),
                            maxHeight: 90,
                          ),
                          child: Image.asset(
                            'assets/images/logo_full.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space8),

                      // Welcome text
                      Text(
                        'Welcome back',
                        style: DesignTokens.headlineLarge.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        'Sign in to continue to Atlendify',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.space8),

                      // Form card
                      SoftCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(DesignTokens.space6),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: EmailValidator.validateEmail,
                              ),
                              const SizedBox(height: DesignTokens.space4),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                validator: PasswordValidator.validatePassword,
                                onFieldSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: DesignTokens.space2),

                              // Error message
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                                  child: Text(
                                    _errorMessage!,
                                    style: DesignTokens.bodySmall.copyWith(
                                      color: BrandColors.absentRed,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              const SizedBox(height: DesignTokens.space3),

                              // Login button (Student)
                              PillButton(
                                label: _isLoading ? 'Signing in...' : 'Sign In as Student',
                                icon: _isLoading ? null : Icons.login_rounded,
                                onPressed: _isLoading ? null : _handleLogin,
                                isDark: isDark,
                                loading: _isLoading,
                              ),
                              const SizedBox(height: DesignTokens.space3),

                              // Login as Admin button
                              PillButton(
                                label: 'Login as Admin',
                                icon: Icons.admin_panel_settings_outlined,
                                onPressed: _isLoading ? null : _handleAdminLogin,
                                isDark: isDark,
                                outlined: true,
                              ),
                              const SizedBox(height: DesignTokens.space6),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      "Don't have an account? ",
                                      style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go(AppRoutes.register),
                                    child: const Text('Create account'),
                                  ),
                                ],
                              ),
                            ],
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

/// Admin PIN Dialog with soft card styling
class _AdminPinDialog extends StatefulWidget {
  final TextEditingController pinController;
  final bool isDark;
  final ValueChanged<String> onSubmit;

  const _AdminPinDialog({
    required this.pinController,
    required this.isDark,
    required this.onSubmit,
  });

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: DesignTokens.emphasizedCurve),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: DesignTokens.emphasizedCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Dialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
                side: BorderSide(color: outlineColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin PIN Required',
                      style: DesignTokens.headlineSmall.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Enter your 4-digit admin PIN to access the admin dashboard',
                      style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    PinBoxes(
                      controller: widget.pinController,
                      disabled: false,
                      errorText: null,
                      semanticLabel: 'Admin PIN',
                      autofocus: true,
                      onSubmit: widget.onSubmit,
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: 'Cancel',
                            icon: Icons.close_rounded,
                            onPressed: () => Navigator.pop(context),
                            isDark: isDark,
                            outlined: true,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space2),
                        Expanded(
                          child: PillButton(
                            label: 'Verify',
                            icon: Icons.check_rounded,
                            onPressed: () {
                              if (widget.pinController.text.length == 4) {
                                widget.onSubmit(widget.pinController.text);
                              }
                            },
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
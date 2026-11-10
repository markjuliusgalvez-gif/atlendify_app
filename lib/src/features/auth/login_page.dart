import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pin_service.dart';
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
  }

  Future<void> _handleAdminLogin() async {
    // Validate email and password fields before showing PIN dialog
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your admin email and password first');
      return;
    }

    // Validate email format
    final emailError = EmailValidator.validateEmail(email);
    if (emailError != null) {
      _showError('Please enter a valid email address');
      return;
    }

    // Check if admin email format matches (or just non-empty for now)
    if (!email.endsWith('@atlendify.app') && !email.contains('admin')) {
      _showError('Please enter your admin credentials');
      return;
    }

    final pinController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => _AdminPinDialog(
        pinController: pinController,
        onSubmit: (pin) => Navigator.pop(context, pin),
      ),
    );

    if (result == null || result.isEmpty) return;

    final pinService = PinService();
    final pinResult = await pinService.verifyPin(
      enteredPin: result,
      storedPinHash: 'admin_pin_hash',
      storedPinSalt: 'admin_pin_salt',
      userId: 0,
    );

    if (!pinResult.isSuccess) {
      if (pinResult.lockedOutRemaining != null) {
        _showError('Too many failed attempts. Try again in ${pinResult.lockedOutRemaining!.inSeconds} seconds.');
      } else {
        _showError('Incorrect PIN. ${pinResult.attemptsRemaining} attempts remaining.');
      }
      return;
    }

    await ref.read(authProvider.notifier).login(
      email: email,
      password: password,
    );
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: true,
        bottom: true,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space6,
              DesignTokens.space6,
              DesignTokens.space6,
              DesignTokens.space6,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo - icon only, no text
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280, maxHeight: 90),
                        child: Image.asset(
                          'assets/images/logo_mark.png',
                          fit: BoxFit.contain,
                          semanticLabel: 'Atlendify Logo',
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space5),

                    // Welcome text
                    Text(
                      'Welcome back',
                      style: textTheme.headlineLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Sign in to continue to Atlendify',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space6),

                    // Form card
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerHighest,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(DesignTokens.space6),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: DesignTokens.space5,
                                    vertical: DesignTokens.space4,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.outline, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.outline, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.error, width: 1.5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                                  ),
                                  labelStyle: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  hintStyle: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                  errorStyle: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.error,
                                  ),
                                  floatingLabelStyle: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                  floatingLabelAlignment: FloatingLabelAlignment.start,
                                ),
                                validator: EmailValidator.validateEmail,
                              ),
                              const SizedBox(height: DesignTokens.space4),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: DesignTokens.space5,
                                    vertical: DesignTokens.space4,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.outline, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.outline, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.error, width: 1.5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                                  ),
                                  labelStyle: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  hintStyle: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                  errorStyle: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.error,
                                  ),
                                  floatingLabelStyle: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                  floatingLabelAlignment: FloatingLabelAlignment.start,
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
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              const SizedBox(height: DesignTokens.space3),

                              // Login button (Student) - Rectangular with subtle radius
                              _RectangularButton(
                                label: _isLoading ? 'Signing in...' : 'Sign In as Student',
                                icon: _isLoading ? null : Icons.login_rounded,
                                onPressed: _isLoading ? null : _handleLogin,
                                isLoading: _isLoading,
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              const SizedBox(height: DesignTokens.space3),

                              // Login as Admin button - Rectangular outlined
                              _RectangularButton(
                                label: 'Login as Admin',
                                icon: Icons.admin_panel_settings_outlined,
                                onPressed: _isLoading ? null : _handleAdminLogin,
                                outlined: true,
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.primary,
                              ),
                              const SizedBox(height: DesignTokens.space6),

                              // Register link
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: DesignTokens.space2,
                                runSpacing: DesignTokens.space1,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go(AppRoutes.register),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: DesignTokens.space2,
                                        vertical: DesignTokens.space1,
                                      ),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: const Size(0, 0),
                                    ),
                                    child: Text(
                                      'Create account',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }
}

/// Rectangular button with subtle border radius for login screen
class _RectangularButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final Color backgroundColor;
  final Color foregroundColor;

  const _RectangularButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: AbsorbPointer(
        absorbing: onPressed == null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            splashFactory: outlined ? InkRipple.splashFactory : null,
            child: Ink(
              height: 52,
              decoration: BoxDecoration(
                color: outlined ? Colors.transparent : backgroundColor,
                border: outlined
                    ? Border.all(color: backgroundColor, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            outlined ? backgroundColor : foregroundColor,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: outlined ? foregroundColor : foregroundColor),
                            const SizedBox(width: DesignTokens.space2),
                          ],
                          Text(
                            label,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: outlined ? foregroundColor : foregroundColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Admin PIN Dialog with theme-aware styling and keyboard avoidance
class _AdminPinDialog extends StatefulWidget {
  final TextEditingController pinController;
  final ValueChanged<String> onSubmit;

  const _AdminPinDialog({
    required this.pinController,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedPadding(
              duration: DesignTokens.durationNormal,
              curve: DesignTokens.curveStandard,
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                child: KeyboardSafeDialog(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  title: 'Admin PIN Required',
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter your 4-digit admin PIN to access the admin dashboard',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
                    ],
                  ),
                  actions: [
                    _RectangularButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      onPressed: () => Navigator.pop(context),
                      outlined: true,
                      backgroundColor: colorScheme.onSurfaceVariant,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    _RectangularButton(
                      label: 'Verify',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        if (widget.pinController.text.length == 4) {
                          widget.onSubmit(widget.pinController.text);
                        }
                      },
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
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
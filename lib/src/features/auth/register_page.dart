import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/pin_boxes.dart';
import '../../core/widgets/shared_widgets.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isAdmin = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _fullNameController.dispose();
    _studentNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? _pinError;
  String? _confirmPinError;

  void _validatePin(String pin) {
    setState(() {
      if (pin.length < 4) {
        _pinError = 'PIN must be 4 digits';
      } else {
        _pinError = null;
      }
    });
  }

  void _validateConfirmPin(String pin) {
    setState(() {
      if (pin.length < 4) {
        _confirmPinError = 'PIN must be 4 digits';
      } else if (pin != _pinController.text) {
        _confirmPinError = 'PINs do not match';
      } else {
        _confirmPinError = null;
      }
    });
  }

  void _onRoleChanged(bool isAdmin) {
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ref.read(authProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _isAdmin ? 'admin' : 'student',
      fullName: _fullNameController.text.trim(),
      studentNumber: _isAdmin ? null : _studentNumberController.text.trim(),
      pin: _isAdmin ? _pinController.text : null,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final logoTopSpace = (availableHeight * 0.06).clamp(24.0, 40.0);
            final contentSpacing = (availableHeight * 0.035).clamp(16.0, 28.0);
            final bottomSpace = (availableHeight * 0.05).clamp(24.0, 40.0);

            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space6,
                  vertical: DesignTokens.space6,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: logoTopSpace),

                        // Logo mark
                        Center(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              colorScheme.primary,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/images/logo_mark.png',
                              width: 64,
                              height: 64,
                              semanticLabel: 'Atlendify Logo',
                            ),
                          ),
                        ),
                        SizedBox(height: contentSpacing),

                        // Title
                        Text(
                          'Create account',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: DesignTokens.space1),
                        Text(
                          'Join Atlendify to track attendance',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: contentSpacing),

                        // Role selector
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
                            padding: const EdgeInsets.all(DesignTokens.space2),
                            child: Row(
                              children: [
                                _buildRoleButton('Student', false, colorScheme, textTheme),
                                _buildRoleButton('Admin', true, colorScheme, textTheme),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: contentSpacing),

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
                                  // Full name (always shown)
                                  TextFormField(
                                    controller: _fullNameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      hintText: 'John Doe',
                                      prefixIcon: Icon(
                                        Icons.person_outline,
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
                                    validator: NameValidator.validateName,
                                  ),
                                  const SizedBox(height: DesignTokens.space4),

                                  // Student number (only for student)
                                  if (!_isAdmin) ...[
                                    TextFormField(
                                      controller: _studentNumberController,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'Student Number',
                                        hintText: 'e.g., STU2024001',
                                        prefixIcon: Icon(
                                          Icons.badge_outlined,
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
                                      validator: StudentNumberValidator.validateStudentNumber,
                                    ),
                                    const SizedBox(height: DesignTokens.space4),
                                  ],

                                  // Email
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

                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'At least 6 characters',
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
                                  ),
                                  const SizedBox(height: DesignTokens.space4),

                                  // Confirm Password
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: _isAdmin ? TextInputAction.next : TextInputAction.done,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      hintText: 'Re-enter password',
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                                    validator: (value) =>
                                        PasswordValidator.validateConfirmPassword(_passwordController.text, value),
                                    onFieldSubmitted: _isAdmin ? null : (_) => _handleRegister(),
                                  ),
                                  const SizedBox(height: DesignTokens.space4),

                                  // PIN fields (only for admin)
                                  if (_isAdmin) ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create 4-digit PIN',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: DesignTokens.space2),
                                        PinBoxes(
                                          controller: _pinController,
                                          disabled: _isLoading,
                                          errorText: _pinError,
                                          semanticLabel: 'PIN',
                                          autofocus: false,
                                          onSubmit: (_) {
                                            FocusScope.of(context).nextFocus();
                                          },
                                          onChanged: _validatePin,
                                        ),
                                        const SizedBox(height: DesignTokens.space4),
                                        Text(
                                          'Confirm PIN',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: DesignTokens.space2),
                                        PinBoxes(
                                          controller: _confirmPinController,
                                          disabled: _isLoading,
                                          errorText: _confirmPinError,
                                          semanticLabel: 'Confirm PIN',
                                          autofocus: false,
                                          onSubmit: (_) => _handleRegister(),
                                          onChanged: _validateConfirmPin,
                                        ),
                                        const SizedBox(height: DesignTokens.space4),
                                      ],
                                    ),
                                  ],

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

                                  // Register button
                                  PillButton(
                                    label: _isLoading ? 'Creating account...' : 'Create Account',
                                    icon: _isLoading ? null : Icons.person_add_rounded,
                                    onPressed: _isLoading ? null : _handleRegister,
                                    loading: _isLoading,
                                    isDark: Theme.of(context).brightness == Brightness.dark,
                                  ),
                                  const SizedBox(height: DesignTokens.space6),

                                  // Login link - wrapped with Wrap for graceful text wrapping
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: DesignTokens.space2,
                                    runSpacing: DesignTokens.space1,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.go(AppRoutes.login),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: DesignTokens.space2,
                                            vertical: DesignTokens.space1,
                                          ),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          minimumSize: const Size(0, 0),
                                        ),
                                        child: Text(
                                          'Sign in',
                                          style: textTheme.labelLarge?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: bottomSpace),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleButton(String label, bool isAdmin, ColorScheme colorScheme, TextTheme textTheme) {
    final selected = _isAdmin == isAdmin;
    return Flexible(
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onRoleChanged(isAdmin),
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outline,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
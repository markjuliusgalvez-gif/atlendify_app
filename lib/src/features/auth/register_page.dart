import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_provider.dart';
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

class _RegisterPageState extends ConsumerState<RegisterPage> {
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;
    final logoTint = isDark ? BrandColors.logoTintDark : BrandColors.logoTintLight;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space5), // Reduced from space6
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  DesignTokens.space8, // Reduced from space12
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Theme toggle
                  Align(
                    alignment: Alignment.topRight,
                    child: ThemeToggleButton(),
                  ),
                  const SizedBox(height: DesignTokens.space4), // Reduced from space6

                  // Logo mark
                  Center(
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(logoTint, BlendMode.srcIn),
                      child: Image.asset(
                        'assets/images/logo_mark.png',
                        width: 64, // Reduced from 72
                        height: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space6), // Reduced from space8

                  // Title
                  Text(
                    'Create account',
                    style: DesignTokens.headlineMedium.copyWith( // Reduced from headlineLarge
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space1), // Reduced from space2
                  Text(
                    'Join Atlendify to track attendance',
                    style: DesignTokens.bodySmall.copyWith( // Reduced from bodyMedium
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space6), // Reduced from space8

                  // Role selector
                  SoftCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(DesignTokens.space2), // Reduced from space3
                    child: Row(
                      children: [
                        _buildRoleButton('Student', false, isDark, textPrimary, textSecondary),
                        _buildRoleButton('Admin', true, isDark, textPrimary, textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space5), // Reduced from space6

                  // Form card
                  SoftCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(DesignTokens.space5), // Reduced from space6
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full name (always shown)
                          TextFormField(
                            controller: _fullNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'John Doe',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: NameValidator.validateName,
                          ),
                          const SizedBox(height: DesignTokens.space3), // Reduced from space4

                          // Student number (only for student)
                          if (!_isAdmin)
                            TextFormField(
                              controller: _studentNumberController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Student Number',
                                hintText: 'e.g., STU2024001',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: StudentNumberValidator.validateStudentNumber,
                            )
                          else
                            const SizedBox.shrink(),

                          if (!_isAdmin) const SizedBox(height: DesignTokens.space3), // Reduced from space4

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
                          const SizedBox(height: DesignTokens.space3), // Reduced from space4

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'At least 6 characters',
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
                          ),
                          const SizedBox(height: DesignTokens.space3), // Reduced from space4

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: _isAdmin ? TextInputAction.next : TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            validator: (value) =>
                                PasswordValidator.validateConfirmPassword(_passwordController.text, value),
                            onFieldSubmitted: _isAdmin ? null : (_) => _handleRegister(),
                          ),
                          const SizedBox(height: DesignTokens.space3), // Reduced from space4

                          // PIN fields (only for admin)
                          if (_isAdmin) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create 4-digit PIN',
                                  style: DesignTokens.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
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
                                  style: DesignTokens.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
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
                              padding: const EdgeInsets.only(bottom: DesignTokens.space2), // Reduced from space3
                              child: Text(
                                _errorMessage!,
                                style: DesignTokens.bodySmall.copyWith(
                                  color: BrandColors.absentRed,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: DesignTokens.space2), // Reduced from space3

                          // Register button
                          PillButton(
                            label: _isLoading ? 'Creating account...' : 'Create Account',
                            icon: _isLoading ? null : Icons.person_add_rounded,
                            onPressed: _isLoading ? null : _handleRegister,
                            isDark: isDark,
                            loading: _isLoading,
                          ),
                          const SizedBox(height: DesignTokens.space6),

                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Already have an account? ',
                                  style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go(AppRoutes.login),
                                child: const Text('Sign in'),
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
    );
  }

  Widget _buildRoleButton(String label, bool isAdmin, bool isDark, Color textPrimary, Color textSecondary) {
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
                    ? (isDark ? BrandColors.primary.withValues(alpha: 0.2) : BrandColors.primary.withValues(alpha: 0.1))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                border: Border.all(
                  color: selected
                      ? BrandColors.primary
                      : (isDark ? BrandColors.darkOutline : BrandColors.lightOutline),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: DesignTokens.titleMedium.copyWith(
                    color: selected
                        ? BrandColors.primary
                        : textSecondary,
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pin_service.dart';
import '../../core/database/repositories.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      builder: (context) => AlertDialog(
        title: const Text('Admin PIN Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your 4-digit admin PIN to access the admin dashboard'),
            const SizedBox(height: 16),
            TextFormField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN',
                hintText: '****',
                counterText: '',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'PIN is required';
                if (value.length != 4) return 'PIN must be 4 digits';
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                Navigator.pop(context, pinController.text);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Verify PIN against stored admin PIN
    // First check if user is already logged in
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
    // The password field is required for login; if empty, show error
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

                  // Logo full - responsive to prevent overflow
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 48,
                        maxHeight: 80,
                      ),
                      child: Image.asset(
                        'assets/images/logo_full.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Welcome text
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue to Atlendify',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
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
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 8),

                        // Error message
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Login button (Student)
                        FilledButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In as Student'),
                        ),
                        const SizedBox(height: 12),

                        // Login as Admin button
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleAdminLogin,
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Login as Admin'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: Theme.of(context).textTheme.bodyMedium,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
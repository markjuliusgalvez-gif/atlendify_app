import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/services/pin_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/pin_boxes.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  String _appVersion = '';
  String _buildNumber = '';
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _entranceController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: DesignTokens.emphasizedCurve),
    );
    _entranceController.forward();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go(AppRoutes.adminHome);
        break;
      case 1:
        context.go(AppRoutes.adminSubjects);
        break;
      case 2:
        // Settings - already here
        break;
    }
  }

  Future<void> _showChangePinDialog() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final user = authState.session.user;

    if (user.pinHash == null || user.pinSalt == null) {
      await _showSetupPinDialog();
      return;
    }

    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? currentPinError;
    String? newPinError;
    String? confirmPinError;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => _StyledDialog(
          title: 'Change PIN',
          isDark: Theme.of(context).brightness == Brightness.dark,
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // Validate all fields
                      String? currentError;
                      String? newError;
                      String? confirmError;

                      if (currentPinController.text.isEmpty) {
                        currentError = 'Current PIN is required';
                      } else if (currentPinController.text.length != 4) {
                        currentError = 'PIN must be 4 digits';
                      }

                      if (newPinController.text.isEmpty) {
                        newError = 'New PIN is required';
                      } else if (newPinController.text.length != 4) {
                        newError = 'PIN must be 4 digits';
                      }

                      if (confirmPinController.text.isEmpty) {
                        confirmError = 'Please confirm your PIN';
                      } else if (confirmPinController.text.length != 4) {
                        confirmError = 'PIN must be 4 digits';
                      } else if (newPinController.text != confirmPinController.text) {
                        confirmError = 'PINs do not match';
                      }

                      setDialogState(() {
                        currentPinError = currentError;
                        newPinError = newError;
                        confirmPinError = confirmError;
                      });

                      if (currentError != null || newError != null || confirmError != null) {
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      Navigator.pop(context);
                      await _changePin(
                        currentPinController.text,
                        newPinController.text,
                        confirmPinController.text,
                      );
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PinBoxes(
                  controller: currentPinController,
                  disabled: isSubmitting,
                  errorText: currentPinError,
                  semanticLabel: 'Current PIN',
                  autofocus: true,
                  onSubmit: (value) {
                    // Auto-focus next field
                    FocusScope.of(context).nextFocus();
                  },
                ),
                if (currentPinError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.space2),
                    child: Text(
                      currentPinError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: DesignTokens.space4),
                PinBoxes(
                  controller: newPinController,
                  disabled: isSubmitting,
                  errorText: newPinError,
                  semanticLabel: 'New PIN',
                  autofocus: false,
                  onSubmit: (value) {
                    FocusScope.of(context).nextFocus();
                  },
                ),
                if (newPinError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.space2),
                    child: Text(
                      newPinError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: DesignTokens.space4),
                PinBoxes(
                  controller: confirmPinController,
                  disabled: isSubmitting,
                  errorText: confirmPinError,
                  semanticLabel: 'Confirm New PIN',
                  autofocus: false,
                  onSubmit: (value) {
                    // Submit on last field
                  },
                ),
                if (confirmPinError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.space2),
                    child: Text(
                      confirmPinError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSetupPinDialog() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? newPinError;
    String? confirmPinError;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => _StyledDialog(
          title: 'Set Up PIN',
          isDark: Theme.of(context).brightness == Brightness.dark,
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // Validate all fields
                      String? newError;
                      String? confirmError;

                      if (newPinController.text.isEmpty) {
                        newError = 'New PIN is required';
                      } else if (newPinController.text.length != 4) {
                        newError = 'PIN must be 4 digits';
                      }

                      if (confirmPinController.text.isEmpty) {
                        confirmError = 'Please confirm your PIN';
                      } else if (confirmPinController.text.length != 4) {
                        confirmError = 'PIN must be 4 digits';
                      } else if (newPinController.text != confirmPinController.text) {
                        confirmError = 'PINs do not match';
                      }

                      setDialogState(() {
                        newPinError = newError;
                        confirmPinError = confirmError;
                      });

                      if (newError != null || confirmError != null) {
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      Navigator.pop(context);
                      await _setupPin(
                        newPinController.text,
                        confirmPinController.text,
                      );
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Set Up'),
            ),
          ],
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set up a 4-digit PIN for admin access',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                PinBoxes(
                  controller: newPinController,
                  disabled: isSubmitting,
                  errorText: newPinError,
                  semanticLabel: 'New PIN',
                  autofocus: true,
                  onSubmit: (value) {
                    FocusScope.of(context).nextFocus();
                  },
                ),
                if (newPinError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.space2),
                    child: Text(
                      newPinError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: DesignTokens.space4),
                PinBoxes(
                  controller: confirmPinController,
                  disabled: isSubmitting,
                  errorText: confirmPinError,
                  semanticLabel: 'Confirm PIN',
                  autofocus: false,
                  onSubmit: (value) {
                    // Submit on last field
                  },
                ),
                if (confirmPinError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.space2),
                    child: Text(
                      confirmPinError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changePin(String currentPin, String newPin, String confirmPin) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final user = authState.session.user;
    final pinService = PinService();

    final result = await pinService.changePin(
      currentPin: currentPin,
      newPin: newPin,
      confirmPin: confirmPin,
      storedPinHash: user.pinHash!,
      storedPinSalt: user.pinSalt!,
      userId: user.id!,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final userRepo = UserRepository();
      await userRepo.updatePin(user.id!, result.newHash!, result.newSalt!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PIN changed successfully'),
            backgroundColor: Color(0xFF1B8A3A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to change PIN'),
            backgroundColor: Color(0xFFD0021B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
          ),
        );
      }
    }
  }

  Future<void> _setupPin(String newPin, String confirmPin) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final user = authState.session.user;
    final pinService = PinService();

    final result = await pinService.setupPin(
      newPin: newPin,
      confirmPin: confirmPin,
      userId: user.id!,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final userRepo = UserRepository();
      await userRepo.updatePin(user.id!, result.hash!, result.salt!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PIN set up successfully'),
            backgroundColor: Color(0xFF1B8A3A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to set up PIN'),
            backgroundColor: Color(0xFFD0021B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => _StyledDialog(
        title: 'Logout',
        isDark: Theme.of(context).brightness == Brightness.dark,
        content: Text(
          'Are you sure you want to logout?',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
            ),
            child: Text(
              'Logout',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBody: true,
      body: SafeArea(
        top: true,
        child: authState is AuthAuthenticated
            ? _buildSettingsContent()
            : Center(
                child: Text(
                  'Not logged in',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassNavBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassNavBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.subject_outlined),
          selectedIcon: Icon(Icons.subject_rounded),
          label: 'Subjects',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
      isDark: Theme.of(context).brightness == Brightness.dark,
      accentColor: colorScheme.primary,
    );
  }

  Widget _buildSettingsContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header with profile menu
          _buildSettingsHeader(colorScheme, textTheme),
          // Settings content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space6,
                DesignTokens.space4,
                DesignTokens.space6,
                DesignTokens.space6 + 120,
              ),
              children: [
                // Appearance section
                _buildSectionHeader('Appearance', colorScheme),
                SoftCard(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.dark_mode_outlined, color: colorScheme.onSurfaceVariant),
                        title: Text('Theme', style: textTheme.titleMedium),
                        subtitle: Text('System default (Dark)', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),

                // Security section
                _buildSectionHeader('Security', colorScheme),
                SoftCard(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                        title: Text('Change Admin PIN', style: textTheme.titleMedium),
                        subtitle: Text('Update your 4-digit admin PIN', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: _showChangePinDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),

                // App Info section
                _buildSectionHeader('App Information', colorScheme),
                SoftCard(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                        title: Text('Version', style: textTheme.titleMedium),
                        subtitle: Text('$_appVersion ($_buildNumber)', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ),
                      Divider(height: 1, color: colorScheme.outlineVariant),
                      ListTile(
                        leading: Icon(Icons.description, color: colorScheme.onSurfaceVariant),
                        title: Text('Open Source Licenses', style: textTheme.titleMedium),
                        subtitle: Text('View third-party licenses', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () => showLicensePage(context: context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),

                // About section
                SoftCard(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  padding: const EdgeInsets.all(DesignTokens.space6),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: colorScheme.primary,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4),
                      Text(
                        'Atlendify',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        'Attendance Management System',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        'Version $_appVersion ($_buildNumber)',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space6),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showLogoutConfirmation,
                    icon: Icon(Icons.logout_rounded, color: colorScheme.error),
                    label: Text('Logout', style: TextStyle(color: colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: DesignTokens.space2),
      child: Text(
        title,
        style: DesignTokens.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space6,
        DesignTokens.space6,
        DesignTokens.space6,
        DesignTokens.space4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: textTheme.headlineLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Manage your preferences',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _buildProfileMenu(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(ColorScheme colorScheme, TextTheme textTheme) {
    final bgColor = colorScheme.surfaceContainerHighest;
    final authState = ref.read(authProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final user = session?.student;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            if (mounted) context.push(AppRoutes.studentProfile);
            break;
          case 'change_avatar':
            _showChangeAvatarDialog();
            break;
          case 'logout':
            _showLogoutConfirmation();
            break;
        }
      },
      itemBuilder: (context) => [
        if (user != null) ...[
          PopupMenuItem<String>(
            enabled: false,
            padding: const EdgeInsets.all(DesignTokens.space3),
            child: Row(
              children: [
                AvatarCircle(
                  name: user.fullName,
                  size: 40,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        session?.user.email ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: DesignTokens.space2),
              Text('My Profile', style: textTheme.labelLarge),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_avatar',
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: DesignTokens.space2),
              Text('Change Picture', style: textTheme.labelLarge),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: colorScheme.error),
              const SizedBox(width: DesignTokens.space2),
              Text('Logout', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: AvatarCircle(
          name: user?.fullName,
          size: 36,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  void _showChangeAvatarDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => KeyboardSafeDialog(
        isDark: Theme.of(context).brightness == Brightness.dark,
        title: 'Change Profile Picture',
        content: Text(
          'This feature will be implemented soon. You can pick an image from gallery or camera.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement image picker
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
            ),
            child: Text(
              'Pick Image',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final bool isDark;

  const _StyledDialog({
    required this.title,
    required this.content,
    required this.actions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedPadding(
      duration: DesignTokens.durationNormal,
      curve: DesignTokens.emphasizedCurve,
      padding: MediaQuery.of(context).viewInsets,
      child: AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: content,
        ),
        actions: actions,
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space2,
        ),
      ),
    );
  }
}
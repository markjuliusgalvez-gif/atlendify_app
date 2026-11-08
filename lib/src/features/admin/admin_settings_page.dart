import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/services/pin_service.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
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
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _entranceController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: DesignTokens.emphasizedCurve),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: DesignTokens.emphasizedCurve));
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
                      style: DesignTokens.bodySmall.copyWith(
                        color: BrandColors.absentRed,
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
                      style: DesignTokens.bodySmall.copyWith(
                        color: BrandColors.absentRed,
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
                      style: DesignTokens.bodySmall.copyWith(
                        color: BrandColors.absentRed,
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
                  style: DesignTokens.bodyMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? BrandColors.darkTextSecondary
                        : BrandColors.lightTextSecondary,
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
                      style: DesignTokens.bodySmall.copyWith(
                        color: BrandColors.absentRed,
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
                      style: DesignTokens.bodySmall.copyWith(
                        color: BrandColors.absentRed,
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
            backgroundColor: BrandColors.presentGreen,
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
            backgroundColor: BrandColors.absentRed,
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
            backgroundColor: BrandColors.presentGreen,
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
            backgroundColor: BrandColors.absentRed,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _StyledDialog(
        title: 'Logout',
        isDark: Theme.of(context).brightness == Brightness.dark,
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: BrandColors.absentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
            ),
            child: const Text('Logout'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: authState is AuthAuthenticated
          ? _buildSettingsContent(textPrimary, textSecondary, isDark)
          : Center(
              child: Text(
                'Not logged in',
                style: DesignTokens.bodyLarge.copyWith(color: textSecondary),
              ),
            ),
      bottomNavigationBar: _buildFloatingNavBar(isDark),
    );
  }

  Widget _buildFloatingNavBar(bool isDark) {
    return FloatingNavBar(
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
      isDark: isDark,
      accentColor: BrandColors.primary,
    );
  }

  Widget _buildSettingsContent(Color textPrimary, Color textSecondary, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Header with profile menu
            _buildSettingsHeader(textPrimary, textSecondary, isDark),
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
                  _buildSectionHeader('Appearance', textPrimary),
                  SoftCard(
                    isDark: isDark,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Theme'),
                          subtitle: const Text('Light, Dark, or System default'),
                          trailing: const ThemeToggleButton(),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space4),

                  // Security section
                  _buildSectionHeader('Security', textPrimary),
                  SoftCard(
                    isDark: isDark,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Change Admin PIN'),
                          subtitle: const Text('Update your 4-digit admin PIN'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showChangePinDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space4),

                  // App Info section
                  _buildSectionHeader('App Information', textPrimary),
                  SoftCard(
                    isDark: isDark,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Version'),
                          subtitle: Text('$_appVersion ($_buildNumber)'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Open Source Licenses'),
                          subtitle: const Text('View third-party licenses'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showLicensePage(context: context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space4),

                  // About section
                  SoftCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(DesignTokens.space6),
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: BrandColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: BrandColors.primary,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space4),
                        Text(
                          'Atlendify',
                          style: DesignTokens.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space1),
                        Text(
                          'Attendance Management System',
                          style: DesignTokens.bodyMedium.copyWith(
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space1),
                        Text(
                          'Version $_appVersion ($_buildNumber)',
                          style: DesignTokens.bodySmall.copyWith(
                            color: textSecondary.withValues(alpha: 0.7),
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
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BrandColors.absentRed,
                        side: BorderSide(color: BrandColors.absentRed),
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
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: DesignTokens.space2),
      child: Text(
        title,
        style: DesignTokens.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: BrandColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsHeader(Color textPrimary, Color textSecondary, bool isDark) {
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
                  style: DesignTokens.headlineLarge.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Manage your preferences',
                  style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: DesignTokens.space2),
          _buildProfileMenu(textPrimary, textSecondary, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(Color textPrimary, Color textSecondary, {required bool isDark}) {
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
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
                  isDark: isDark,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: DesignTokens.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        session?.user.email ?? '',
                        style: DesignTokens.bodySmall.copyWith(
                          color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
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
              Icon(Icons.person_outline_rounded, size: 20, color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
              const SizedBox(width: DesignTokens.space2),
              Text('My Profile', style: DesignTokens.labelLarge),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_avatar',
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined, size: 20, color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
              const SizedBox(width: DesignTokens.space2),
              Text('Change Picture', style: DesignTokens.labelLarge),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: BrandColors.absentRed),
              const SizedBox(width: DesignTokens.space2),
              Text('Logout', style: DesignTokens.labelLarge.copyWith(color: BrandColors.absentRed)),
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
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
            width: 1,
          ),
        ),
        child: AvatarCircle(
          name: user?.fullName,
          size: 36,
          isDark: isDark,
        ),
      ),
    );
  }

  void _showChangeAvatarDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

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
          'Change Profile Picture',
          style: DesignTokens.headlineSmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This feature will be implemented soon. You can pick an image from gallery or camera.',
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
              // TODO: Implement image picker
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
            ),
            child: Text(
              'Pick Image',
              style: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
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
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;

    return AlertDialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
        side: BorderSide(color: outlineColor, width: 1),
      ),
      title: Text(
        title,
        style: DesignTokens.headlineSmall.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space2,
      ),
    );
  }
}

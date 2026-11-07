import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/services/pin_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  int _selectedIndex = 4;
  String _appVersion = '';
  String _buildNumber = '';
  bool _isChangingPin = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
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
        context.go(AppRoutes.adminScan);
        break;
      case 3:
        context.go(AppRoutes.adminRecords);
        break;
      case 4:
        // Settings - already here
        break;
    }
  }

  Future<void> _showChangePinDialog() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final user = authState.session.user;

    if (user.pinHash == null || user.pinSalt == null) {
      // No PIN set - show setup dialog
      await _showSetupPinDialog();
      return;
    }

    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPinController,
                  decoration: const InputDecoration(
                    labelText: 'Current PIN',
                    hintText: 'Enter current 4-digit PIN',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPinController,
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                    hintText: 'Enter new 4-digit PIN',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPinController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New PIN',
                    hintText: 'Confirm new 4-digit PIN',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isChangingPin ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isChangingPin
                  ? null
                  : () async {
                      if (currentPinController.text.isEmpty ||
                          newPinController.text.isEmpty ||
                          confirmPinController.text.isEmpty) {
                        return;
                      }
                      setDialogState(() => _isChangingPin = true);
                      Navigator.pop(context);
                      await _changePin(
                        currentPinController.text,
                        newPinController.text,
                        confirmPinController.text,
                      );
                    },
              child: _isChangingPin
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetupPinDialog() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Up PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Set up a 4-digit PIN for admin access'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPinController,
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                    hintText: 'Enter 4-digit PIN',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPinController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    hintText: 'Confirm 4-digit PIN',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isChangingPin ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isChangingPin
                  ? null
                  : () async {
                      if (newPinController.text.isEmpty ||
                          confirmPinController.text.isEmpty) {
                        return;
                      }
                      setDialogState(() => _isChangingPin = true);
                      Navigator.pop(context);
                      await _setupPin(
                        newPinController.text,
                        confirmPinController.text,
                      );
                    },
              child: _isChangingPin
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Set Up'),
            ),
          ],
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
    );

    if (!mounted) return;

    setState(() => _isChangingPin = false);

    if (result.isSuccess) {
      // Update user in database
      final userRepo = UserRepository();
      await userRepo.updatePin(user.id!, result.newHash!, result.newSalt!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN changed successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to change PIN'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    );

    if (!mounted) return;

    setState(() => _isChangingPin = false);

    if (result.isSuccess) {
      // Update user in database
      final userRepo = UserRepository();
      await userRepo.updatePin(user.id!, result.hash!, result.salt!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN set up successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to set up PIN'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [const ThemeToggleButton()],
      ),
      body: authState is AuthAuthenticated
          ? _buildSettingsContent()
          : const Center(child: Text('Not logged in')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.subject_outlined),
            selectedIcon: Icon(Icons.subject),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Appearance section
        _buildSectionHeader('Appearance'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Theme'),
                subtitle: const Text('Light, Dark, or System default'),
                trailing: const ThemeToggleButton(),
                onTap: () {
                  // Theme toggle is in trailing
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Security section
        _buildSectionHeader('Security'),
        Card(
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
        const SizedBox(height: 16),

        // App Info section
        _buildSectionHeader('App Information'),
        Card(
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
        const SizedBox(height: 16),

        // About section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo_full.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.school_rounded, size: 120),
                ),
                const SizedBox(height: 16),
                Text(
                  'Atlendify',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Attendance Management System',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version $_appVersion ($_buildNumber)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Logout button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutConfirmation,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
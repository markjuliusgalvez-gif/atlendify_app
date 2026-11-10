import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  int _selectedIndex = 2;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go(AppRoutes.studentHome);
        break;
      case 1:
        context.go(AppRoutes.studentRecords);
        break;
      case 2:
        // Profile - already here
        break;
    }
  }

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history_rounded),
      label: 'My Records',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: authState is AuthAuthenticated
          ? _buildProfileContent(authState.session, colorScheme)
          : Center(
              child: Text(
                'Not logged in',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: _destinations,
        accentColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildProfileContent(UserSession session, ColorScheme colorScheme) {
    final student = session.student!;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: true,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space6,
          DesignTokens.space6,
          DesignTokens.space6,
          // Nav bar height + safe-area bottom + keyboard inset + 16
          DesignTokens.bottomBarHeight + MediaQuery.of(context).padding.bottom + 16,
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AppHeader
              AppHeader(
                title: 'Profile',
                subtitle: 'Manage your account information',
                showProfileMenu: true,
              ),
              const SizedBox(height: DesignTokens.space6),

              // Profile Card
              _buildProfileCard(student, colorScheme, textTheme),
              const SizedBox(height: DesignTokens.space5),

              // Personal Information Card
              _buildPersonalInfoCard(student, session, colorScheme, textTheme),
              const SizedBox(height: DesignTokens.space5),

              // Logout Button
              _buildLogoutButton(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Student student, ColorScheme colorScheme, TextTheme textTheme) {
    return SoftCard(
      isDark: Theme.of(context).brightness == Brightness.dark,
      padding: const EdgeInsets.all(DesignTokens.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large Avatar
          AvatarCircle(
            name: student.fullName,
            size: 96,
            isDark: true,
          ),
          const SizedBox(height: DesignTokens.space4),
          // Full Name
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              student.fullName,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          // Student ID Chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space1,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.space1),
                Text(
                  'Student ID: ${student.studentNumber}',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(
    Student student,
    UserSession session,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SoftCard(
      isDark: Theme.of(context).brightness == Brightness.dark,
      padding: const EdgeInsets.all(DesignTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Personal Information',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),

          // Full Name (Editable)
          _EditableNameRow(
            student: student,
            session: session,
            onNameChanged: (newName) {
              // The auth state will be updated by the provider
              // The UI will rebuild with the new name automatically
            },
          ),
          const SizedBox(height: DesignTokens.space3),

          // Student ID (Read-only with lock icon)
          _buildInfoRow(
            label: 'Student ID',
            value: student.studentNumber,
            colorScheme: colorScheme,
            textTheme: textTheme,
            icon: Icons.badge_outlined,
            trailingIcon: Icons.lock_outline_rounded,
            trailingTooltip: 'This cannot be changed',
          ),
          const SizedBox(height: DesignTokens.space3),

          // Email (Read-only)
          _buildInfoRow(
            label: 'Email',
            value: session.user.email,
            colorScheme: colorScheme,
            textTheme: textTheme,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: DesignTokens.space3),

          // Role (Read-only)
          _buildInfoRow(
            label: 'Role',
            value: 'Student',
            colorScheme: colorScheme,
            textTheme: textTheme,
            icon: Icons.person_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required IconData icon,
    IconData? trailingIcon,
    String? trailingTooltip,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: DesignTokens.space1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: DesignTokens.space2),
          Tooltip(
            message: trailingTooltip ?? '',
            child: Icon(
              trailingIcon,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoutButton(ColorScheme colorScheme, TextTheme textTheme) {
    return OutlinedButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
              side: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
            title: Text(
              'Logout',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
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
                  backgroundColor: const Color(0xFFD0021B),
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
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.space3),
        side: BorderSide(color: const Color(0xFFD0021B), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
        ),
      ),
      child: Text(
        'Logout',
        style: textTheme.labelLarge?.copyWith(
          color: const Color(0xFFD0021B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Editable name row with inline edit capability
class _EditableNameRow extends ConsumerStatefulWidget {
  final Student student;
  final UserSession session;
  final void Function(String) onNameChanged;

  const _EditableNameRow({
    required this.student,
    required this.session,
    required this.onNameChanged,
  });

  @override
  ConsumerState<_EditableNameRow> createState() => _EditableNameRowState();
}

class _EditableNameRowState extends ConsumerState<_EditableNameRow> {
  bool _isEditing = false;
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.student.fullName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _errorText = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.student.fullName;
      _errorText = null;
    });
  }

  Future<void> _saveName() async {
    final trimmed = _controller.text.trim();

    // Validate
    if (trimmed.length < 2 || trimmed.length > 50) {
      setState(() {
        _errorText = 'Name must be 2-50 characters';
      });
      return;
    }

    if (trimmed == widget.student.fullName) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() {
      _errorText = null;
    });

    // Show loading
    _showLoadingDialog();

    try {
      // Use the new method in AuthNotifier to update the student name
      await ref.read(authProvider.notifier).updateStudentName(trimmed);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated'),
          backgroundColor: const Color(0xFF1B8A3A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
        ),
      );

      setState(() {
        _isEditing = false;
        widget.onNameChanged(trimmed);
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update name: $e'),
          backgroundColor: const Color(0xFFD0021B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
        ),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2,
            ),
            const SizedBox(width: DesignTokens.space3),
            Text('Saving...'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isEditing) ...[
          // Display mode
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Name',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.student.fullName,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _startEditing,
                icon: Icon(
                  Icons.edit_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'Edit name',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Edit mode
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Name',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        counterText: '',
                        errorText: _errorText,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space3,
                          vertical: DesignTokens.space2,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                          borderSide: BorderSide(color: const Color(0xFFD0021B)),
                        ),
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        _errorText!,
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFD0021B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              // Save/Cancel buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _saveName,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    tooltip: 'Save',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8A3A).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFF1B8A3A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  IconButton(
                    onPressed: _cancelEditing,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Cancel',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.12),
                      foregroundColor: colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}
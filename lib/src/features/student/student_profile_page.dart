import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logout',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Are you sure you want to logout?',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
                      label: 'Logout',
                      icon: Icons.logout_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      isDark: isDark,
                      backgroundColor: const Color(0xFFD0021B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBody: true,
      body: session != null
          ? _buildProfileContent(session, context, colorScheme, textTheme)
          : Center(
              child: Text(
                'Not logged in',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
      bottomNavigationBar: _buildGlassNavBar(colorScheme),
    );
  }

  Widget _buildGlassNavBar(ColorScheme colorScheme) {
    return GlassNavBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabSelected,
      destinations: const [
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
      ],
      isDark: Theme.of(context).brightness == Brightness.dark,
      accentColor: colorScheme.primary,
    );
  }

  Widget _buildProfileContent(UserSession session, BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space6,
          DesignTokens.space4,
          DesignTokens.space6,
          DesignTokens.space6 + 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Account Information',
              isDark: isDark,
            ),
            const SizedBox(height: DesignTokens.space3),
            SoftCard(
              isDark: isDark,
              child: Column(
                children: [
                  _ProfileInfoRow(
                    label: 'Name',
                    value: session.student?.fullName ?? 'N/A',
                    icon: Icons.person_rounded,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  _ProfileInfoRow(
                    label: 'Student Number',
                    value: session.student?.studentNumber ?? 'N/A',
                    icon: Icons.badge_rounded,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  _ProfileInfoRow(
                    label: 'Email',
                    value: session.user.email,
                    icon: Icons.email_rounded,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  _ProfileInfoRow(
                    label: 'Role',
                    value: 'Student',
                    icon: Icons.school_rounded,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            SectionTitle(
              title: 'Settings',
              isDark: isDark,
            ),
            const SizedBox(height: DesignTokens.space3),
            SoftTile(
              isDark: isDark,
              onTap: () {
                // Theme toggle handled by theme provider
              },
              child: Row(
                children: [
                  Icon(Icons.color_lens_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: DesignTokens.space3),
                  Text(
                    'Theme Mode',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isDark ? 'Dark' : 'Light',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            SoftTile(
              isDark: isDark,
              onTap: () => _showLogoutDialog(context, ref),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: const Color(0xFFD0021B)),
                  const SizedBox(width: DesignTokens.space3),
                  Text(
                    'Logout',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD0021B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusCircle),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [const ThemeToggleButton()],
      ),
      body: session != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow('Name', session.student?.fullName ?? 'N/A', context),
                  _buildInfoRow('Student Number', session.student?.studentNumber ?? 'N/A', context),
                  _buildInfoRow('Email', session.user.email, context),
                  _buildInfoRow('Role', 'Student', context),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showLogoutDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: Text('Not logged in')),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        // Navigation handled by parent
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'My Records'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
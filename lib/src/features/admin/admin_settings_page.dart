import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [const ThemeToggleButton()],
      ),
      body: const Center(child: Text('Settings - Coming Soon')),
      bottomNavigationBar: _buildBottomNav(context, 4),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {},
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.subject_outlined), selectedIcon: Icon(Icons.subject), label: 'Subjects'),
        NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        NavigationDestination(icon: Icon(Icons.assessment_outlined), selectedIcon: Icon(Icons.assessment), label: 'Records'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
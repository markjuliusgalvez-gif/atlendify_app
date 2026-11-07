import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

class StudentRecordsPage extends ConsumerWidget {
  const StudentRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Records'),
        actions: [const ThemeToggleButton()],
      ),
      body: const Center(child: Text('Student Records - Coming Soon')),
      bottomNavigationBar: _buildBottomNav(context, 1),
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
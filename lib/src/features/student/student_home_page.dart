import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [const ThemeToggleButton()],
      ),
      body: const Center(child: Text('Student Home - Coming Soon')),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            // Navigate to records
            break;
          case 2:
            // Navigate to profile
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'My Records'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
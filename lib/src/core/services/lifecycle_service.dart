import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_provider.dart';

/// App lifecycle observer for handling background/foreground events
/// Automatically locks admin PIN when app goes to background
class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref ref;

  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is going to background - lock admin PIN if unlocked
        final authState = ref.read(authProvider);
        if (authState is AuthAuthenticated && authState.isAdminUnlocked) {
          ref.read(authProvider.notifier).lockPin();
        }
        break;
      case AppLifecycleState.resumed:
        // App came to foreground - could add biometric re-auth here if needed
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}

/// Provider for app lifecycle observer
final appLifecycleObserverProvider = Provider<AppLifecycleObserver>((ref) {
  return AppLifecycleObserver(ref);
});
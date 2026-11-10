import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_cast
import '../../features/auth/auth_provider.dart';
import '../../features/splash/splash_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/student/student_home_page.dart';
import '../../features/student/student_records_page.dart';
import '../../features/student/student_profile_page.dart';
import '../../features/admin/admin_home_page.dart';
import '../../features/admin/admin_subjects_page.dart';
import '../../features/admin/admin_scan_page.dart';
import '../../features/admin/subject_dashboard_page.dart';
import '../../features/admin/admin_records_page.dart';
import '../../features/admin/admin_settings_page.dart';
import '../../features/admin/pin_gate_page.dart';
import '../../core/theme/design_tokens.dart';

/// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String pinGate = '/pin-gate';

  // Student routes
  static const String studentHome = '/student/home';
  static const String studentRecords = '/student/records';
  static const String studentProfile = '/student/profile';

  // Admin routes
  static const String adminHome = '/admin/home';
  static const String adminSubjects = '/admin/subjects';
  static const String adminSubjectDashboard = '/admin/subjects/:subjectId/dashboard';
  static const String adminScan = '/admin/scan';
  static const String adminRecords = '/admin/records';
  static const String adminSettings = '/admin/settings';
}

/// Provider to get auth state fresh for router redirect
final _routerAuthStateProvider = Provider<AuthState>((ref) {
  // This forces the router to re-evaluate redirect when auth state changes
  return ref.watch(authProvider);
});

/// Provider for router refresh listenable
final _routerRefreshProvider = Provider<ChangeNotifier>((ref) {
  // Use a simple notifier that triggers refresh on auth state changes
  return _RouterRefreshNotifier(ref);
});

class _RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  _RouterRefreshNotifier(this._ref) {
    _subscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// Pure redirect logic - unit testable
String? redirectLogic(AuthState authState, String matchedLocation) {
  final isLoggedIn = authState is AuthAuthenticated;
  final isGoingToLogin = matchedLocation == AppRoutes.login;
  final isGoingToRegister = matchedLocation == AppRoutes.register;
  final isGoingToSplash = matchedLocation == AppRoutes.splash;
  final isGoingToPinGate = matchedLocation == AppRoutes.pinGate;

  // If not logged in, only allow login, register
  // Splash should redirect to login (brief show during init, then navigate away)
  if (!isLoggedIn) {
    if (isGoingToLogin || isGoingToRegister) {
      return null;
    }
    if (isGoingToSplash) {
      return AppRoutes.login;
    }
    return AppRoutes.login;
  }

  final authenticated = authState;
  final isAdmin = authenticated.isAdmin;
  final isAdminLocked = authenticated.isAdminLocked;
  final isAdminUnlocked = authenticated.isAdminUnlocked;
  final isStudent = authenticated.isStudent;

  // If logged in, redirect from splash/login/register to appropriate home/gate
  if (isGoingToSplash || isGoingToLogin || isGoingToRegister) {
    if (isAdmin) {
      return AppRoutes.pinGate;
    }
    if (isStudent) {
      return AppRoutes.studentHome;
    }
  }

  // Admin PIN gate access
  if (isGoingToPinGate) {
    if (isAdminLocked) {
      return null; // Allow access to PIN gate
    }
    if (isAdminUnlocked) {
      return AppRoutes.adminHome; // Already unlocked, go to dashboard
    }
    if (isStudent) {
      return AppRoutes.studentHome; // Students shouldn't see PIN gate
    }
  }

  // Admin dashboard routes - only allow if unlocked
  final isAdminRoute = matchedLocation.startsWith('/admin/');
  if (isAdminRoute) {
    if (isAdmin) {
      if (isAdminLocked) {
        return AppRoutes.pinGate; // Not unlocked yet, redirect to PIN gate
      }
      return null; // Unlocked admin, allow access
    }
    if (isStudent) {
      return AppRoutes.studentHome; // Student trying to access admin route
    }
  }

  // Student routes - only allow if student
  final isStudentRoute = matchedLocation.startsWith('/student/');
  if (isStudentRoute) {
    if (isStudent) {
      return null;
    }
    if (isAdmin) {
      return isAdminLocked ? AppRoutes.pinGate : AppRoutes.adminHome;
    }
  }

  // PIN gate access for students
  if (isGoingToPinGate && isStudent) {
    return AppRoutes.studentHome;
  }

  return null;
}

/// Custom fade transition page
class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionDuration: DesignTokens.durationNormal,
          reverseTransitionDuration: DesignTokens.durationNormal,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: ref.read(_routerRefreshProvider),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => FadeTransitionPage(child: const SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => FadeTransitionPage(child: const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => FadeTransitionPage(child: const RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.pinGate,
        name: 'pinGate',
        pageBuilder: (context, state) => FadeTransitionPage(child: const PinGatePage()),
      ),

      // Student routes
      GoRoute(
        path: AppRoutes.studentHome,
        name: 'studentHome',
        pageBuilder: (context, state) => FadeTransitionPage(child: const StudentHomePage()),
      ),
      GoRoute(
        path: AppRoutes.studentRecords,
        name: 'studentRecords',
        pageBuilder: (context, state) => FadeTransitionPage(child: const StudentRecordsPage()),
      ),
      GoRoute(
        path: AppRoutes.studentProfile,
        name: 'studentProfile',
        pageBuilder: (context, state) => FadeTransitionPage(child: const StudentProfilePage()),
      ),

      // Admin routes
      GoRoute(
        path: AppRoutes.adminHome,
        name: 'adminHome',
        pageBuilder: (context, state) => FadeTransitionPage(child: const AdminHomePage()),
      ),
      GoRoute(
        path: AppRoutes.adminSubjects,
        name: 'adminSubjects',
        pageBuilder: (context, state) => FadeTransitionPage(child: const AdminSubjectsPage()),
      ),
      GoRoute(
        path: AppRoutes.adminSubjectDashboard,
        name: 'adminSubjectDashboard',
        pageBuilder: (context, state) {
          final subjectId = int.parse(state.pathParameters['subjectId']!);
          return FadeTransitionPage(child: SubjectDashboardPage(subjectId: subjectId));
        },
      ),
      GoRoute(
        path: AppRoutes.adminScan,
        name: 'adminScan',
        pageBuilder: (context, state) => FadeTransitionPage(child: const AdminScanPage()),
      ),
      GoRoute(
        path: AppRoutes.adminRecords,
        name: 'adminRecords',
        pageBuilder: (context, state) => FadeTransitionPage(child: const AdminRecordsPage()),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        name: 'adminSettings',
        pageBuilder: (context, state) => FadeTransitionPage(child: const AdminSettingsPage()),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(_routerAuthStateProvider);
      return redirectLogic(authState, state.matchedLocation);
    },
  );
});
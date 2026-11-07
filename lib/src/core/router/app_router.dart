import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../features/admin/admin_records_page.dart';
import '../../features/admin/admin_settings_page.dart';
import '../../features/admin/pin_gate_page.dart';

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
  static const String adminScan = '/admin/scan';
  static const String adminRecords = '/admin/records';
  static const String adminSettings = '/admin/settings';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.pinGate,
        name: 'pinGate',
        builder: (context, state) => const PinGatePage(),
      ),

      // Student routes
      GoRoute(
        path: AppRoutes.studentHome,
        name: 'studentHome',
        builder: (context, state) => const StudentHomePage(),
      ),
      GoRoute(
        path: AppRoutes.studentRecords,
        name: 'studentRecords',
        builder: (context, state) => const StudentRecordsPage(),
      ),
      GoRoute(
        path: AppRoutes.studentProfile,
        name: 'studentProfile',
        builder: (context, state) => const StudentProfilePage(),
      ),

      // Admin routes
      GoRoute(
        path: AppRoutes.adminHome,
        name: 'adminHome',
        builder: (context, state) => const AdminHomePage(),
      ),
      GoRoute(
        path: AppRoutes.adminSubjects,
        name: 'adminSubjects',
        builder: (context, state) => const AdminSubjectsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminScan,
        name: 'adminScan',
        builder: (context, state) => const AdminScanPage(),
      ),
      GoRoute(
        path: AppRoutes.adminRecords,
        name: 'adminRecords',
        builder: (context, state) => const AdminRecordsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        name: 'adminSettings',
        builder: (context, state) => const AdminSettingsPage(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState is AuthAuthenticated;
      final matchedLocation = state.matchedLocation;
      final isGoingToLogin = matchedLocation == AppRoutes.login;
      final isGoingToRegister = matchedLocation == AppRoutes.register;
      final isGoingToSplash = matchedLocation == AppRoutes.splash;

      // If not logged in, only allow login, register, splash
      if (!isLoggedIn) {
        if (isGoingToLogin || isGoingToRegister || isGoingToSplash) {
          return null;
        }
        return AppRoutes.login;
      }

      // If logged in, redirect from splash/login/register to appropriate home
      if (isGoingToSplash || isGoingToLogin || isGoingToRegister) {
        final session = authState.session;
        if (session.isAdmin) {
          return AppRoutes.pinGate;
        }
        return AppRoutes.studentHome;
      }

      return null;
    },
  );
});
import 'package:flutter_test/flutter_test.dart';
import 'package:atlendify_app/src/core/router/app_router.dart';
import 'package:atlendify_app/src/features/auth/auth_provider.dart';
import 'package:atlendify_app/src/core/database/repositories.dart' as db;

void main() {
  group('Router Redirect Logic', () {
    test('loggedOut + /login returns null (allowed)', () {
      expect(redirectLogic(const AuthUnauthenticated(), '/login'), isNull);
    });

    test('loggedOut + /register returns null (allowed)', () {
      expect(redirectLogic(const AuthUnauthenticated(), '/register'), isNull);
    });

    test('loggedOut + / returns null (allowed)', () {
      expect(redirectLogic(const AuthUnauthenticated(), '/'), isNull);
    });

    test('loggedOut + /pin-gate redirects to /login', () {
      expect(redirectLogic(const AuthUnauthenticated(), '/pin-gate'), equals('/login'));
    });

    test('loggedOut + /admin/home redirects to /login', () {
      expect(redirectLogic(const AuthUnauthenticated(), '/admin/home'), equals('/login'));
    });

    test('loggedOut + /student/home redirects to /login', () {
      expect(redirectLogic(const AuthUnauthenticated(), '/student/home'), equals('/login'));
    });

    test('adminLocked + /login redirects to /pin-gate', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: false);
      expect(redirectLogic(state, '/login'), equals('/pin-gate'));
    });

    test('adminLocked + /register redirects to /pin-gate', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: false);
      expect(redirectLogic(state, '/register'), equals('/pin-gate'));
    });

    test('adminLocked + / redirects to /pin-gate', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: false);
      expect(redirectLogic(state, '/'), equals('/pin-gate'));
    });

    test('adminLocked + /pin-gate returns null (allowed)', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: false);
      expect(redirectLogic(state, '/pin-gate'), isNull);
    });

    test('adminLocked + /admin/home redirects to /pin-gate', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: false);
      expect(redirectLogic(state, '/admin/home'), equals('/pin-gate'));
    });

    test('adminUnlocked + /login redirects to /admin/home', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: true);
      expect(redirectLogic(state, '/login'), equals('/pin-gate')); // admin always goes to pin gate from login
    });

    test('adminUnlocked + /pin-gate redirects to /admin/home', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: true);
      expect(redirectLogic(state, '/pin-gate'), equals('/admin/home'));
    });

    test('adminUnlocked + /admin/home returns null (allowed)', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: true);
      expect(redirectLogic(state, '/admin/home'), isNull);
    });

    test('adminUnlocked + /admin/subjects returns null (allowed)', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: true);
      expect(redirectLogic(state, '/admin/subjects'), isNull);
    });

    test('student + /login redirects to /student/home', () {
      final state = _makeAuthAuthenticated(isAdmin: false, pinUnlocked: false);
      expect(redirectLogic(state, '/login'), equals('/student/home'));
    });

    test('student + /student/home returns null (allowed)', () {
      final state = _makeAuthAuthenticated(isAdmin: false, pinUnlocked: false);
      expect(redirectLogic(state, '/student/home'), isNull);
    });

    test('student + /student/records returns null (allowed)', () {
      final state = _makeAuthAuthenticated(isAdmin: false, pinUnlocked: false);
      expect(redirectLogic(state, '/student/records'), isNull);
    });

    test('student + /admin/home redirects to /student/home', () {
      final state = _makeAuthAuthenticated(isAdmin: false, pinUnlocked: false);
      expect(redirectLogic(state, '/admin/home'), equals('/student/home'));
    });

    test('student + /pin-gate redirects to /student/home', () {
      final state = _makeAuthAuthenticated(isAdmin: false, pinUnlocked: false);
      expect(redirectLogic(state, '/pin-gate'), equals('/student/home'));
    });

    test('adminLocked + /student/home redirects to /pin-gate', () {
      final state = _makeAuthAuthenticated(isAdmin: true, pinUnlocked: false);
      expect(redirectLogic(state, '/student/home'), equals('/pin-gate'));
    });
  });
}

AuthAuthenticated _makeAuthAuthenticated({required bool isAdmin, required bool pinUnlocked}) {
  final user = db.User(
    id: 1,
    email: 'test@example.com',
    passwordHash: 'hash',
    passwordSalt: 'salt',
    role: isAdmin ? 'admin' : 'student',
    pinHash: isAdmin ? 'pinhash' : null,
    pinSalt: isAdmin ? 'pinsalt' : null,
    createdAt: 0,
    updatedAt: 0,
  );
  final session = UserSession(user: user);
  return AuthAuthenticated(session, pinUnlocked: pinUnlocked);
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/repositories.dart';
import '../../core/services/auth_service.dart';

/// Current user session
class UserSession {
  final User user;
  final Student? student;

  UserSession({required this.user, this.student});

  bool get isAdmin => user.role == 'admin';
  bool get isStudent => user.role == 'student';
}

/// Auth state - explicit states for proper navigation
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserSession session;
  final bool pinUnlocked; // true when admin has entered PIN and dashboard is unlocked
  const AuthAuthenticated(this.session, {this.pinUnlocked = false});

  bool get isAdmin => session.isAdmin;
  bool get isStudent => session.isStudent;
  bool get isAdminLocked => session.isAdmin && !pinUnlocked;
  bool get isAdminUnlocked => session.isAdmin && pinUnlocked;

  AuthAuthenticated copyWith({bool? pinUnlocked}) {
    return AuthAuthenticated(session, pinUnlocked: pinUnlocked ?? this.pinUnlocked);
  }
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _userRepo = UserRepository();
  final StudentRepository _studentRepo = StudentRepository();

  AuthNotifier() : super(const AuthInitial()) {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    state = const AuthLoading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        final user = await _userRepo.getById(userId);
        if (user != null) {
          Student? student;
          if (user.role == 'student') {
            student = await _studentRepo.getByUserId(userId);
          }
          state = AuthAuthenticated(UserSession(user: user, student: student), pinUnlocked: false);
          return;
        }
      }
      state = const AuthUnauthenticated();
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _userRepo.getByEmail(email);
      if (user == null) {
        state = const AuthError('Invalid email or password');
        return;
      }

      if (!AuthService.verifyPassword(password, user.passwordHash, user.passwordSalt)) {
        state = const AuthError('Invalid email or password');
        return;
      }

      Student? student;
      if (user.role == 'student') {
        student = await _studentRepo.getByUserId(user.id!);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id!);

      state = AuthAuthenticated(UserSession(user: user, student: student), pinUnlocked: false);
    } catch (e) {
      state = AuthError('Login failed: $e');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? studentNumber,
    String? pin,
  }) async {
    state = const AuthLoading();
    try {
      // Check if email exists
      if (await _userRepo.emailExists(email)) {
        state = const AuthError('Email already registered');
        return;
      }

      // Check student number uniqueness
      if (studentNumber != null) {
        if (await _studentRepo.studentNumberExists(studentNumber)) {
          state = const AuthError('Student number already in use');
          return;
        }
      }

      final salt = AuthService.generateSalt();
      final passwordHash = AuthService.hashPassword(password, salt);
      final now = DateTime.now().millisecondsSinceEpoch;

      String? pinHash;
      String? pinSalt;
      if (pin != null && pin.isNotEmpty) {
        final pinData = AuthService.generatePinHash(pin);
        pinHash = pinData['hash'];
        pinSalt = pinData['salt'];
      }

      final user = User(
        email: email,
        passwordHash: passwordHash,
        passwordSalt: salt,
        role: role,
        pinHash: pinHash,
        pinSalt: pinSalt,
        createdAt: now,
        updatedAt: now,
      );

      final userId = await _userRepo.insert(user);

      if (role == 'student' && studentNumber != null) {
        final student = Student(
          studentNumber: studentNumber,
          fullName: fullName,
          userId: userId,
          createdAt: now,
          updatedAt: now,
        );
        await _studentRepo.insert(student);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userId);

      final createdUser = await _userRepo.getById(userId);
      if (createdUser != null) {
        Student? student;
        if (role == 'student') {
          student = await _studentRepo.getByStudentNumber(studentNumber!);
        }
        state = AuthAuthenticated(UserSession(user: createdUser, student: student), pinUnlocked: false);
      } else {
        state = const AuthError('Registration failed');
      }
    } catch (e) {
      state = AuthError('Registration failed: $e');
    }
  }

  /// Unlock PIN for admin (called after successful PIN verification)
  void unlockPin() {
    if (state is AuthAuthenticated) {
      final current = state as AuthAuthenticated;
      if (current.isAdmin) {
        state = current.copyWith(pinUnlocked: true);
      }
    }
  }

  /// Lock PIN for admin (called when app backgrounds or "Lock dashboard" pressed)
  void lockPin() {
    if (state is AuthAuthenticated) {
      final current = state as AuthAuthenticated;
      if (current.isAdmin) {
        state = current.copyWith(pinUnlocked: false);
      }
    }
  }

  /// Shared sign-out function - used by logout, Back to Login, etc.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    state = const AuthUnauthenticated();
  }

  Future<void> logout() async {
    await signOut();
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// PIN lockout state
class PinLockoutState {
  final int failedAttempts;
  final DateTime? lockoutUntil;

  PinLockoutState({
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  bool get isLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  Duration? get remainingLockout {
    if (lockoutUntil == null) return null;
    final remaining = lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}

/// PIN Service for managing PIN authentication and lockout
class PinService {
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);

  /// Get the SharedPreferences keys for a specific user
  String _prefsFailedAttemptsKey(int userId) => 'pin_failed_attempts_$userId';
  String _prefsLockoutUntilKey(int userId) => 'pin_lockout_until_$userId';

  /// Check if PIN is locked out for a specific user
  Future<PinLockoutState> getLockoutState(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final failedAttempts = prefs.getInt(_prefsFailedAttemptsKey(userId)) ?? 0;
    final lockoutUntilMs = prefs.getInt(_prefsLockoutUntilKey(userId));
    final lockoutUntil = lockoutUntilMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lockoutUntilMs)
        : null;
    return PinLockoutState(failedAttempts: failedAttempts, lockoutUntil: lockoutUntil);
  }

  /// Record a failed PIN attempt for a specific user
  Future<PinLockoutState> recordFailedAttempt(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final state = await getLockoutState(userId);
    final newFailedAttempts = state.failedAttempts + 1;

    if (newFailedAttempts >= maxFailedAttempts) {
      final lockoutUntil = DateTime.now().add(lockoutDuration);
      await prefs.setInt(_prefsFailedAttemptsKey(userId), newFailedAttempts);
      await prefs.setInt(_prefsLockoutUntilKey(userId), lockoutUntil.millisecondsSinceEpoch);
      return PinLockoutState(failedAttempts: newFailedAttempts, lockoutUntil: lockoutUntil);
    } else {
      await prefs.setInt(_prefsFailedAttemptsKey(userId), newFailedAttempts);
      return PinLockoutState(failedAttempts: newFailedAttempts, lockoutUntil: null);
    }
  }

  /// Reset failed attempts on successful PIN entry for a specific user
  Future<void> resetFailedAttempts(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsFailedAttemptsKey(userId));
    await prefs.remove(_prefsLockoutUntilKey(userId));
  }

  /// Verify PIN with lockout checking for a specific user
  Future<PinVerifyResult> verifyPin({
    required String enteredPin,
    required String storedPinHash,
    required String storedPinSalt,
    required int userId,
  }) async {
    final lockoutState = await getLockoutState(userId);
    if (lockoutState.isLockedOut) {
      return PinVerifyResult.lockedOut(lockoutState.remainingLockout!);
    }

    final isValid = AuthService.verifyPin(enteredPin, storedPinHash, storedPinSalt);
    if (isValid) {
      await resetFailedAttempts(userId);
      return PinVerifyResult.success();
    } else {
      final newState = await recordFailedAttempt(userId);
      if (newState.isLockedOut) {
        return PinVerifyResult.lockedOut(newState.remainingLockout!);
      }
      return PinVerifyResult.failed(maxFailedAttempts - newState.failedAttempts);
    }
  }

  /// Change PIN (requires current PIN verification)
  Future<PinChangeResult> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
    required String storedPinHash,
    required String storedPinSalt,
    required int userId,
  }) async {
    final newPinError = PinValidator.validatePin(newPin);
    if (newPinError != null) return PinChangeResult.error(newPinError);

    final confirmError = PinValidator.validateConfirmPin(newPin, confirmPin);
    if (confirmError != null) return PinChangeResult.error(confirmError);

    final lockoutState = await getLockoutState(userId);
    if (lockoutState.isLockedOut) {
      return PinChangeResult.error('Too many failed attempts. Try again in ${lockoutState.remainingLockout!.inSeconds} seconds.');
    }

    final isValid = AuthService.verifyPin(currentPin, storedPinHash, storedPinSalt);
    if (!isValid) {
      final newState = await recordFailedAttempt(userId);
      if (newState.isLockedOut) {
        return PinChangeResult.error('Too many failed attempts. Try again in ${newState.remainingLockout!.inSeconds} seconds.');
      }
      return PinChangeResult.error('Current PIN is incorrect. ${maxFailedAttempts - newState.failedAttempts} attempts remaining.');
    }

    await resetFailedAttempts(userId);
    final pinHash = AuthService.generatePinHash(newPin);
    return PinChangeResult.success(pinHash['hash']!, pinHash['salt']!);
  }

  /// Set up PIN for the first time (no current PIN required)
  Future<PinSetupResult> setupPin({
    required String newPin,
    required String confirmPin,
    required int userId,
  }) async {
    final newPinError = PinValidator.validatePin(newPin);
    if (newPinError != null) return PinSetupResult.error(newPinError);

    final confirmError = PinValidator.validateConfirmPin(newPin, confirmPin);
    if (confirmError != null) return PinSetupResult.error(confirmError);

    // Reset any existing lockout for this user
    await resetFailedAttempts(userId);
    final pinHash = AuthService.generatePinHash(newPin);
    return PinSetupResult.success(pinHash['hash']!, pinHash['salt']!);
  }
}

/// PIN verification result
class PinVerifyResult {
  final bool isSuccess;
  final int? attemptsRemaining;
  final Duration? lockedOutRemaining;

  const PinVerifyResult._(this.isSuccess, {this.attemptsRemaining, this.lockedOutRemaining});

  factory PinVerifyResult.success() => const PinVerifyResult._(true);
  factory PinVerifyResult.failed(int attemptsRemaining) => PinVerifyResult._(false, attemptsRemaining: attemptsRemaining);
  factory PinVerifyResult.lockedOut(Duration remaining) => PinVerifyResult._(false, lockedOutRemaining: remaining);
}

/// PIN change result
class PinChangeResult {
  final bool isSuccess;
  final String? newHash;
  final String? newSalt;
  final String? errorMessage;

  const PinChangeResult._(this.isSuccess, {this.newHash, this.newSalt, this.errorMessage});

  factory PinChangeResult.success(String newHash, String newSalt) => PinChangeResult._(true, newHash: newHash, newSalt: newSalt);
  factory PinChangeResult.error(String message) => PinChangeResult._(false, errorMessage: message);
}

/// PIN setup result
class PinSetupResult {
  final bool isSuccess;
  final String? hash;
  final String? salt;
  final String? errorMessage;

  const PinSetupResult._(this.isSuccess, {this.hash, this.salt, this.errorMessage});

  factory PinSetupResult.success(String hash, String salt) => PinSetupResult._(true, hash: hash, salt: salt);
  factory PinSetupResult.error(String message) => PinSetupResult._(false, errorMessage: message);
}


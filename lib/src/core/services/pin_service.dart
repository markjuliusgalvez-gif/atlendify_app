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

  final String _prefsFailedAttemptsKey = 'pin_failed_attempts';
  final String _prefsLockoutUntilKey = 'pin_lockout_until';

  /// Check if PIN is locked out
  Future<PinLockoutState> getLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    final failedAttempts = prefs.getInt(_prefsFailedAttemptsKey) ?? 0;
    final lockoutUntilMs = prefs.getInt(_prefsLockoutUntilKey);
    final lockoutUntil = lockoutUntilMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lockoutUntilMs)
        : null;
    return PinLockoutState(failedAttempts: failedAttempts, lockoutUntil: lockoutUntil);
  }

  /// Record a failed PIN attempt
  Future<PinLockoutState> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final state = await getLockoutState();
    final newFailedAttempts = state.failedAttempts + 1;

    if (newFailedAttempts >= maxFailedAttempts) {
      final lockoutUntil = DateTime.now().add(lockoutDuration);
      await prefs.setInt(_prefsFailedAttemptsKey, newFailedAttempts);
      await prefs.setInt(_prefsLockoutUntilKey, lockoutUntil.millisecondsSinceEpoch);
      return PinLockoutState(failedAttempts: newFailedAttempts, lockoutUntil: lockoutUntil);
    } else {
      await prefs.setInt(_prefsFailedAttemptsKey, newFailedAttempts);
      return PinLockoutState(failedAttempts: newFailedAttempts, lockoutUntil: null);
    }
  }

  /// Reset failed attempts on successful PIN entry
  Future<void> resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsFailedAttemptsKey);
    await prefs.remove(_prefsLockoutUntilKey);
  }

  /// Verify PIN with lockout checking
  Future<PinVerifyResult> verifyPin({
    required String enteredPin,
    required String storedPinHash,
    required String storedPinSalt,
  }) async {
    final lockoutState = await getLockoutState();
    if (lockoutState.isLockedOut) {
      return PinVerifyResult.lockedOut(lockoutState.remainingLockout!);
    }

    final isValid = AuthService.verifyPin(enteredPin, storedPinHash, storedPinSalt);
    if (isValid) {
      await resetFailedAttempts();
      return PinVerifyResult.success();
    } else {
      final newState = await recordFailedAttempt();
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
  }) async {
    final newPinError = PinValidator.validatePin(newPin);
    if (newPinError != null) return PinChangeResult.error(newPinError);

    final confirmError = PinValidator.validateConfirmPin(newPin, confirmPin);
    if (confirmError != null) return PinChangeResult.error(confirmError);

    final lockoutState = await getLockoutState();
    if (lockoutState.isLockedOut) {
      return PinChangeResult.error('Too many failed attempts. Try again in ${lockoutState.remainingLockout!.inSeconds} seconds.');
    }

    final isValid = AuthService.verifyPin(currentPin, storedPinHash, storedPinSalt);
    if (!isValid) {
      final newState = await recordFailedAttempt();
      if (newState.isLockedOut) {
        return PinChangeResult.error('Too many failed attempts. Try again in ${newState.remainingLockout!.inSeconds} seconds.');
      }
      return PinChangeResult.error('Current PIN is incorrect. ${maxFailedAttempts - newState.failedAttempts} attempts remaining.');
    }

    await resetFailedAttempts();
    final pinHash = AuthService.generatePinHash(newPin);
    return PinChangeResult.success(pinHash['hash']!, pinHash['salt']!);
  }

  /// Set up PIN for the first time (no current PIN required)
  Future<PinSetupResult> setupPin({
    required String newPin,
    required String confirmPin,
  }) async {
    final newPinError = PinValidator.validatePin(newPin);
    if (newPinError != null) return PinSetupResult.error(newPinError);

    final confirmError = PinValidator.validateConfirmPin(newPin, confirmPin);
    if (confirmError != null) return PinSetupResult.error(confirmError);

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


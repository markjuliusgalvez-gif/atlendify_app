import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atlendify_app/src/core/services/pin_service.dart';
import 'package:atlendify_app/src/core/services/auth_service.dart';

void main() {
  group('PinLockoutState', () {
    test('isLockedOut returns false when lockoutUntil is null', () {
      final state = PinLockoutState(failedAttempts: 3);
      expect(state.isLockedOut, isFalse);
    });

    test('isLockedOut returns false when lockoutUntil is in the past', () {
      final state = PinLockoutState(
        failedAttempts: 5,
        lockoutUntil: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(state.isLockedOut, isFalse);
    });

    test('isLockedOut returns true when lockoutUntil is in the future', () {
      final state = PinLockoutState(
        failedAttempts: 5,
        lockoutUntil: DateTime.now().add(const Duration(seconds: 30)),
      );
      expect(state.isLockedOut, isTrue);
    });

    test('remainingLockout returns null when lockoutUntil is null', () {
      final state = PinLockoutState(failedAttempts: 3);
      expect(state.remainingLockout, isNull);
    });

    test('remainingLockout returns correct duration when locked out', () {
      final future = DateTime.now().add(const Duration(seconds: 20));
      final state = PinLockoutState(
        failedAttempts: 5,
        lockoutUntil: future,
      );
      expect(state.remainingLockout!.inSeconds, greaterThan(15));
      expect(state.remainingLockout!.inSeconds, lessThanOrEqualTo(20));
    });

    test('remainingLockout returns null when lockout has expired', () {
      final state = PinLockoutState(
        failedAttempts: 5,
        lockoutUntil: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(state.remainingLockout, isNull);
    });
  });

  group('PinService', () {
    late PinService pinService;
    const testUserId = 123;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      pinService = PinService();
    });

    group('getLockoutState', () {
      test('returns default state when no prefs stored', () async {
        final state = await pinService.getLockoutState(testUserId);
        expect(state.failedAttempts, equals(0));
        expect(state.lockoutUntil, isNull);
      });

      test('returns stored failed attempts', () async {
        SharedPreferences.setMockInitialValues({'pin_failed_attempts_$testUserId': 3});
        final state = await pinService.getLockoutState(testUserId);
        expect(state.failedAttempts, equals(3));
      });

      test('returns stored lockout until', () async {
        final futureMs = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'pin_failed_attempts_$testUserId': 5,
          'pin_lockout_until_$testUserId': futureMs,
        });
        final state = await pinService.getLockoutState(testUserId);
        expect(state.failedAttempts, equals(5));
        expect(state.lockoutUntil, isNotNull);
        expect(state.isLockedOut, isTrue);
      });
    });

    group('recordFailedAttempt', () {
      test('increments failed attempts and no lockout when under max', () async {
        SharedPreferences.setMockInitialValues({'pin_failed_attempts_$testUserId': 2});
        final state = await pinService.recordFailedAttempt(testUserId);
        expect(state.failedAttempts, equals(3));
        expect(state.isLockedOut, isFalse);
      });

      test('locks out when reaching max failed attempts', () async {
        SharedPreferences.setMockInitialValues({'pin_failed_attempts_$testUserId': 4});
        final state = await pinService.recordFailedAttempt(testUserId);
        expect(state.failedAttempts, equals(5));
        expect(state.isLockedOut, isTrue);
        expect(state.lockoutUntil, isNotNull);
      });

      test('locks out when exceeding max failed attempts', () async {
        SharedPreferences.setMockInitialValues({'pin_failed_attempts_$testUserId': 5});
        final state = await pinService.recordFailedAttempt(testUserId);
        expect(state.failedAttempts, equals(6));
        expect(state.isLockedOut, isTrue);
      });
    });

    group('resetFailedAttempts', () {
      test('clears failed attempts and lockout', () async {
        SharedPreferences.setMockInitialValues({
          'pin_failed_attempts_$testUserId': 5,
          'pin_lockout_until_$testUserId': DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch,
        });

        await pinService.resetFailedAttempts(testUserId);

        final state = await pinService.getLockoutState(testUserId);
        expect(state.failedAttempts, equals(0));
        expect(state.lockoutUntil, isNull);
      });
    });

    group('verifyPin', () {
      const testPin = '1234';
      late String pinHash;
      late String pinSalt;

      setUp(() {
        final hashResult = AuthService.generatePinHash(testPin);
        pinHash = hashResult['hash']!;
        pinSalt = hashResult['salt']!;
      });

      test('returns success for correct PIN', () async {
        final result = await pinService.verifyPin(
          enteredPin: testPin,
          storedPinHash: pinHash,
          storedPinSalt: pinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isTrue);
      });

      test('returns failed for incorrect PIN', () async {
        final result = await pinService.verifyPin(
          enteredPin: '4321',
          storedPinHash: pinHash,
          storedPinSalt: pinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.attemptsRemaining, equals(4)); // 5 max - 1 failed
      });

      test('returns lockedOut when already locked out', () async {
        // First, trigger lockout by setting failed attempts and lockout time
        final lockoutUntil = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'pin_failed_attempts_$testUserId': 5,
          'pin_lockout_until_$testUserId': lockoutUntil,
        });

        final result = await pinService.verifyPin(
          enteredPin: testPin,
          storedPinHash: pinHash,
          storedPinSalt: pinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.lockedOutRemaining, isNotNull);
      });

      test('locks out after max failed attempts', () async {
        // Fail 5 times
        for (int i = 0; i < 5; i++) {
          await pinService.verifyPin(
            enteredPin: 'wrong$i',
            storedPinHash: pinHash,
            storedPinSalt: pinSalt,
            userId: testUserId,
          );
        }

        // 6th attempt should be locked out
        final result = await pinService.verifyPin(
          enteredPin: 'wrong5',
          storedPinHash: pinHash,
          storedPinSalt: pinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.lockedOutRemaining, isNotNull);
      });

      test('resets failed attempts on success after failures', () async {
        // Fail 2 times
        await pinService.verifyPin(enteredPin: 'wrong1', storedPinHash: pinHash, storedPinSalt: pinSalt, userId: testUserId);
        await pinService.verifyPin(enteredPin: 'wrong2', storedPinHash: pinHash, storedPinSalt: pinSalt, userId: testUserId);

        // Then succeed
        final result = await pinService.verifyPin(
          enteredPin: testPin,
          storedPinHash: pinHash,
          storedPinSalt: pinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isTrue);

        // Next failure should start from 1 again
        final failResult = await pinService.verifyPin(
          enteredPin: 'wrong3',
          storedPinHash: pinHash,
          storedPinSalt: pinSalt,
          userId: testUserId,
        );
        expect(failResult.attemptsRemaining, equals(4));
      });
    });

    group('changePin', () {
      const currentPin = '1234';
      const newPin = '5678';
      late String currentPinHash;
      late String currentPinSalt;

      setUp(() {
        final hashResult = AuthService.generatePinHash(currentPin);
        currentPinHash = hashResult['hash']!;
        currentPinSalt = hashResult['salt']!;
      });

      test('returns success with new hash and salt for correct current PIN', () async {
        final result = await pinService.changePin(
          currentPin: currentPin,
          newPin: newPin,
          confirmPin: newPin,
          storedPinHash: currentPinHash,
          storedPinSalt: currentPinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isTrue);
        expect(result.newHash, isNotNull);
        expect(result.newSalt, isNotNull);
        expect(result.newHash, isNot(equals(currentPinHash)));
      });

      test('returns error for invalid new PIN format', () async {
        final result = await pinService.changePin(
          currentPin: currentPin,
          newPin: '123',
          confirmPin: '123',
          storedPinHash: currentPinHash,
          storedPinSalt: currentPinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals('PIN must be 4 digits'));
      });

      test('returns error for non-matching confirm PIN', () async {
        final result = await pinService.changePin(
          currentPin: currentPin,
          newPin: newPin,
          confirmPin: '8765',
          storedPinHash: currentPinHash,
          storedPinSalt: currentPinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals('PINs do not match'));
      });

      test('returns error for incorrect current PIN', () async {
        final result = await pinService.changePin(
          currentPin: '4321',
          newPin: newPin,
          confirmPin: newPin,
          storedPinHash: currentPinHash,
          storedPinSalt: currentPinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage!.contains('Current PIN is incorrect'), isTrue);
      });

      test('returns error when locked out', () async {
        final lockoutUntil = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'pin_failed_attempts_$testUserId': 5,
          'pin_lockout_until_$testUserId': lockoutUntil,
        });
        final result = await pinService.changePin(
          currentPin: currentPin,
          newPin: newPin,
          confirmPin: newPin,
          storedPinHash: currentPinHash,
          storedPinSalt: currentPinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage!.contains('Too many failed attempts'), isTrue);
      });

      test('locks out after max failed attempts on wrong current PIN', () async {
        for (int i = 0; i < 5; i++) {
          await pinService.changePin(
            currentPin: 'wrong$i',
            newPin: newPin,
            confirmPin: newPin,
            storedPinHash: currentPinHash,
            storedPinSalt: currentPinSalt,
            userId: testUserId,
          );
        }

        final result = await pinService.changePin(
          currentPin: 'wrong5',
          newPin: newPin,
          confirmPin: newPin,
          storedPinHash: currentPinHash,
          storedPinSalt: currentPinSalt,
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage!.contains('Too many failed attempts'), isTrue);
      });
    });

    group('setupPin', () {
      const newPin = '5678';

      test('returns success with hash and salt for valid PIN', () async {
        final result = await pinService.setupPin(
          newPin: newPin,
          confirmPin: newPin,
          userId: testUserId,
        );
        expect(result.isSuccess, isTrue);
        expect(result.hash, isNotNull);
        expect(result.salt, isNotNull);

        // Verify the generated hash works
        final isValid = AuthService.verifyPin(newPin, result.hash!, result.salt!);
        expect(isValid, isTrue);
      });

      test('returns error for invalid PIN format', () async {
        final result = await pinService.setupPin(
          newPin: '123',
          confirmPin: '123',
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals('PIN must be 4 digits'));
      });

      test('returns error for non-matching confirm PIN', () async {
        final result = await pinService.setupPin(
          newPin: newPin,
          confirmPin: '8765',
          userId: testUserId,
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals('PINs do not match'));
      });
    });
  });

  group('PinVerifyResult', () {
    test('success factory creates correct result', () {
      final result = PinVerifyResult.success();
      expect(result.isSuccess, isTrue);
      expect(result.attemptsRemaining, isNull);
      expect(result.lockedOutRemaining, isNull);
    });

    test('failed factory creates correct result', () {
      final result = PinVerifyResult.failed(3);
      expect(result.isSuccess, isFalse);
      expect(result.attemptsRemaining, equals(3));
      expect(result.lockedOutRemaining, isNull);
    });

    test('lockedOut factory creates correct result', () {
      final result = PinVerifyResult.lockedOut(const Duration(seconds: 30));
      expect(result.isSuccess, isFalse);
      expect(result.attemptsRemaining, isNull);
      expect(result.lockedOutRemaining, equals(const Duration(seconds: 30)));
    });
  });

  group('PinChangeResult', () {
    test('success factory creates correct result', () {
      final result = PinChangeResult.success('newhash', 'newsalt');
      expect(result.isSuccess, isTrue);
      expect(result.newHash, equals('newhash'));
      expect(result.newSalt, equals('newsalt'));
      expect(result.errorMessage, isNull);
    });

    test('error factory creates correct result', () {
      final result = PinChangeResult.error('Error message');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Error message'));
      expect(result.newHash, isNull);
      expect(result.newSalt, isNull);
    });
  });

  group('PinSetupResult', () {
    test('success factory creates correct result', () {
      final result = PinSetupResult.success('hash', 'salt');
      expect(result.isSuccess, isTrue);
      expect(result.hash, equals('hash'));
      expect(result.salt, equals('salt'));
      expect(result.errorMessage, isNull);
    });

    test('error factory creates correct result', () {
      final result = PinSetupResult.error('Error message');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Error message'));
      expect(result.hash, isNull);
      expect(result.salt, isNull);
    });
  });
}
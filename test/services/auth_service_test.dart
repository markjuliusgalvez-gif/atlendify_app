import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlendify_app/src/core/services/auth_service.dart';

void main() {
  group('AuthService', () {
    group('generateSalt', () {
      test('generates a salt of correct length', () {
        final salt = AuthService.generateSalt();
        final decoded = base64.decode(salt);
        expect(decoded.length, equals(16));
      });

      test('generates different salts on each call', () {
        final salt1 = AuthService.generateSalt();
        final salt2 = AuthService.generateSalt();
        expect(salt1, isNot(equals(salt2)));
      });
    });

    group('hashPassword', () {
      test('produces consistent hash for same password and salt', () {
        const password = 'testPassword123';
        const salt = 'dGVzdCBzYWx0'; // base64 encoded "test salt"

        final hash1 = AuthService.hashPassword(password, salt);
        final hash2 = AuthService.hashPassword(password, salt);

        expect(hash1, equals(hash2));
        expect(hash1.length, greaterThan(0));
      });

      test('produces different hashes for different passwords', () {
        const salt = 'dGVzdCBzYWx0';

        final hash1 = AuthService.hashPassword('password1', salt);
        final hash2 = AuthService.hashPassword('password2', salt);

        expect(hash1, isNot(equals(hash2)));
      });

      test('produces different hashes for different salts', () {
        const password = 'testPassword123';

        final hash1 = AuthService.hashPassword(password, 'c2FsdDE=');
        final hash2 = AuthService.hashPassword(password, 'c2FsdDI=');

        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('verifyPassword', () {
      test('returns true for correct password', () {
        const password = 'correctPassword';
        final salt = AuthService.generateSalt();
        final hash = AuthService.hashPassword(password, salt);

        final result = AuthService.verifyPassword(password, hash, salt);
        expect(result, isTrue);
      });

      test('returns false for incorrect password', () {
        const correctPassword = 'correctPassword';
        const wrongPassword = 'wrongPassword';
        final salt = AuthService.generateSalt();
        final hash = AuthService.hashPassword(correctPassword, salt);

        final result = AuthService.verifyPassword(wrongPassword, hash, salt);
        expect(result, isFalse);
      });

      test('returns false for incorrect salt', () {
        const password = 'testPassword';
        final salt1 = AuthService.generateSalt();
        final salt2 = AuthService.generateSalt();
        final hash = AuthService.hashPassword(password, salt1);

        final result = AuthService.verifyPassword(password, hash, salt2);
        expect(result, isFalse);
      });
    });

    group('generatePinHash', () {
      test('returns hash and salt', () {
        const pin = '1234';
        final result = AuthService.generatePinHash(pin);

        expect(result.containsKey('hash'), isTrue);
        expect(result.containsKey('salt'), isTrue);
        expect(result['hash']!.length, greaterThan(0));
        expect(result['salt']!.length, greaterThan(0));
      });

      test('generated hash verifies correctly', () {
        const pin = '1234';
        final pinHash = AuthService.generatePinHash(pin);

        final isValid = AuthService.verifyPin(pin, pinHash['hash']!, pinHash['salt']!);
        expect(isValid, isTrue);
      });

      test('wrong PIN does not verify', () {
        const pin = '1234';
        const wrongPin = '4321';
        final pinHash = AuthService.generatePinHash(pin);

        final isValid = AuthService.verifyPin(wrongPin, pinHash['hash']!, pinHash['salt']!);
        expect(isValid, isFalse);
      });
    });

    group('generateId', () {
      test('generates valid UUID format', () {
        final id1 = AuthService.generateId();
        final id2 = AuthService.generateId();

        expect(id1, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')));
        expect(id2, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')));
        expect(id1, isNot(equals(id2)));
      });
    });
  });

  group('PinValidator', () {
    group('isValidPin', () {
      test('returns true for valid 4-digit PIN', () {
        expect(PinValidator.isValidPin('1234'), isTrue);
        expect(PinValidator.isValidPin('0000'), isTrue);
        expect(PinValidator.isValidPin('9999'), isTrue);
      });

      test('returns false for invalid PIN length', () {
        expect(PinValidator.isValidPin('123'), isFalse);
        expect(PinValidator.isValidPin('12345'), isFalse);
        expect(PinValidator.isValidPin(''), isFalse);
      });

      test('returns false for non-numeric PIN', () {
        expect(PinValidator.isValidPin('abcd'), isFalse);
        expect(PinValidator.isValidPin('12a4'), isFalse);
        expect(PinValidator.isValidPin('12 4'), isFalse);
      });
    });

    group('validatePin', () {
      test('returns null for valid PIN', () {
        expect(PinValidator.validatePin('1234'), isNull);
      });

      test('returns error for null PIN', () {
        expect(PinValidator.validatePin(null), equals('PIN is required'));
      });

      test('returns error for empty PIN', () {
        expect(PinValidator.validatePin(''), equals('PIN is required'));
      });

      test('returns error for invalid PIN format', () {
        expect(PinValidator.validatePin('123'), equals('PIN must be 4 digits'));
        expect(PinValidator.validatePin('abcd'), equals('PIN must be 4 digits'));
      });
    });

    group('validateConfirmPin', () {
      test('returns null for matching PINs', () {
        expect(PinValidator.validateConfirmPin('1234', '1234'), isNull);
      });

      test('returns error for empty confirm PIN', () {
        expect(PinValidator.validateConfirmPin('1234', ''), equals('Please confirm your PIN'));
      });

      test('returns error for non-matching PINs', () {
        expect(PinValidator.validateConfirmPin('1234', '4321'), equals('PINs do not match'));
      });
    });
  });

  group('EmailValidator', () {
    group('isValidEmail', () {
      test('returns true for valid emails', () {
        expect(EmailValidator.isValidEmail('test@example.com'), isTrue);
        expect(EmailValidator.isValidEmail('user.name@domain.org'), isTrue);
        expect(EmailValidator.isValidEmail('user+tag@example.co.uk'), isTrue);
      });

      test('returns false for invalid emails', () {
        expect(EmailValidator.isValidEmail('invalid'), isFalse);
        expect(EmailValidator.isValidEmail('@example.com'), isFalse);
        expect(EmailValidator.isValidEmail('test@'), isFalse);
        expect(EmailValidator.isValidEmail('test@.com'), isFalse);
        expect(EmailValidator.isValidEmail(''), isFalse);
      });
    });

    group('validateEmail', () {
      test('returns null for valid email', () {
        expect(EmailValidator.validateEmail('test@example.com'), isNull);
      });

      test('returns error for null email', () {
        expect(EmailValidator.validateEmail(null), equals('Email is required'));
      });

      test('returns error for empty email', () {
        expect(EmailValidator.validateEmail(''), equals('Email is required'));
      });

      test('returns error for invalid email format', () {
        expect(EmailValidator.validateEmail('invalid'), equals('Enter a valid email address'));
        expect(EmailValidator.validateEmail('@example.com'), equals('Enter a valid email address'));
      });
    });
  });

  group('PasswordValidator', () {
    group('isValidPassword', () {
      test('returns true for passwords meeting minimum length', () {
        expect(PasswordValidator.isValidPassword('123456'), isTrue);
        expect(PasswordValidator.isValidPassword('password123'), isTrue);
      });

      test('returns false for passwords below minimum length', () {
        expect(PasswordValidator.isValidPassword('12345'), isFalse);
        expect(PasswordValidator.isValidPassword(''), isFalse);
      });
    });

    group('validatePassword', () {
      test('returns null for valid password', () {
        expect(PasswordValidator.validatePassword('123456'), isNull);
      });

      test('returns error for null password', () {
        expect(PasswordValidator.validatePassword(null), equals('Password is required'));
      });

      test('returns error for empty password', () {
        expect(PasswordValidator.validatePassword(''), equals('Password is required'));
      });

      test('returns error for short password', () {
        expect(PasswordValidator.validatePassword('12345'), equals('Password must be at least 6 characters'));
      });
    });

    group('validateConfirmPassword', () {
      test('returns null for matching passwords', () {
        expect(PasswordValidator.validateConfirmPassword('password', 'password'), isNull);
      });

      test('returns error for empty confirm password', () {
        expect(PasswordValidator.validateConfirmPassword('password', ''), equals('Please confirm your password'));
      });

      test('returns error for non-matching passwords', () {
        expect(PasswordValidator.validateConfirmPassword('password1', 'password2'), equals('Passwords do not match'));
      });
    });
  });

  group('StudentNumberValidator', () {
    group('isValidStudentNumber', () {
      test('returns true for valid student numbers', () {
        expect(StudentNumberValidator.isValidStudentNumber('A123'), isTrue);
        expect(StudentNumberValidator.isValidStudentNumber('STUDENT001'), isTrue);
        expect(StudentNumberValidator.isValidStudentNumber('1234'), isTrue);
      });

      test('returns false for invalid student numbers', () {
        expect(StudentNumberValidator.isValidStudentNumber('123'), isFalse);
        expect(StudentNumberValidator.isValidStudentNumber(''), isFalse);
        expect(StudentNumberValidator.isValidStudentNumber('STU-DENT'), isFalse);
        expect(StudentNumberValidator.isValidStudentNumber('STU DENT'), isFalse);
      });
    });

    group('validateStudentNumber', () {
      test('returns null for valid student number', () {
        expect(StudentNumberValidator.validateStudentNumber('A123'), isNull);
      });

      test('returns error for null student number', () {
        expect(StudentNumberValidator.validateStudentNumber(null), equals('Student number is required'));
      });

      test('returns error for empty student number', () {
        expect(StudentNumberValidator.validateStudentNumber(''), equals('Student number is required'));
      });

      test('returns error for invalid student number', () {
        expect(StudentNumberValidator.validateStudentNumber('123'), equals('Student number must be at least 4 alphanumeric characters'));
        expect(StudentNumberValidator.validateStudentNumber('STU-DENT'), equals('Student number must be at least 4 alphanumeric characters'));
      });
    });
  });

  group('NameValidator', () {
    group('isValidName', () {
      test('returns true for valid names', () {
        expect(NameValidator.isValidName('John'), isTrue);
        expect(NameValidator.isValidName('John Doe'), isTrue);
        expect(NameValidator.isValidName('A B'), isTrue);
      });

      test('returns false for invalid names', () {
        expect(NameValidator.isValidName('J'), isFalse);
        expect(NameValidator.isValidName(''), isFalse);
        expect(NameValidator.isValidName('  '), isFalse);
      });
    });

    group('validateName', () {
      test('returns null for valid name', () {
        expect(NameValidator.validateName('John Doe'), isNull);
      });

      test('returns error for null name', () {
        expect(NameValidator.validateName(null), equals('Name is required'));
      });

      test('returns error for empty name', () {
        expect(NameValidator.validateName(''), equals('Name is required'));
        expect(NameValidator.validateName('   '), equals('Name is required'));
      });

      test('returns error for short name', () {
        expect(NameValidator.validateName('J'), equals('Name must be at least 2 characters'));
      });
    });
  });
}
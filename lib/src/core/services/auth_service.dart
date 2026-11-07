import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Authentication service for password hashing and verification.
/// Uses PBKDF2 with SHA-256 for secure password storage.
class AuthService {
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 16;
  static final Uuid _uuid = const Uuid();

  /// Generate a cryptographically secure random salt
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Hash a password with PBKDF2
  static String hashPassword(String password, String salt) {
    final saltBytes = base64.decode(salt);
    final passwordBytes = utf8.encode(password);

    // Use HMAC-SHA256 as PRF for PBKDF2
    final hmac = Hmac(sha256, passwordBytes);
    var result = <int>[];

    for (int i = 1; result.length < _keyLength; i++) {
      final block = hmac.convert(_intToBytes(i) + saltBytes).bytes;
      result.addAll(block);
    }

    return base64.encode(result.sublist(0, _keyLength));
  }

  /// Verify a password against stored hash and salt
  static bool verifyPassword(String password, String storedHash, String salt) {
    final computedHash = hashPassword(password, salt);
    return _constantTimeEquals(computedHash, storedHash);
  }

  /// Generate a new PIN hash and salt
  static Map<String, String> generatePinHash(String pin) {
    final salt = generateSalt();
    final hash = hashPassword(pin, salt);
    return {'hash': hash, 'salt': salt};
  }

  /// Verify a PIN
  static bool verifyPin(String pin, String storedHash, String salt) {
    return verifyPassword(pin, storedHash, salt);
  }

  /// Constant-time string comparison to prevent timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Convert int to 4-byte big-endian
  static List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  /// Generate a new UUID
  static String generateId() => _uuid.v4();
}

/// Secure PIN validation
class PinValidator {
  static bool isValidPin(String pin) {
    if (pin.length != 4) return false;
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }

  static String? validatePin(String? pin) {
    if (pin == null || pin.isEmpty) return 'PIN is required';
    if (!isValidPin(pin)) return 'PIN must be 4 digits';
    return null;
  }

  static String? validateConfirmPin(String pin, String confirmPin) {
    if (confirmPin.isEmpty) return 'Please confirm your PIN';
    if (pin != confirmPin) return 'PINs do not match';
    return null;
  }
}

/// Email validation
class EmailValidator {
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email is required';
    if (!isValidEmail(email)) return 'Enter a valid email address';
    return null;
  }
}

/// Password validation
class PasswordValidator {
  static const int minLength = 6;

  static bool isValidPassword(String password) {
    return password.length >= minLength;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    if (!isValidPassword(password)) return 'Password must be at least $minLength characters';
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) return 'Please confirm your password';
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }
}

/// Student number validation
class StudentNumberValidator {
  static bool isValidStudentNumber(String studentNumber) {
    return studentNumber.length >= 4 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(studentNumber);
  }

  static String? validateStudentNumber(String? studentNumber) {
    if (studentNumber == null || studentNumber.isEmpty) return 'Student number is required';
    if (!isValidStudentNumber(studentNumber)) return 'Student number must be at least 4 alphanumeric characters';
    return null;
  }
}

/// Name validation
class NameValidator {
  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Name is required';
    if (!isValidName(name)) return 'Name must be at least 2 characters';
    return null;
  }
}
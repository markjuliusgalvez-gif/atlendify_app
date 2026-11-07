import 'dart:convert';
import 'package:crypto/crypto.dart';

/// QR Code specification constants
const int _qrVersion = 1;
const String _appSecret = 'atlendify-secret-key-2024';

/// QR Payload structure
class QrPayload {
  final int version;
  final String studentNumber;
  final String fullNameB64; // URL-safe base64 encoded
  final String date; // yyyyMMdd
  final String signature; // Truncated HMAC-SHA256

  QrPayload({
    required this.version,
    required this.studentNumber,
    required this.fullNameB64,
    required this.date,
    required this.signature,
  });

  String toJson() {
    final map = {
      'v': version,
      'sn': studentNumber,
      'n': fullNameB64,
      'd': date,
      's': signature,
    };
    return jsonEncode(map);
  }

  static QrPayload? fromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return QrPayload(
        version: map['v'] as int,
        studentNumber: map['sn'] as String,
        fullNameB64: map['n'] as String,
        date: map['d'] as String,
        signature: map['s'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Verify the signature
  bool verifySignature() {
    final data = '$version|$studentNumber|$fullNameB64|$date';
    final expectedSig = QrService._generateSignature(data);
    return QrService._constantTimeEquals(signature, expectedSig);
  }

  /// Get the full name decoded
  String get fullName {
    try {
      return utf8.decode(base64Url.decode(fullNameB64));
    } catch (_) {
      return '';
    }
  }
}

/// QR Service for generating and verifying QR codes
class QrService {
  /// Generate a QR code payload for a student for a specific date
  static QrPayload generatePayload({
    required String studentNumber,
    required String fullName,
    required DateTime date,
  }) {
    final dateStr = _formatDate(date);
    final fullNameB64 = base64Url.encode(utf8.encode(fullName));
    final version = _qrVersion;

    final data = '$version|$studentNumber|$fullNameB64|$dateStr';
    final signature = _generateSignature(data);

    return QrPayload(
      version: version,
      studentNumber: studentNumber,
      fullNameB64: fullNameB64,
      date: dateStr,
      signature: signature,
    );
  }

  /// Generate QR code data string
  static String generateQrData({
    required String studentNumber,
    required String fullName,
    required DateTime date,
  }) {
    final payload = generatePayload(
      studentNumber: studentNumber,
      fullName: fullName,
      date: date,
    );
    return payload.toJson();
  }

  /// Parse and verify a QR code string
  static QrVerificationResult verifyQr(String qrData, DateTime scanDate) {
    final payload = QrPayload.fromJson(qrData);
    if (payload == null) {
      return QrVerificationResult.invalid('Invalid student code.');
    }

    // Check version
    if (payload.version != _qrVersion) {
      return QrVerificationResult.invalid('Unknown QR code version.');
    }

    // Verify signature
    if (!payload.verifySignature()) {
      return QrVerificationResult.invalid('Invalid student code.');
    }

    // Check date matches scan date
    final scanDateStr = _formatDate(scanDate);
    if (payload.date != scanDateStr) {
      return QrVerificationResult.oldCode(
        'Scan the latest student code. This QR code is from a previous day.',
        payload.studentNumber,
        payload.fullName,
      );
    }

    return QrVerificationResult.valid(
      payload.studentNumber,
      payload.fullName,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  static String _generateSignature(String data) {
    final key = utf8.encode(_appSecret);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(data));
    // Truncate to 16 chars for compactness
    return base64Url.encode(digest.bytes).substring(0, 16);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

/// Result of QR verification
sealed class QrVerificationResult {
  final bool isValid;

  const QrVerificationResult._(this.isValid);

  factory QrVerificationResult.valid(String studentNumber, String fullName) = ValidQrResult;
  factory QrVerificationResult.invalid(String message) = InvalidQrResult;
  factory QrVerificationResult.oldCode(String message, String studentNumber, String fullName) = OldCodeQrResult;
  factory QrVerificationResult.notEnrolled(String message) = NotEnrolledQrResult;
  factory QrVerificationResult.alreadyMarked(String message, String status, DateTime time) = AlreadyMarkedQrResult;
  factory QrVerificationResult.sessionClosed(String message) = SessionClosedQrResult;
}

class ValidQrResult extends QrVerificationResult {
  final String studentNumber;
  final String fullName;

  ValidQrResult(this.studentNumber, this.fullName) : super._(true);
}

class InvalidQrResult extends QrVerificationResult {
  final String message;

  InvalidQrResult(this.message) : super._(false);
}

class OldCodeQrResult extends QrVerificationResult {
  final String message;
  final String studentNumber;
  final String fullName;

  OldCodeQrResult(this.message, this.studentNumber, this.fullName) : super._(false);
}

class NotEnrolledQrResult extends QrVerificationResult {
  final String message;

  NotEnrolledQrResult(this.message) : super._(false);
}

class AlreadyMarkedQrResult extends QrVerificationResult {
  final String message;
  final String status;
  final DateTime time;

  AlreadyMarkedQrResult(this.message, this.status, this.time) : super._(false);
}

class SessionClosedQrResult extends QrVerificationResult {
  final String message;

  SessionClosedQrResult(this.message) : super._(false);
}
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlendify_app/src/core/services/qr_service.dart';

void main() {
  group('QrService', () {
    group('generatePayload', () {
      test('generates valid payload with correct structure', () {
        final payload = QrService.generatePayload(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 15),
        );

        expect(payload.version, equals(1));
        expect(payload.studentNumber, equals('STU001'));
        expect(payload.date, equals('20240115'));
        expect(payload.signature.length, equals(16));
        expect(payload.fullName, equals('John Doe'));
      });

      test('generates different signatures for different data', () {
        final payload1 = QrService.generatePayload(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 15),
        );

        final payload2 = QrService.generatePayload(
          studentNumber: 'STU002',
          fullName: 'Jane Doe',
          date: DateTime(2024, 1, 15),
        );

        expect(payload1.signature, isNot(equals(payload2.signature)));
      });

      test('generates different signatures for different dates', () {
        final payload1 = QrService.generatePayload(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 15),
        );

        final payload2 = QrService.generatePayload(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 16),
        );

        expect(payload1.signature, isNot(equals(payload2.signature)));
      });
    });

    group('generateQrData', () {
      test('generates valid JSON string', () {
        final qrData = QrService.generateQrData(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 15),
        );

        final json = jsonDecode(qrData) as Map<String, dynamic>;
        expect(json['v'], equals(1));
        expect(json['sn'], equals('STU001'));
        expect(json['n'], isNotEmpty);
        expect(json['d'], equals('20240115'));
        expect(json['s'], isNotEmpty);
      });
    });

    group('verifyQr', () {
      test('returns valid result for correct QR code on same date', () {
        final qrData = QrService.generateQrData(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 15),
        );

        final result = QrService.verifyQr(qrData, DateTime(2024, 1, 15));

        expect(result.isValid, isTrue);
        expect(result, isA<ValidQrResult>());
        final validResult = result as ValidQrResult;
        expect(validResult.studentNumber, equals('STU001'));
        expect(validResult.fullName, equals('John Doe'));
      });

      test('returns invalid result for tampered QR code', () {
        final qrData = QrService.generateQrData(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 15),
        );

        final json = jsonDecode(qrData) as Map<String, dynamic>;
        json['sn'] = 'STU999';
        final tamperedData = jsonEncode(json);

        final result = QrService.verifyQr(tamperedData, DateTime(2024, 1, 15));

        expect(result.isValid, isFalse);
        expect(result, isA<InvalidQrResult>());
      });

      test('returns invalid result for wrong signature', () {
        final qrData = QrService.generateQrData(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 15),
        );

        final json = jsonDecode(qrData) as Map<String, dynamic>;
        json['s'] = 'wrongsignature1234';
        final tamperedData = jsonEncode(json);

        final result = QrService.verifyQr(tamperedData, DateTime(2024, 1, 15));

        expect(result.isValid, isFalse);
        expect(result, isA<InvalidQrResult>());
      });

      test('returns old code result for previous date QR', () {
        final qrData = QrService.generateQrData(
          studentNumber: 'STU001',
          fullName: 'John Doe',
          date: DateTime(2024, 1, 14),
        );

        final result = QrService.verifyQr(qrData, DateTime(2024, 1, 15));

        expect(result.isValid, isFalse);
        expect(result, isA<OldCodeQrResult>());
        final oldCodeResult = result as OldCodeQrResult;
        expect(oldCodeResult.studentNumber, equals('STU001'));
        expect(oldCodeResult.fullName, equals('John Doe'));
      });

      test('returns invalid result for malformed JSON', () {
        final result = QrService.verifyQr('not valid json', DateTime(2024, 1, 15));

        expect(result.isValid, isFalse);
        expect(result, isA<InvalidQrResult>());
      });

      test('returns invalid result for unknown version', () {
        final json = {
          'v': 2,
          'sn': 'STU001',
          'n': base64Url.encode(utf8.encode('John Doe')),
          'd': '20240115',
          's': 'somevalidsignature',
        };

        final result = QrService.verifyQr(jsonEncode(json), DateTime(2024, 1, 15));

        expect(result.isValid, isFalse);
        expect(result, isA<InvalidQrResult>());
      });
    });

    group('QrPayload', () {
      test('fromJson parses valid JSON correctly', () {
        const json = '{"v":1,"sn":"STU001","n":"Sm9obiBEb2U=","d":"20240115","s":"signature123456"}';
        final payload = QrPayload.fromJson(json);

        expect(payload, isNotNull);
        expect(payload!.version, equals(1));
        expect(payload.studentNumber, equals('STU001'));
        expect(payload.fullNameB64, equals('Sm9obiBEb2U='));
        expect(payload.date, equals('20240115'));
        expect(payload.signature, equals('signature123456'));
      });

      test('fromJson returns null for invalid JSON', () {
        final payload = QrPayload.fromJson('invalid json');
        expect(payload, isNull);
      });

      test('fromJson returns null for missing fields', () {
        const json = '{"v":1}';
        final payload = QrPayload.fromJson(json);
        expect(payload, isNull);
      });

      test('verifySignature validates correct signature', () {
        const data = '1|STU001|Sm9obiBEb2U=|20240115';
        final key = utf8.encode('atlendify-secret-key-2024');
        final hmac = Hmac(sha256, key);
        final digest = hmac.convert(utf8.encode(data));
        final signature = base64Url.encode(digest.bytes).substring(0, 16);

        final payload = QrPayload(
          version: 1,
          studentNumber: 'STU001',
          fullNameB64: 'Sm9obiBEb2U=',
          date: '20240115',
          signature: signature,
        );

        expect(payload.verifySignature(), isTrue);
      });

      test('verifySignature rejects incorrect signature', () {
        final payload = QrPayload(
          version: 1,
          studentNumber: 'STU001',
          fullNameB64: 'Sm9obiBEb2U=',
          date: '20240115',
          signature: 'wrongsignature123',
        );

        expect(payload.verifySignature(), isFalse);
      });

      test('fullName decodes correctly', () {
        const name = 'John Doe';
        final b64 = base64Url.encode(utf8.encode(name));

        final payload = QrPayload(
          version: 1,
          studentNumber: 'STU001',
          fullNameB64: b64,
          date: '20240115',
          signature: 'signature',
        );

        expect(payload.fullName, equals(name));
      });

      test('toJson produces correct JSON', () {
        const json = '{"v":1,"sn":"STU001","n":"Sm9obiBEb2U=","d":"20240115","s":"signature123456"}';
        final payload = QrPayload.fromJson(json)!;
        final encoded = payload.toJson();

        final originalMap = jsonDecode(json) as Map<String, dynamic>;
        final encodedMap = jsonDecode(encoded) as Map<String, dynamic>;

        expect(encodedMap['v'], equals(originalMap['v']));
        expect(encodedMap['sn'], equals(originalMap['sn']));
        expect(encodedMap['n'], equals(originalMap['n']));
        expect(encodedMap['d'], equals(originalMap['d']));
        expect(encodedMap['s'], equals(originalMap['s']));
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:atlendify_app/src/core/services/status_rules.dart';

void main() {
  group('TimeUtils', () {
    group('parseTime', () {
      test('parses valid time string correctly', () {
        final time = TimeUtils.parseTime('08:30');
        final now = DateTime.now();
        expect(time.hour, equals(8));
        expect(time.minute, equals(30));
        expect(time.year, equals(now.year));
        expect(time.month, equals(now.month));
        expect(time.day, equals(now.day));
      });

      test('parses midnight correctly', () {
        final time = TimeUtils.parseTime('00:00');
        expect(time.hour, equals(0));
        expect(time.minute, equals(0));
      });

      test('parses noon correctly', () {
        final time = TimeUtils.parseTime('12:00');
        expect(time.hour, equals(12));
        expect(time.minute, equals(0));
      });

      test('throws FormatException for invalid format', () {
        expect(() => TimeUtils.parseTime('8:30'), throwsFormatException);
        expect(() => TimeUtils.parseTime('0830'), throwsFormatException);
        expect(() => TimeUtils.parseTime('25:00'), throwsFormatException);
        expect(() => TimeUtils.parseTime('12:60'), throwsFormatException);
      });
    });

    group('combineDateAndTime', () {
      test('combines date and time correctly', () {
        final date = DateTime(2024, 1, 15);
        final combined = TimeUtils.combineDateAndTime(date, '08:30');

        expect(combined.year, equals(2024));
        expect(combined.month, equals(1));
        expect(combined.day, equals(15));
        expect(combined.hour, equals(8));
        expect(combined.minute, equals(30));
      });

      test('throws FormatException for invalid time format', () {
        final date = DateTime(2024, 1, 15);
        expect(() => TimeUtils.combineDateAndTime(date, '8:30'), throwsFormatException);
        expect(() => TimeUtils.combineDateAndTime(date, '25:00'), throwsFormatException);
      });
    });

    group('formatTime', () {
      test('formats DateTime to HH:mm correctly', () {
        final dateTime = DateTime(2024, 1, 15, 8, 30);
        expect(TimeUtils.formatTime(dateTime), equals('08:30'));

        final noon = DateTime(2024, 1, 15, 12, 0);
        expect(TimeUtils.formatTime(noon), equals('12:00'));

        final midnight = DateTime(2024, 1, 15, 0, 0);
        expect(TimeUtils.formatTime(midnight), equals('00:00'));

        final pm = DateTime(2024, 1, 15, 17, 45);
        expect(TimeUtils.formatTime(pm), equals('17:45'));
      });
    });
  });

  group('StatusRules.determineStatus', () {
    final sessionDate = DateTime(2024, 1, 15);
    const startTime = '08:00';
    const lateAfterTime = '08:15';
    const endTime = '10:00';

    test('returns present when scan time is before start time', () {
      final scanTime = TimeUtils.combineDateAndTime(sessionDate, '07:59');
      final status = StatusRules.determineStatus(
        scanTime: scanTime,
        sessionStartTime: startTime,
        sessionLateAfterTime: lateAfterTime,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(status, equals(AttendanceStatus.present));
    });

    test('returns present when scan time is at start time', () {
      final scanTime = TimeUtils.combineDateAndTime(sessionDate, '08:00');
      final status = StatusRules.determineStatus(
        scanTime: scanTime,
        sessionStartTime: startTime,
        sessionLateAfterTime: lateAfterTime,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(status, equals(AttendanceStatus.present));
    });

    test('returns present when scan time is between start and lateAfter', () {
      final scanTime = TimeUtils.combineDateAndTime(sessionDate, '08:10');
      final status = StatusRules.determineStatus(
        scanTime: scanTime,
        sessionStartTime: startTime,
        sessionLateAfterTime: lateAfterTime,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(status, equals(AttendanceStatus.present));
    });

    test('returns present when scan time is at lateAfter time', () {
      final scanTime = TimeUtils.combineDateAndTime(sessionDate, '08:15');
      final status = StatusRules.determineStatus(
        scanTime: scanTime,
        sessionStartTime: startTime,
        sessionLateAfterTime: lateAfterTime,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(status, equals(AttendanceStatus.present));
    });

    test('returns late when scan time is after lateAfter but before end', () {
      final scanTime = TimeUtils.combineDateAndTime(sessionDate, '08:30');
      final status = StatusRules.determineStatus(
        scanTime: scanTime,
        sessionStartTime: startTime,
        sessionLateAfterTime: lateAfterTime,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(status, equals(AttendanceStatus.late));
    });

    test('returns late when scan time is at end time', () {
      final scanTime = TimeUtils.combineDateAndTime(sessionDate, '10:00');
      final status = StatusRules.determineStatus(
        scanTime: scanTime,
        sessionStartTime: startTime,
        sessionLateAfterTime: lateAfterTime,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(status, equals(AttendanceStatus.late));
    });

    test('returns rejected when scan time is after end time', () {
      final scanTime = TimeUtils.combineDateAndTime(sessionDate, '10:01');
      final status = StatusRules.determineStatus(
        scanTime: scanTime,
        sessionStartTime: startTime,
        sessionLateAfterTime: lateAfterTime,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(status, equals(AttendanceStatus.rejected));
    });

    test('handles edge case: scan at midnight of session day', () {
      final scanTime = TimeUtils.combineDateAndTime(sessionDate, '00:00');
      final status = StatusRules.determineStatus(
        scanTime: scanTime,
        sessionStartTime: startTime,
        sessionLateAfterTime: lateAfterTime,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(status, equals(AttendanceStatus.present));
    });
  });

  group('StatusRules.isSessionOpen', () {
    final sessionDate = DateTime(2024, 1, 15);
    const endTime = '10:00';

    test('returns true when session is open and before end time', () {
      final now = TimeUtils.combineDateAndTime(sessionDate, '09:00');
      final isOpen = StatusRules.isSessionOpen(
        now: now,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
        sessionStatus: 'open',
      );
      expect(isOpen, isTrue);
    });

    test('returns true when session is at end time', () {
      final now = TimeUtils.combineDateAndTime(sessionDate, '10:00');
      final isOpen = StatusRules.isSessionOpen(
        now: now,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
        sessionStatus: 'open',
      );
      expect(isOpen, isTrue);
    });

    test('returns false when session is after end time', () {
      final now = TimeUtils.combineDateAndTime(sessionDate, '10:01');
      final isOpen = StatusRules.isSessionOpen(
        now: now,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
        sessionStatus: 'open',
      );
      expect(isOpen, isFalse);
    });

    test('returns false when session status is closed', () {
      final now = TimeUtils.combineDateAndTime(sessionDate, '09:00');
      final isOpen = StatusRules.isSessionOpen(
        now: now,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
        sessionStatus: 'closed',
      );
      expect(isOpen, isFalse);
    });
  });

  group('StatusRules.shouldFinalize', () {
    final sessionDate = DateTime(2024, 1, 15);
    const endTime = '10:00';

    test('returns false when before end time', () {
      final now = TimeUtils.combineDateAndTime(sessionDate, '09:00');
      final shouldFinalize = StatusRules.shouldFinalize(
        now: now,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(shouldFinalize, isFalse);
    });

    test('returns false when at end time', () {
      final now = TimeUtils.combineDateAndTime(sessionDate, '10:00');
      final shouldFinalize = StatusRules.shouldFinalize(
        now: now,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(shouldFinalize, isFalse);
    });

    test('returns true when after end time', () {
      final now = TimeUtils.combineDateAndTime(sessionDate, '10:01');
      final shouldFinalize = StatusRules.shouldFinalize(
        now: now,
        sessionEndTime: endTime,
        sessionDate: sessionDate,
      );
      expect(shouldFinalize, isTrue);
    });
  });

  group('StatusResult', () {
    test('present factory creates correct result', () {
      final result = StatusResult.present();
      expect(result.status, equals(AttendanceStatus.present));
      expect(result.message, equals('Present'));
      expect(result.shouldSave, isTrue);
    });

    test('late factory creates correct result', () {
      final result = StatusResult.late();
      expect(result.status, equals(AttendanceStatus.late));
      expect(result.message, equals('Late'));
      expect(result.shouldSave, isTrue);
    });

    test('absent factory creates correct result', () {
      final result = StatusResult.absent();
      expect(result.status, equals(AttendanceStatus.absent));
      expect(result.message, equals('Absent'));
      expect(result.shouldSave, isTrue);
    });

    test('rejected factory creates correct result', () {
      final result = StatusResult.rejected('Session closed');
      expect(result.status, equals(AttendanceStatus.rejected));
      expect(result.message, equals('Session closed'));
      expect(result.shouldSave, isFalse);
    });
  });

  group('Clock interface', () {
    test('SystemClock returns current time', () {
      final clock = SystemClock();
      final now = clock.now();
      final expected = DateTime.now();
      expect(now.difference(expected).inSeconds.abs(), lessThan(1));
    });
  });
}
import 'package:intl/intl.dart';

/// Time utilities for status rules
class TimeUtils {
  static const String timeFormat = 'HH:mm';

  static DateTime parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $timeStr');
    }
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static DateTime combineDateAndTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $timeStr');
    }
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat(timeFormat).format(dateTime);
  }
}

/// Status rules for attendance
class StatusRules {
  /// Determine attendance status based on scan time and session times
  static AttendanceStatus determineStatus({
    required DateTime scanTime,
    required String sessionStartTime,
    required String sessionLateAfterTime,
    required String sessionEndTime,
    required DateTime sessionDate,
  }) {
    final start = TimeUtils.combineDateAndTime(sessionDate, sessionStartTime);
    final lateAfter = TimeUtils.combineDateAndTime(sessionDate, sessionLateAfterTime);
    final end = TimeUtils.combineDateAndTime(sessionDate, sessionEndTime);

    if (scanTime.isBefore(start) || scanTime.isAtSameMomentAs(start)) {
      return AttendanceStatus.present;
    } else if (scanTime.isBefore(lateAfter) || scanTime.isAtSameMomentAs(lateAfter)) {
      return AttendanceStatus.present;
    } else if (scanTime.isBefore(end) || scanTime.isAtSameMomentAs(end)) {
      return AttendanceStatus.late;
    } else {
      return AttendanceStatus.rejected;
    }
  }

  /// Check if a session is still open for scanning
  static bool isSessionOpen({
    required DateTime now,
    required String sessionEndTime,
    required DateTime sessionDate,
    required String sessionStatus,
  }) {
    if (sessionStatus == 'closed') return false;
    final end = TimeUtils.combineDateAndTime(sessionDate, sessionEndTime);
    return now.isBefore(end) || now.isAtSameMomentAs(end);
  }

  /// Check if session should be finalized (end time passed)
  static bool shouldFinalize({
    required DateTime now,
    required String sessionEndTime,
    required DateTime sessionDate,
  }) {
    final end = TimeUtils.combineDateAndTime(sessionDate, sessionEndTime);
    return now.isAfter(end);
  }
}

enum AttendanceStatus {
  present,
  late,
  absent,
  rejected,
}

/// Result of status determination
class StatusResult {
  final AttendanceStatus status;
  final String message;
  final bool shouldSave;

  const StatusResult(this.status, this.message, this.shouldSave);

  factory StatusResult.present() =>
      const StatusResult(AttendanceStatus.present, 'Present', true);

  factory StatusResult.late() =>
      const StatusResult(AttendanceStatus.late, 'Late', true);

  factory StatusResult.absent() =>
      const StatusResult(AttendanceStatus.absent, 'Absent', true);

  factory StatusResult.rejected(String message) =>
      StatusResult(AttendanceStatus.rejected, message, false);
}

/// Clock interface for testability
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}
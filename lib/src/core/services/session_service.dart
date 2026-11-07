import '../database/repositories.dart';
import 'status_rules.dart';

/// Session service for managing attendance sessions and finalization
class SessionService {
  final SessionRepository _sessionRepo = SessionRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final SubjectStudentRepository _subjectStudentRepo = SubjectStudentRepository();
  final Clock _clock;

  SessionService({Clock? clock}) : _clock = clock ?? SystemClock();

  /// Finalize attendance for a session - marks absent students
  Future<int> finalizeSession(int sessionId) async {
    final now = _clock.now().millisecondsSinceEpoch;
    final session = await _sessionRepo.getById(sessionId);
    if (session == null) return 0;

    // Get enrolled students for this subject
    final enrolledStudents = await _subjectStudentRepo.getEnrolledStudents(session.subjectId);
    final enrolledIds = enrolledStudents.map((s) => s.id!).toList();

    // Finalize absentees
    return await _attendanceRepo.finalizeAbsentees(sessionId, enrolledIds, now);
  }

  /// Finalize all open sessions that have passed their end time
  Future<int> finalizeOverdueSessions() async {
    final now = _clock.now();
    final sessions = await _sessionRepo.getOpenSessions();
    int totalFinalized = 0;

    for (final session in sessions) {
      final sessionDate = DateTime.parse(session.date);
      if (StatusRules.shouldFinalize(
        now: now,
        sessionEndTime: session.endTime,
        sessionDate: sessionDate,
      )) {
        totalFinalized += await finalizeSession(session.id!);
        await _sessionRepo.finalize(session.id!, now.millisecondsSinceEpoch);
      }
    }

    return totalFinalized;
  }

  /// Check and finalize sessions for a specific subject
  Future<int> checkAndFinalizeSubjectSessions(int subjectId) async {
    final now = _clock.now();
    final sessions = await _sessionRepo.getBySubject(subjectId);
    int totalFinalized = 0;

    for (final session in sessions) {
      if (session.status == 'open') {
        final sessionDate = DateTime.parse(session.date);
        if (StatusRules.shouldFinalize(
          now: now,
          sessionEndTime: session.endTime,
          sessionDate: sessionDate,
        )) {
          totalFinalized += await finalizeSession(session.id!);
          await _sessionRepo.finalize(session.id!, now.millisecondsSinceEpoch);
        }
      }
    }

    return totalFinalized;
  }

  /// Get session with attendance counts
  Future<SessionWithCounts?> getSessionWithCounts(int sessionId) async {
    final session = await _sessionRepo.getById(sessionId);
    if (session == null) return null;

    final counts = await _attendanceRepo.getCountsBySession(sessionId);
    final enrolledCount = (await _subjectStudentRepo.getEnrolledStudents(session.subjectId)).length;

    return SessionWithCounts(
      session: session,
      present: counts['present'] ?? 0,
      late: counts['late'] ?? 0,
      absent: counts['absent'] ?? 0,
      enrolled: enrolledCount,
    );
  }
}

/// Session with attendance counts
class SessionWithCounts {
  final Session session;
  final int present;
  final int late;
  final int absent;
  final int enrolled;

  SessionWithCounts({
    required this.session,
    required this.present,
    required this.late,
    required this.absent,
    required this.enrolled,
  });

  int get totalRecorded => present + late + absent;
  int get notRecorded => enrolled - totalRecorded;
}

/// Clock interface for testability
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

/// Fake clock for testing
class FakeClock implements Clock {
  final DateTime _fixedTime;
  FakeClock(this._fixedTime);
  @override
  DateTime now() => _fixedTime;
}
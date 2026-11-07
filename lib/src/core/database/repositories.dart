import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Base repository interface
abstract class BaseRepository {
  Future<Database> get db;
}

/// User model
class User {
  final int? id;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String role; // 'admin' or 'student'
  final String? pinHash;
  final String? pinSalt;
  final int createdAt;
  final int updatedAt;

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.role,
    this.pinHash,
    this.pinSalt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'role': role,
      'pin_hash': pinHash,
      'pin_salt': pinSalt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      passwordHash: map['password_hash'],
      passwordSalt: map['password_salt'],
      role: map['role'],
      pinHash: map['pin_hash'],
      pinSalt: map['pin_salt'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}

/// Student model
class Student {
  final int? id;
  final String studentNumber;
  final String fullName;
  final int? userId;
  final int createdAt;
  final int updatedAt;

  Student({
    this.id,
    required this.studentNumber,
    required this.fullName,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_number': studentNumber,
      'full_name': fullName,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      studentNumber: map['student_number'],
      fullName: map['full_name'],
      userId: map['user_id'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}

/// Subject model
class Subject {
  final int? id;
  final String name;
  final String code;
  final String section;
  final String days;
  final String startTime;
  final String lateAfterTime;
  final String endTime;
  final int createdAt;
  final int updatedAt;

  Subject({
    this.id,
    required this.name,
    required this.code,
    required this.section,
    required this.days,
    required this.startTime,
    required this.lateAfterTime,
    required this.endTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'section': section,
      'days': days,
      'start_time': startTime,
      'late_after_time': lateAfterTime,
      'end_time': endTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      section: map['section'],
      days: map['days'],
      startTime: map['start_time'],
      lateAfterTime: map['late_after_time'],
      endTime: map['end_time'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}

/// Session model
class Session {
  final int? id;
  final int subjectId;
  final String date;
  final String startTime;
  final String lateAfterTime;
  final String endTime;
  final String status; // 'open' or 'closed'
  final int? finalizedAt;
  final int createdAt;
  final int updatedAt;

  Session({
    this.id,
    required this.subjectId,
    required this.date,
    required this.startTime,
    required this.lateAfterTime,
    required this.endTime,
    required this.status,
    this.finalizedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'date': date,
      'start_time': startTime,
      'late_after_time': lateAfterTime,
      'end_time': endTime,
      'status': status,
      'finalized_at': finalizedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      subjectId: map['subject_id'],
      date: map['date'],
      startTime: map['start_time'],
      lateAfterTime: map['late_after_time'],
      endTime: map['end_time'],
      status: map['status'],
      finalizedAt: map['finalized_at'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}

/// Attendance model
class Attendance {
  final int? id;
  final int sessionId;
  final int studentId;
  final String status; // 'present', 'late', 'absent'
  final int scannedAt;
  final String source; // 'scan' or 'manual'
  final int createdAt;
  final int updatedAt;

  Attendance({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.scannedAt,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'status': status,
      'scanned_at': scannedAt,
      'source': source,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      sessionId: map['session_id'],
      studentId: map['student_id'],
      status: map['status'],
      scannedAt: map['scanned_at'],
      source: map['source'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}

/// User Repository
class UserRepository implements BaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Database> get db => _dbHelper.database;

  Future<int> insert(User user) async {
    final db = await this.db;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getByEmail(String email) async {
    final db = await this.db;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<User?> getById(int id) async {
    final db = await this.db;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<int> update(User user) async {
    final db = await this.db;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<bool> emailExists(String email) async {
    final db = await this.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE email = ?',
      [email],
    );
    return (result.first['count'] as int) > 0;
  }

  Future<int> updatePin(int userId, String pinHash, String pinSalt) async {
    final db = await this.db;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      'users',
      {
        'pin_hash': pinHash,
        'pin_salt': pinSalt,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}

/// Student Repository
class StudentRepository implements BaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Database> get db => _dbHelper.database;

  Future<int> insert(Student student) async {
    final db = await this.db;
    return await db.insert('students', student.toMap());
  }

  Future<Student?> getById(int id) async {
    final db = await this.db;
    final results = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Student.fromMap(results.first);
  }

  Future<Student?> getByStudentNumber(String studentNumber) async {
    final db = await this.db;
    final results = await db.query(
      'students',
      where: 'student_number = ?',
      whereArgs: [studentNumber],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Student.fromMap(results.first);
  }

  Future<Student?> getByUserId(int userId) async {
    final db = await this.db;
    final results = await db.query(
      'students',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Student.fromMap(results.first);
  }

  Future<List<Student>> getAll() async {
    final db = await this.db;
    final results = await db.query('students', orderBy: 'full_name ASC');
    return results.map(Student.fromMap).toList();
  }

  Future<int> update(Student student) async {
    final db = await this.db;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<bool> studentNumberExists(String studentNumber, {int? excludeId}) async {
    final db = await this.db;
    String where = 'student_number = ?';
    List<dynamic> args = [studentNumber];
    if (excludeId != null) {
      where += ' AND id != ?';
      args.add(excludeId);
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE $where',
      args,
    );
    return (result.first['count'] as int) > 0;
  }
}

/// Subject Repository
class SubjectRepository implements BaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Database> get db => _dbHelper.database;

  Future<int> insert(Subject subject) async {
    final db = await this.db;
    return await db.insert('subjects', subject.toMap());
  }

  Future<Subject?> getById(int id) async {
    final db = await this.db;
    final results = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Subject.fromMap(results.first);
  }

  Future<List<Subject>> getAll() async {
    final db = await this.db;
    final results = await db.query('subjects', orderBy: 'name ASC');
    return results.map(Subject.fromMap).toList();
  }

  Future<int> update(Subject subject) async {
    final db = await this.db;
    return await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await this.db;
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }
}

/// SubjectStudent Repository (enrollment)
class SubjectStudentRepository implements BaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Database> get db => _dbHelper.database;

  Future<int> enroll(int subjectId, int studentId) async {
    final db = await this.db;
    return await db.insert('subject_students', {
      'subject_id': subjectId,
      'student_id': studentId,
      'enrolled_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<int> unenroll(int subjectId, int studentId) async {
    final db = await this.db;
    return await db.delete(
      'subject_students',
      where: 'subject_id = ? AND student_id = ?',
      whereArgs: [subjectId, studentId],
    );
  }

  Future<List<Student>> getEnrolledStudents(int subjectId) async {
    final db = await this.db;
    final results = await db.rawQuery('''
      SELECT s.* FROM students s
      JOIN subject_students ss ON s.id = ss.student_id
      WHERE ss.subject_id = ?
      ORDER BY s.full_name ASC
    ''', [subjectId]);
    return results.map(Student.fromMap).toList();
  }

  Future<List<Subject>> getEnrolledSubjects(int studentId) async {
    final db = await this.db;
    final results = await db.rawQuery('''
      SELECT sub.* FROM subjects sub
      JOIN subject_students ss ON sub.id = ss.subject_id
      WHERE ss.student_id = ?
      ORDER BY sub.name ASC
    ''', [studentId]);
    return results.map(Subject.fromMap).toList();
  }

  Future<bool> isEnrolled(int subjectId, int studentId) async {
    final db = await this.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM subject_students WHERE subject_id = ? AND student_id = ?',
      [subjectId, studentId],
    );
    return (result.first['count'] as int) > 0;
  }
}

/// Session Repository
class SessionRepository implements BaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Database> get db => _dbHelper.database;

  Future<int> insert(Session session) async {
    final db = await this.db;
    return await db.insert('sessions', session.toMap());
  }

  Future<Session?> getById(int id) async {
    final db = await this.db;
    final results = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Session.fromMap(results.first);
  }

  Future<Session?> getBySubjectAndDate(int subjectId, String date) async {
    final db = await this.db;
    final results = await db.query(
      'sessions',
      where: 'subject_id = ? AND date = ?',
      whereArgs: [subjectId, date],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Session.fromMap(results.first);
  }

  Future<List<Session>> getBySubject(int subjectId) async {
    final db = await this.db;
    final results = await db.query(
      'sessions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'date DESC',
    );
    return results.map(Session.fromMap).toList();
  }

  Future<List<Session>> getOpenSessions() async {
    final db = await this.db;
    final results = await db.query(
      'sessions',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'date DESC, start_time ASC',
    );
    return results.map(Session.fromMap).toList();
  }

  Future<List<Session>> getSessionsForDate(String date) async {
    final db = await this.db;
    final results = await db.query(
      'sessions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'start_time ASC',
    );
    return results.map(Session.fromMap).toList();
  }

  Future<int> update(Session session) async {
    final db = await this.db;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> finalize(int sessionId, int finalizedAt) async {
    final db = await this.db;
    return await db.update(
      'sessions',
      {
        'status': 'closed',
        'finalized_at': finalizedAt,
        'updated_at': finalizedAt,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }
}

/// Attendance Repository
class AttendanceRepository implements BaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Database> get db => _dbHelper.database;

  Future<int> insert(Attendance attendance) async {
    final db = await this.db;
    return await db.insert('attendance', attendance.toMap());
  }

  Future<Attendance?> getBySessionAndStudent(int sessionId, int studentId) async {
    final db = await this.db;
    final results = await db.query(
      'attendance',
      where: 'session_id = ? AND student_id = ?',
      whereArgs: [sessionId, studentId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Attendance.fromMap(results.first);
  }

  Future<List<Attendance>> getBySession(int sessionId) async {
    final db = await this.db;
    final results = await db.query(
      'attendance',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'scanned_at ASC',
    );
    return results.map(Attendance.fromMap).toList();
  }

  Future<List<Attendance>> getByStudent(int studentId) async {
    final db = await this.db;
    final results = await db.query(
      'attendance',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'scanned_at DESC',
    );
    return results.map(Attendance.fromMap).toList();
  }

  Future<int> update(Attendance attendance) async {
    final db = await this.db;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  Future<int> finalizeAbsentees(int sessionId, List<int> enrolledStudentIds, int now) async {
    final db = await this.db;
    final batch = db.batch();

    // Get already recorded student IDs
    final recorded = await db.rawQuery(
      'SELECT student_id FROM attendance WHERE session_id = ?',
      [sessionId],
    );
    final recordedIds = recorded.map((r) => r['student_id'] as int).toSet();

    // Find absent students
    final absentIds = enrolledStudentIds.where((id) => !recordedIds.contains(id)).toList();

    for (final studentId in absentIds) {
      batch.insert('attendance', Attendance(
        sessionId: sessionId,
        studentId: studentId,
        status: 'absent',
        scannedAt: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      ).toMap());
    }

    await batch.commit(noResult: true);
    return absentIds.length;
  }

  Future<Map<String, int>> getCountsBySession(int sessionId) async {
    final db = await this.db;
    final results = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM attendance
      WHERE session_id = ?
      GROUP BY status
    ''', [sessionId]);

    final counts = <String, int>{'present': 0, 'late': 0, 'absent': 0};
    for (final row in results) {
      counts[row['status'] as String] = row['count'] as int;
    }
    return counts;
  }

  Future<List<Attendance>> search({
    int? subjectId,
    String? date,
    String? status,
    String? studentName,
  }) async {
    final db = await this.db;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (subjectId != null) {
      whereClauses.add('s.subject_id = ?');
      whereArgs.add(subjectId);
    }
    if (date != null) {
      whereClauses.add('s.date = ?');
      whereArgs.add(date);
    }
    if (status != null) {
      whereClauses.add('a.status = ?');
      whereArgs.add(status);
    }
    if (studentName != null && studentName.isNotEmpty) {
      whereClauses.add('st.full_name LIKE ?');
      whereArgs.add('%$studentName%');
    }

    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final query = '''
      SELECT a.*, s.subject_id, s.date, st.full_name, st.student_number
      FROM attendance a
      JOIN sessions s ON a.session_id = s.id
      JOIN students st ON a.student_id = st.id
      $whereSql
      ORDER BY s.date DESC, a.scanned_at DESC
    ''';

    final results = await db.rawQuery(query, whereArgs);
    return results.map(Attendance.fromMap).toList();
  }
}
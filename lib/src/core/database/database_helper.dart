import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const int _dbVersion = 1;
  static const String _dbName = 'atlendify.db';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin', 'student')),
        pin_hash TEXT,
        pin_salt TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_number TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        section TEXT NOT NULL,
        days TEXT NOT NULL,
        start_time TEXT NOT NULL,
        late_after_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE (code, section)
      )
    ''');

    await db.execute('''
      CREATE TABLE subject_students (
        subject_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        enrolled_at INTEGER NOT NULL,
        PRIMARY KEY (subject_id, student_id),
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        late_after_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('open', 'closed')) DEFAULT 'open',
        finalized_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
        UNIQUE (subject_id, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('present', 'late', 'absent')),
        scanned_at INTEGER NOT NULL,
        source TEXT NOT NULL CHECK (source IN ('scan', 'manual')),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        UNIQUE (session_id, student_id)
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_students_student_number ON students(student_number)');
    await db.execute('CREATE INDEX idx_sessions_subject_date ON sessions(subject_id, date)');
    await db.execute('CREATE INDEX idx_attendance_session ON attendance(session_id)');
    await db.execute('CREATE INDEX idx_attendance_student ON attendance(student_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE users ADD COLUMN ...');
    // }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
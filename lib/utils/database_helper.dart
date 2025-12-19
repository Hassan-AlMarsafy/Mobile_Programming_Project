import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hydroponic_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTables(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Sessions table for auto-login
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL
      )
    ''');

    // Password reset tokens
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reset_tokens(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        used INTEGER DEFAULT 0
      )
    ''');
  }

  // User CRUD operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUserPassword(int userId, String newPassword) async {
    Database db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Session management
  Future<void> saveSession(int userId, String token) async {
    Database db = await database;
    await db.delete('sessions'); // Clear previous sessions
    await db.insert('sessions', {
      'user_id': userId,
      'token': token,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'sessions',
      where: 'expires_at > ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> clearSession() async {
    Database db = await database;
    await db.delete('sessions');
  }

  // Password reset tokens
  Future<String> createResetToken(int userId) async {
    Database db = await database;
    String token = DateTime.now().millisecondsSinceEpoch.toString() + userId.toString();

    await db.insert('reset_tokens', {
      'user_id': userId,
      'token': token,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      'used': 0,
    });

    return token;
  }

  Future<bool> validateResetToken(String token) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'reset_tokens',
      where: 'token = ? AND expires_at > ? AND used = 0',
      whereArgs: [token, DateTime.now().toIso8601String()],
    );
    return result.isNotEmpty;
  }

  Future<void> markTokenUsed(String token) async {
    Database db = await database;
    await db.update(
      'reset_tokens',
      {'used': 1},
      where: 'token = ?',
      whereArgs: [token],
    );
  }

  Future<int?> getUserIdByToken(String token) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'reset_tokens',
      where: 'token = ?',
      whereArgs: [token],
    );
    return result.isNotEmpty ? result.first['user_id'] : null;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
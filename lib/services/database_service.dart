import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_data.dart';
import '../models/actuator_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hydroponic_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Sensor history for analytics
    await db.execute('''
      CREATE TABLE sensor_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        temperature REAL,
        ph REAL,
        water_level REAL,
        tds REAL,
        light_intensity REAL,
        timestamp INTEGER
      )
    ''');

    // Cached current sensor data for offline mode
    await db.execute('''
      CREATE TABLE cached_sensor_data (
        id INTEGER PRIMARY KEY,
        temperature REAL,
        ph REAL,
        water_level REAL,
        tds REAL,
        light_intensity REAL,
        timestamp INTEGER
      )
    ''');

    // Cached actuator data for offline mode
    await db.execute('''
      CREATE TABLE cached_actuator_data (
        id INTEGER PRIMARY KEY,
        water_pump INTEGER,
        nutrient_pump INTEGER,
        lights INTEGER,
        fan INTEGER,
        timestamp INTEGER
      )
    ''');

    // Alert history
    await db.execute('''
      CREATE TABLE alert_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensor_type TEXT,
        message TEXT,
        severity TEXT,
        timestamp INTEGER
      )
    ''');

    // Threshold profiles
    await db.execute('''
      CREATE TABLE threshold_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        temp_min REAL,
        temp_max REAL,
        ph_min REAL,
        ph_max REAL,
        water_min REAL,
        water_max REAL,
        tds_min REAL,
        tds_max REAL,
        light_min REAL,
        light_max REAL,
        is_active INTEGER DEFAULT 0
      )
    ''');

    // Offline command queue
    await db.execute('''
      CREATE TABLE command_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        command_type TEXT,
        payload TEXT,
        created_at INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Insert default threshold profiles
    await db.insert('threshold_profiles', {
      'name': 'Default',
      'temp_min': 18.0,
      'temp_max': 28.0,
      'ph_min': 5.5,
      'ph_max': 6.5,
      'water_min': 20.0,
      'water_max': 100.0,
      'tds_min': 800.0,
      'tds_max': 1500.0,
      'light_min': 200.0,
      'light_max': 1000.0,
      'is_active': 1,
    });

    await db.insert('threshold_profiles', {
      'name': 'Lettuce',
      'temp_min': 15.0,
      'temp_max': 22.0,
      'ph_min': 5.5,
      'ph_max': 6.5,
      'water_min': 30.0,
      'water_max': 100.0,
      'tds_min': 560.0,
      'tds_max': 840.0,
      'light_min': 150.0,
      'light_max': 600.0,
      'is_active': 0,
    });

    await db.insert('threshold_profiles', {
      'name': 'Tomatoes',
      'temp_min': 18.0,
      'temp_max': 26.0,
      'ph_min': 5.8,
      'ph_max': 6.8,
      'water_min': 30.0,
      'water_max': 100.0,
      'tds_min': 1400.0,
      'tds_max': 3500.0,
      'light_min': 300.0,
      'light_max': 1000.0,
      'is_active': 0,
    });
  }

  // ============ SENSOR HISTORY (for analytics) ============

  Future<void> addSensorHistory(SensorData data) async {
    final db = await database;
    await db.insert('sensor_history', {
      'temperature': data.temperature,
      'ph': data.pH,
      'water_level': data.waterLevel,
      'tds': data.tds,
      'light_intensity': data.lightIntensity,
      'timestamp': data.timestamp.millisecondsSinceEpoch,
    });

    // Keep only last 7 days of data (cleanup)
    final cutoff =
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    await db
        .delete('sensor_history', where: 'timestamp < ?', whereArgs: [cutoff]);
  }

  Future<List<Map<String, dynamic>>> getSensorHistory({int days = 7}) async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

    return await db.query(
      'sensor_history',
      where: 'timestamp > ?',
      whereArgs: [cutoff],
      orderBy: 'timestamp ASC',
    );
  }

  Future<Map<String, dynamic>> getSensorStatistics({int days = 7}) async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT 
        AVG(temperature) as avg_temp,
        MIN(temperature) as min_temp,
        MAX(temperature) as max_temp,
        AVG(ph) as avg_ph,
        MIN(ph) as min_ph,
        MAX(ph) as max_ph,
        AVG(water_level) as avg_water,
        MIN(water_level) as min_water,
        MAX(water_level) as max_water,
        AVG(tds) as avg_tds,
        MIN(tds) as min_tds,
        MAX(tds) as max_tds,
        AVG(light_intensity) as avg_light,
        MIN(light_intensity) as min_light,
        MAX(light_intensity) as max_light,
        COUNT(*) as data_points
      FROM sensor_history
      WHERE timestamp > ?
    ''', [cutoff]);

    return result.isNotEmpty ? result.first : {};
  }

  // ============ CACHED SENSOR DATA (for offline) ============

  Future<void> cacheSensorData(SensorData data) async {
    final db = await database;
    await db.insert(
      'cached_sensor_data',
      {
        'id': 1, // Single row for current data
        'temperature': data.temperature,
        'ph': data.pH,
        'water_level': data.waterLevel,
        'tds': data.tds,
        'light_intensity': data.lightIntensity,
        'timestamp': data.timestamp.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SensorData?> getCachedSensorData() async {
    final db = await database;
    final result = await db.query('cached_sensor_data', where: 'id = 1');

    if (result.isNotEmpty) {
      final row = result.first;
      return SensorData(
        temperature: (row['temperature'] as num).toDouble(),
        pH: (row['ph'] as num).toDouble(),
        waterLevel: (row['water_level'] as num).toDouble(),
        tds: (row['tds'] as num).toDouble(),
        lightIntensity: (row['light_intensity'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      );
    }
    return null;
  }

  // ============ CACHED ACTUATOR DATA (for offline) ============

  Future<void> cacheActuatorData(ActuatorData data) async {
    final db = await database;
    await db.insert(
      'cached_actuator_data',
      {
        'id': 1,
        'water_pump': data.waterPump ? 1 : 0,
        'nutrient_pump': data.nutrientPump ? 1 : 0,
        'lights': data.lights ? 1 : 0,
        'fan': data.fan ? 1 : 0,
        'timestamp': data.timestamp.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ActuatorData?> getCachedActuatorData() async {
    final db = await database;
    final result = await db.query('cached_actuator_data', where: 'id = 1');

    if (result.isNotEmpty) {
      final row = result.first;
      return ActuatorData(
        waterPump: row['water_pump'] == 1,
        nutrientPump: row['nutrient_pump'] == 1,
        lights: row['lights'] == 1,
        fan: row['fan'] == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      );
    }
    return null;
  }

  // ============ ALERT HISTORY ============

  Future<void> addAlert({
    required String sensorType,
    required String message,
    required String severity,
  }) async {
    final db = await database;
    await db.insert('alert_history', {
      'sensor_type': sensorType,
      'message': message,
      'severity': severity,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Keep only last 100 alerts
    await db.rawDelete('''
      DELETE FROM alert_history WHERE id NOT IN (
        SELECT id FROM alert_history ORDER BY timestamp DESC LIMIT 100
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getAlertHistory({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'alert_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // ============ THRESHOLD PROFILES ============

  Future<List<Map<String, dynamic>>> getThresholdProfiles() async {
    final db = await database;
    return await db.query('threshold_profiles', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getActiveProfile() async {
    final db = await database;
    final result = await db.query(
      'threshold_profiles',
      where: 'is_active = 1',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> setActiveProfile(int profileId) async {
    final db = await database;
    await db.update('threshold_profiles', {'is_active': 0});
    await db.update(
      'threshold_profiles',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [profileId],
    );
  }

  Future<int> addThresholdProfile(Map<String, dynamic> profile) async {
    final db = await database;
    return await db.insert('threshold_profiles', profile);
  }

  Future<void> updateThresholdProfile(
      int id, Map<String, dynamic> profile) async {
    final db = await database;
    await db.update('threshold_profiles', profile,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteThresholdProfile(int id) async {
    final db = await database;
    await db.delete('threshold_profiles', where: 'id = ?', whereArgs: [id]);
  }

  // ============ COMMAND QUEUE (for offline mode) ============

  Future<void> queueCommand({
    required String commandType,
    required String payload,
  }) async {
    final db = await database;
    await db.insert('command_queue', {
      'command_type': commandType,
      'payload': payload,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsynedCommands() async {
    final db = await database;
    return await db.query(
      'command_queue',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markCommandSynced(int id) async {
    final db = await database;
    await db.update(
      'command_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearSyncedCommands() async {
    final db = await database;
    await db.delete('command_queue', where: 'synced = 1');
  }

  // ============ UTILITY ============

  Future<DateTime?> getLastSyncTime() async {
    final data = await getCachedSensorData();
    return data?.timestamp;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sensor_history');
    await db.delete('cached_sensor_data');
    await db.delete('cached_actuator_data');
    await db.delete('alert_history');
    await db.delete('command_queue');
  }
}

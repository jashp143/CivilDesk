import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Offline Service for local data caching and sync queue management
/// Phase 3 Optimization - Offline Support
/// 
/// Features:
/// - Local caching of employees and attendance data
/// - Sync queue for offline actions
/// - Auto-sync when connection restored
class OfflineService {
  static Database? _db;
  static final OfflineService _instance = OfflineService._internal();
  
  // Connectivity monitoring
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final _connectivityController = StreamController<bool>.broadcast();
  
  factory OfflineService() => _instance;
  OfflineService._internal();
  
  /// Stream of connectivity status (true = online, false = offline)
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Get database instance
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }
  
  /// Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'civildesk_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Employee cache table
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY,
        employee_id TEXT UNIQUE,
        first_name TEXT,
        last_name TEXT,
        email TEXT,
        phone_number TEXT,
        department TEXT,
        designation TEXT,
        is_active INTEGER,
        data TEXT,
        last_updated INTEGER
      )
    ''');
    
    // Attendance cache table
    await db.execute('''
      CREATE TABLE attendance_cache(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT,
        date TEXT,
        check_in_time TEXT,
        check_out_time TEXT,
        lunch_out_time TEXT,
        lunch_in_time TEXT,
        status TEXT,
        working_hours REAL,
        data TEXT,
        last_synced INTEGER
      )
    ''');
    
    // Sync queue for offline actions
    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        endpoint TEXT,
        method TEXT,
        data TEXT,
        created_at INTEGER,
        synced INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');
    
    // Dashboard stats cache
    await db.execute('''
      CREATE TABLE dashboard_cache(
        id INTEGER PRIMARY KEY,
        employee_id TEXT UNIQUE,
        data TEXT,
        last_updated INTEGER
      )
    ''');
    
    // Create indexes
    await db.execute('CREATE INDEX idx_employees_employee_id ON employees(employee_id)');
    await db.execute('CREATE INDEX idx_attendance_employee_date ON attendance_cache(employee_id, date)');
    await db.execute('CREATE INDEX idx_sync_queue_synced ON sync_queue(synced)');
  }
  
  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
  }
  
  /// Start monitoring connectivity
  void startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final isOnline = result != ConnectivityResult.none;
        _connectivityController.add(isOnline);
        
        if (isOnline) {
          // Auto-sync when connection restored
          syncPendingActions();
        }
      },
    );
  }
  
  /// Stop monitoring connectivity
  void stopConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
  }
  
  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  // ==================== Employee Cache ====================
  
  /// Cache employee data
  Future<void> cacheEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    await db.insert(
      'employees',
      {
        'id': employee['id'],
        'employee_id': employee['employeeId'],
        'first_name': employee['firstName'],
        'last_name': employee['lastName'],
        'email': employee['email'],
        'phone_number': employee['phoneNumber'],
        'department': employee['department'],
        'designation': employee['designation'],
        'is_active': employee['isActive'] == true ? 1 : 0,
        'data': jsonEncode(employee),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Cache multiple employees
  Future<void> cacheEmployees(List<Map<String, dynamic>> employees) async {
    final db = await database;
    final batch = db.batch();
    
    for (var employee in employees) {
      batch.insert(
        'employees',
        {
          'id': employee['id'],
          'employee_id': employee['employeeId'],
          'first_name': employee['firstName'],
          'last_name': employee['lastName'],
          'email': employee['email'],
          'phone_number': employee['phoneNumber'],
          'department': employee['department'],
          'designation': employee['designation'],
          'is_active': employee['isActive'] == true ? 1 : 0,
          'data': jsonEncode(employee),
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }
  
  /// Get cached employee by employee ID
  Future<Map<String, dynamic>?> getCachedEmployee(String employeeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
    );
    
    if (maps.isEmpty) return null;
    return jsonDecode(maps.first['data']);
  }
  
  /// Get all cached employees
  Future<List<Map<String, dynamic>>> getCachedEmployees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'first_name ASC',
    );
    
    return maps.map((m) => jsonDecode(m['data']) as Map<String, dynamic>).toList();
  }
  
  // ==================== Attendance Cache ====================
  
  /// Cache attendance record
  Future<void> cacheAttendance(Map<String, dynamic> attendance) async {
    final db = await database;
    await db.insert(
      'attendance_cache',
      {
        'employee_id': attendance['employeeId'],
        'date': attendance['date'],
        'check_in_time': attendance['checkInTime'],
        'check_out_time': attendance['checkOutTime'],
        'lunch_out_time': attendance['lunchOutTime'],
        'lunch_in_time': attendance['lunchInTime'],
        'status': attendance['status'],
        'working_hours': attendance['workingHours'],
        'data': jsonEncode(attendance),
        'last_synced': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Get cached attendance for a date range
  Future<List<Map<String, dynamic>>> getCachedAttendance(
    String employeeId,
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_cache',
      where: 'employee_id = ? AND date >= ? AND date <= ?',
      whereArgs: [employeeId, startDate, endDate],
      orderBy: 'date DESC',
    );
    
    return maps.map((m) => jsonDecode(m['data']) as Map<String, dynamic>).toList();
  }
  
  // ==================== Dashboard Cache ====================
  
  /// Cache dashboard stats
  Future<void> cacheDashboardStats(String employeeId, Map<String, dynamic> stats) async {
    final db = await database;
    await db.insert(
      'dashboard_cache',
      {
        'id': 1,
        'employee_id': employeeId,
        'data': jsonEncode(stats),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Get cached dashboard stats
  Future<Map<String, dynamic>?> getCachedDashboardStats(String employeeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dashboard_cache',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
    );
    
    if (maps.isEmpty) return null;
    
    // Check if cache is stale (older than 1 hour)
    final lastUpdated = maps.first['last_updated'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - lastUpdated;
    if (age > 3600000) return null; // 1 hour
    
    return jsonDecode(maps.first['data']);
  }
  
  // ==================== Sync Queue ====================
  
  /// Queue an action for sync when online
  Future<void> queueAction({
    required String action,
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'action': action,
      'endpoint': endpoint,
      'method': method,
      'data': jsonEncode(data),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
      'retry_count': 0,
    });
  }
  
  /// Get pending sync actions
  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'synced = ? AND retry_count < ?',
      whereArgs: [0, 3], // Max 3 retries
      orderBy: 'created_at ASC',
    );
  }
  
  /// Mark action as synced
  Future<void> markActionSynced(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Increment retry count for failed action
  Future<void> incrementRetryCount(int id, String error) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }
  
  /// Sync pending actions with server
  Future<void> syncPendingActions() async {
    if (!await isOnline()) return;
    
    final pendingActions = await getPendingSyncActions();
    if (pendingActions.isEmpty) return;
    
    // TODO: Implement actual sync logic with API service
    // This would call the appropriate API endpoints for each queued action
    for (var action in pendingActions) {
      try {
        // Placeholder for actual API call
        // await _apiService.syncAction(action);
        await markActionSynced(action['id'] as int);
      } catch (e) {
        await incrementRetryCount(action['id'] as int, e.toString());
      }
    }
  }
  
  /// Get sync queue status
  Future<Map<String, int>> getSyncQueueStatus() async {
    final db = await database;
    
    final pending = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM sync_queue WHERE synced = 0 AND retry_count < 3'
    )) ?? 0;
    
    final failed = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM sync_queue WHERE synced = 0 AND retry_count >= 3'
    )) ?? 0;
    
    final synced = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM sync_queue WHERE synced = 1'
    )) ?? 0;
    
    return {
      'pending': pending,
      'failed': failed,
      'synced': synced,
    };
  }
  
  // ==================== Cleanup ====================
  
  /// Clear all cached data
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('employees');
    await db.delete('attendance_cache');
    await db.delete('dashboard_cache');
  }
  
  /// Clear synced items from queue (keep for 7 days)
  Future<void> cleanupSyncQueue() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    
    await db.delete(
      'sync_queue',
      where: 'synced = 1 AND created_at < ?',
      whereArgs: [sevenDaysAgo],
    );
  }
  
  /// Close database connection
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    stopConnectivityMonitoring();
    await _connectivityController.close();
  }
}


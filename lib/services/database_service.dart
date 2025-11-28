import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/emotionlog.dart';
import '../models/chat_message.dart';
import '../models/check_in.dart';
import '../models/daily_recommendation.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emotions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Emotions table
    await db.execute('''
      CREATE TABLE emotions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emotion TEXT NOT NULL,
        intensity INTEGER NOT NULL,
        note TEXT NOT NULL,
        dateTime TEXT NOT NULL
      )
    ''');

    // Chat messages table
    await db.execute('''
    CREATE TABLE chat_messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message TEXT NOT NULL,
      isUser INTEGER NOT NULL,
      timestamp TEXT NOT NULL,
      emotionContext TEXT
    )
  ''');

    // Daily recommendations table
    await db.execute('''
    CREATE TABLE daily_recommendations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      category TEXT NOT NULL,
      imageUrl TEXT NOT NULL,
      date TEXT NOT NULL,
      completed INTEGER NOT NULL
    )
  ''');

    // Check-ins table
    await db.execute('''
    CREATE TABLE check_ins (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      emoji TEXT NOT NULL,
      diary TEXT,
      title TEXT,
      aiResponse TEXT NOT NULL,
      timestamp TEXT NOT NULL
    )
  ''');
  }

  // Insert emotion log
  Future<int> insertEmotion(EmotionLog log) async {
    final db = await database;
    return await db.insert('emotions', log.toMap());
  }

  // Get all emotions
  Future<List<EmotionLog>> getAllEmotions() async {
    final db = await database;
    final result = await db.query('emotions', orderBy: 'dateTime DESC');
    return result.map((map) => EmotionLog.fromMap(map)).toList();
  }

  // Get emotions for date range
  Future<List<EmotionLog>> getEmotionsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'emotions',
      where: 'dateTime BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'dateTime ASC',
    );
    return result.map((map) => EmotionLog.fromMap(map)).toList();
  }

  // Delete emotion
  Future<int> deleteEmotion(int id) async {
    final db = await database;
    return await db.delete('emotions', where: 'id = ?', whereArgs: [id]);
  }

  // Chat message operations
  Future<int> insertChatMessage(ChatMessage message) async {
    final db = await database;
    return await db.insert('chat_messages', message.toMap());
  }

  Future<List<ChatMessage>> getChatHistory({int limit = 50}) async {
    final db = await database;
    final result = await db.query(
      'chat_messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((map) => ChatMessage.fromMap(map)).toList();
  }

  // Recommendation operations
  Future<int> insertRecommendation(DailyRecommendation recommendation) async {
    final db = await database;
    // Ensure table exists before inserting
    await _ensureRecommendationsTableExists(db);
    return await db.insert('daily_recommendations', recommendation.toMap());
  }

  Future<DailyRecommendation?> getTodayRecommendation() async {
    final db = await database;
    // Ensure table exists before querying
    await _ensureRecommendationsTableExists(db);
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    final result = await db.query(
      'daily_recommendations',
      where: 'date LIKE ?',
      whereArgs: ['$todayStr%'],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DailyRecommendation.fromMap(result.first);
  }

  Future<int> markRecommendationCompleted(int id) async {
    final db = await database;
    // Ensure table exists before updating
    await _ensureRecommendationsTableExists(db);
    return await db.update(
      'daily_recommendations',
      {'completed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _ensureRecommendationsTableExists(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='daily_recommendations'",
    );
    if (tables.isEmpty) {
      await db.execute('''
      CREATE TABLE daily_recommendations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL
      )
    ''');
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // If upgrading from version 1 to 2, add missing tables
    if (oldVersion < 2) {
      // Check if check_ins table exists, if not create it
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='check_ins'",
      );
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE check_ins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            emoji TEXT NOT NULL,
            diary TEXT,
            aiResponse TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      }

      // Check if daily_recommendations table exists, if not create it
      final recTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='daily_recommendations'",
      );
      if (recTables.isEmpty) {
        await db.execute('''
          CREATE TABLE daily_recommendations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            imageUrl TEXT NOT NULL,
            date TEXT NOT NULL,
            completed INTEGER NOT NULL
          )
        ''');
      }

      // Check if chat_messages table exists, if not create it
      final chatTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='chat_messages'",
      );
      if (chatTables.isEmpty) {
        await db.execute('''
          CREATE TABLE chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            emotionContext TEXT
          )
        ''');
      }
    }

    if (oldVersion < 3) {
      // Check if check_ins table has the title column
      final checkInsColumns = await db.rawQuery("PRAGMA table_info(check_ins)");
      final hasTitleColumn = checkInsColumns.any(
        (column) => column['name'] == 'title',
      );

      if (!hasTitleColumn) {
        // Add title column to existing check_ins table
        await db.execute('ALTER TABLE check_ins ADD COLUMN title TEXT');
        debugPrint('Added title column to check_ins table');
      }

      // Also update the table creation for future use
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='check_ins'",
      );
      if (tables.isEmpty) {
        await db.execute('''
        CREATE TABLE check_ins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          emoji TEXT NOT NULL,
          diary TEXT,
          title TEXT,
          aiResponse TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
      }
    }
  }

  // Check-in operations
  Future<int> insertCheckIn(CheckIn checkIn) async {
    final db = await database;
    // Ensure table exists before inserting
    await _ensureCheckInsTableExists(db);
    return await db.insert('check_ins', checkIn.toMap());
  }

  // 在 _ensureCheckInsTableExists 方法中添加
  Future<void> _ensureCheckInsTableExists(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='check_ins'",
    );
    if (tables.isEmpty) {
      await db.execute('''
      CREATE TABLE check_ins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emoji TEXT NOT NULL,
        diary TEXT,
        title TEXT,
        aiResponse TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        emotion TEXT NOT NULL
      )
    ''');
    } else {
      // 检查并添加缺失的列
      final columns = await db.rawQuery("PRAGMA table_info(check_ins)");
      final hasTitleColumn = columns.any((column) => column['name'] == 'title');
      final hasEmotionColumn = columns.any(
        (column) => column['name'] == 'emotion',
      );

      if (!hasTitleColumn) {
        await db.execute('ALTER TABLE check_ins ADD COLUMN title TEXT');
      }
      if (!hasEmotionColumn) {
        await db.execute('ALTER TABLE check_ins ADD COLUMN emotion TEXT');
      }
    }
  }

  Future<List<CheckIn>> getRecentCheckIns({int days = 7}) async {
    final db = await database;
    // Ensure table exists before querying
    await _ensureCheckInsTableExists(db);
    final since = DateTime.now().subtract(Duration(days: days));

    final result = await db.query(
      'check_ins',
      where: 'timestamp > ?',
      whereArgs: [since.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => CheckIn.fromMap(map)).toList();
  }

  Future<List<CheckIn>> getAllCheckIns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_ins',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => CheckIn.fromMap(maps[i]));
  }

  Future<int> updateCheckIn(CheckIn checkIn) async {
    final db = await database;
    return await db.update(
      'check_ins',
      checkIn.toMap(),
      where: 'id = ?',
      whereArgs: [checkIn.id],
    );
  }

  // Close database
  Future close() async {
    final db = await database;
    db.close();
  }
}

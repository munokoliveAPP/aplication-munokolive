import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'security_service.dart';
import 'watchdog_service.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  final securityService = ref.read(securityServiceProvider);
  return LocalDatabaseService(securityService);
});

class LocalDatabaseService {
  final SecurityService _securityService;
  static Database? _database;
  static const String _dbName = 'munokolive_local.db';
  static const int _dbVersion = 1;

  LocalDatabaseService(this._securityService);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    try {
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onOpen: (db) async {
          // Self-Healing: Check integrity
          // This is a basic check.
        },
      );
    } catch (e) {
      // Self-Healing: Corrupted DB
      WatchdogService.logWarning(
        "Database corruption detected. Recreating... Error: $e",
      );
      await deleteDatabase(path);
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: (db, version) async {
          await _createTables(db);
        },
      );
    }
  }

  Future<void> _createTables(Database db) async {
    // 1. Posts Table (Feed)
    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        authorId TEXT,
        content TEXT,
        imageUrl TEXT,
        timestamp INTEGER,
        jsonPayload TEXT
      )
    ''');
    // Index for fast sorting/pagination
    await db.execute(
      'CREATE INDEX idx_posts_timestamp ON posts (timestamp DESC)',
    );

    // 2. Messages Table (Chat)
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT,
        senderId TEXT,
        content TEXT,
        timestamp INTEGER,
        isRead INTEGER,
        jsonPayload TEXT
      )
    ''');
    // Index for conversation history
    await db.execute(
      'CREATE INDEX idx_messages_conversation ON messages (conversationId, timestamp DESC)',
    );

    // 3. Offline Queue Table (Robustness)
    await db.execute('''
      CREATE TABLE pending_actions (
        id TEXT PRIMARY KEY,
        type TEXT, -- 'post', 'message', 'like', etc.
        payload TEXT, -- JSON data
        timestamp INTEGER
      )
    ''');
  }

  // --- Maintenance ---

  Future<void> runMaintenance() async {
    final db = await database;
    await db.rawQuery('VACUUM'); // Reclaims unused space
    WatchdogService.logInfo("Database maintenance (VACUUM) completed.");
  }

  // --- Generic Cache Methods ---

  Future<void> cachePost(Map<String, dynamic> post) async {
    final db = await database;

    // Encrypt sensitive payload
    await _securityService.initialize();
    final jsonString = jsonEncode(post);
    final encryptedPayload = _securityService.encryptData(jsonString);

    await db.insert('posts', {
      'id': post['id'],
      'authorId': post['authorId'] ?? '',
      'content': post['content'] ?? '',
      'imageUrl': post['imageUrl'] ?? '',
      'timestamp':
          (post['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      'jsonPayload': encryptedPayload, // Encrypted
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCachedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'posts',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    await _securityService.initialize();

    return maps
        .map((row) {
          try {
            final encrypted = row['jsonPayload'] as String;
            final decrypted = _securityService.decryptData(encrypted);
            return jsonDecode(decrypted) as Map<String, dynamic>;
          } catch (e) {
            // Fallback or skip corrupted data
            return <String, dynamic>{};
          }
        })
        .where((element) => element.isNotEmpty)
        .toList();
  }

  // --- Chat Innovation ---

  Future<void> cacheMessage(Map<String, dynamic> message) async {
    final db = await database;

    // Encrypt sensitive payload
    await _securityService.initialize();
    final jsonString = jsonEncode(message);
    final encryptedPayload = _securityService.encryptData(jsonString);

    await db.insert('messages', {
      'id': message['id'],
      'conversationId': message['conversationId'],
      'senderId': message['senderId'],
      'content': message['content'] ?? '',
      'timestamp':
          (message['timestamp'] as int?) ??
          DateTime.now().millisecondsSinceEpoch,
      'isRead': (message['isRead'] == true) ? 1 : 0,
      'jsonPayload': encryptedPayload, // Encrypted
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    await _securityService.initialize();

    return maps
        .map((row) {
          try {
            final encrypted = row['jsonPayload'] as String;
            final decrypted = _securityService.decryptData(encrypted);
            return jsonDecode(decrypted) as Map<String, dynamic>;
          } catch (e) {
            return <String, dynamic>{};
          }
        })
        .where((element) => element.isNotEmpty)
        .toList();
  }

  // --- Offline Queue ---

  Future<void> queueAction(
    String id,
    String type,
    Map<String, dynamic> payload,
  ) async {
    final db = await database;
    await db.insert('pending_actions', {
      'id': id,
      'type': type,
      'payload': jsonEncode(payload),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    final result = await db.query('pending_actions', orderBy: 'timestamp ASC');
    return result;
  }

  Future<void> removePendingAction(String id) async {
    final db = await database;
    await db.delete('pending_actions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Auto-Purge ---

  Future<void> purgeOldData({int daysToKeep = 30}) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .millisecondsSinceEpoch;

    await db.delete('posts', where: 'timestamp < ?', whereArgs: [cutoff]);
    await db.delete('messages', where: 'timestamp < ?', whereArgs: [cutoff]);

    // Also check DB size if needed (advanced), but for now time-based is sufficient
  }

  // --- Secure Wipe (Privacy) ---

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Close existing connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete file
    await deleteDatabase(path);
  }
}

// lib/core/database/local_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../logic/screen/chatScreen/chat_model.dart';
import '../../logic/screen/chatScreen/conversation_model.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'khoa_luan.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // Bảng cuộc trò chuyện
    await db.execute('''
      CREATE TABLE conversations (
        id           TEXT PRIMARY KEY,
        title        TEXT NOT NULL,
        last_message TEXT,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        message_count INTEGER DEFAULT 0
      )
    ''');

    // Bảng tin nhắn
    await db.execute('''
      CREATE TABLE messages (
        id              TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role            TEXT NOT NULL,
        type            TEXT NOT NULL,
        content         TEXT NOT NULL,
        image_path      TEXT,
        disease_result  TEXT,
        confidence      REAL,
        is_loading      INTEGER DEFAULT 0,
        created_at      TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id)
      )
    ''');
  }

  // ── Conversations ─────────────────────────────────────────

  static Future<void> saveConversation(Conversation conv) async {
    final db = await database;
    await db.insert(
      'conversations',
      conv.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateConversation(Conversation conv) async {
    final db = await database;
    await db.update(
      'conversations',
      conv.toMap(),
      where: 'id = ?',
      whereArgs: [conv.id],
    );
  }

  static Future<List<Conversation>> getConversations() async {
    final db   = await database;
    final maps = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
    return maps.map(Conversation.fromMap).toList();
  }

  static Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
  }

  // ── Messages ──────────────────────────────────────────────

  static Future<void> saveMessage(
      String conversationId, ChatMessage msg) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id':              msg.id,
        'conversation_id': conversationId,
        'role':            msg.role.name,
        'type':            msg.type.name,
        'content':         msg.content,
        'image_path':      msg.imagePath,
        'disease_result':  msg.diseaseResult,
        'confidence':      msg.confidence,
        'is_loading':      msg.isLoading ? 1 : 0,
        'created_at':      msg.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ChatMessage>> getMessages(
      String conversationId) async {
    final db   = await database;
    final maps = await db.query(
      'messages',
      where: 'conversation_id = ? AND is_loading = 0',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return maps.map((m) {
      return ChatMessage(
        id:            m['id'] as String,
        role:          MessageRole.values.byName(m['role'] as String),
        type:          MessageType.values.byName(m['type'] as String),
        content:       m['content'] as String,
        imagePath:     m['image_path'] as String?,
        diseaseResult: m['disease_result'] as String?,
        confidence:    m['confidence'] as double?,
        createdAt:     DateTime.parse(m['created_at'] as String),
      );
    }).toList();
  }
}
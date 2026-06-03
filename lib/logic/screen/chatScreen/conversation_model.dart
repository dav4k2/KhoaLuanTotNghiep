// lib/logic/screen/chatScreen/conversation_model.dart

class Conversation {
  final String id;
  final String title;          // Tên cuộc trò chuyện (lấy từ tin nhắn đầu tiên)
  final String? lastMessage;   // Tin nhắn cuối cùng để preview
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  Conversation({
    required this.id,
    required this.title,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  // Tạo conversation mới
  factory Conversation.create({required String firstMessage}) {
    final now = DateTime.now();
    return Conversation(
      id: now.millisecondsSinceEpoch.toString(),
      // Dùng 30 ký tự đầu của tin nhắn đầu tiên làm title
      title: firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage,
      createdAt: now,
      updatedAt: now,
    );
  }

  Conversation copyWith({
    String? lastMessage,
    DateTime? updatedAt,
    int? messageCount,
  }) {
    return Conversation(
      id: id,
      title: title,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'last_message': lastMessage,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'message_count': messageCount,
  };

  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
    id: map['id'].toString(),
    title: map['title'] as String,
    lastMessage: map['last_message'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    messageCount: map['message_count'] as int? ?? 0,
  );
}
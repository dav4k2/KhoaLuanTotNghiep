// lib/logic/chat/chat_model.dart

enum MessageRole { user, assistant }
enum MessageType { text, image }

class ChatMessage {
  final String id;
  final MessageRole role;
  final MessageType type;
  final String content;          // Text nội dung hoặc mô tả kết quả TFLite
  final String? imagePath;       // Đường dẫn ảnh nếu là tin nhắn ảnh
  final String? diseaseResult;   // Kết quả TFLite: "Potato Early Blight"
  final double? confidence;      // Độ chính xác: 0.94
  final DateTime createdAt;
  final bool isLoading;          // Đang chờ AI trả lời
  bool get isNetworkImage =>
      imagePath != null && imagePath!.startsWith('http');

  static int _idCounter = 0;

  static String _generateId() {
    _idCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    this.imagePath,
    this.diseaseResult,
    this.confidence,
    this.isLoading = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.userText(String content) => ChatMessage(
    id: _generateId(),
    role: MessageRole.user,
    type: MessageType.text,
    content: content,
  );

  factory ChatMessage.userImage({
    required String imagePath,
    required String diseaseResult,
    required double confidence,
  }) =>
      ChatMessage(
        id: _generateId(),
        role: MessageRole.user,
        type: MessageType.image,
        content: 'Ảnh chụp lá cây',
        imagePath: imagePath,
        diseaseResult: diseaseResult,
        confidence: confidence,
      );

  factory ChatMessage.assistantLoading() => ChatMessage(
    id: 'loading_${_generateId()}',
    role: MessageRole.assistant,
    type: MessageType.text,
    content: '',
    isLoading: true,
  );

  factory ChatMessage.assistantText(String content) => ChatMessage(
    id: _generateId(),
    role: MessageRole.assistant,
    type: MessageType.text,
    content: content,
  );

  ChatMessage copyWith({bool? isLoading, String? content}) => ChatMessage(
    id: id,
    role: role,
    type: type,
    content: content ?? this.content,
    imagePath: imagePath,
    diseaseResult: diseaseResult,
    confidence: confidence,
    isLoading: isLoading ?? this.isLoading,
    createdAt: createdAt,
  );
}
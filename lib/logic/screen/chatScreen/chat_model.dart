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

  // Tạo tin nhắn của user (text)
  factory ChatMessage.userText(String content) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    role: MessageRole.user,
    type: MessageType.text,
    content: content,
  );

  // Tạo tin nhắn của user (ảnh + kết quả TFLite)
  factory ChatMessage.userImage({
    required String imagePath,
    required String diseaseResult,
    required double confidence,
  }) =>
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.user,
        type: MessageType.image,
        content: 'Ảnh chụp lá cây',
        imagePath: imagePath,
        diseaseResult: diseaseResult,
        confidence: confidence,
      );

  // Tạo tin nhắn loading của AI
  factory ChatMessage.assistantLoading() => ChatMessage(
    id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
    role: MessageRole.assistant,
    type: MessageType.text,
    content: '',
    isLoading: true,
  );

  // Tạo tin nhắn của AI
  factory ChatMessage.assistantText(String content) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
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
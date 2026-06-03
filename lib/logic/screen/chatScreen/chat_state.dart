// lib/logic/screen/chatScreen/chat_state.dart

import 'chat_model.dart';
import 'conversation_model.dart';

enum ChatStatus { idle, loading, error }

class ChatState {
  final List<ChatMessage> messages;
  final ChatStatus status;
  final String? errorMessage;
  final bool isAnalyzingImage;
  final Conversation? currentConversation; // ← THÊM

  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.idle,
    this.errorMessage,
    this.isAnalyzingImage = false,
    this.currentConversation,               // ← THÊM
  });

  bool get isLoading  => status == ChatStatus.loading;
  bool get hasMessages => messages.isNotEmpty;

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    String? errorMessage,
    bool? isAnalyzingImage,
    Conversation? currentConversation,
  }) {
    return ChatState(
      messages:            messages ?? this.messages,
      status:              status ?? this.status,
      errorMessage:        errorMessage,
      isAnalyzingImage:    isAnalyzingImage ?? this.isAnalyzingImage,
      currentConversation: currentConversation ?? this.currentConversation,
    );
  }
}
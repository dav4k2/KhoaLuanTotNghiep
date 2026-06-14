// lib/logic/screen/chatScreen/chat_notifier.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/service/image_upload_service.dart';
import 'chat_model.dart';
import 'chat_state.dart';
import 'conversation_model.dart';
import 'gemini_service.dart';
import 'plant_disease_classifier.dart';

// ── Trigger refresh TaskBar ───────────────────────────────────
class _RefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state++;
}

final conversationRefreshProvider =
NotifierProvider<_RefreshNotifier, int>(_RefreshNotifier.new);

// ── Chat Notifier ─────────────────────────────────────────────

class ChatNotifier extends Notifier<ChatState> {
  final _gemini = GeminiService();

  @override
  ChatState build() {
    plantClassifier.loadModel();
    return const ChatState();
  }

  void _refreshConversations() {
    ref.read(conversationRefreshProvider.notifier).increment();
  }

  void startNewConversation() => state = const ChatState();

  Future<void> loadConversation(String conversationId) async {
    try {
      final messages = await LocalDatabase.getMessages(conversationId);
      final convs    = await LocalDatabase.getConversations();
      final conv     = convs.firstWhere((c) => c.id == conversationId);
      state = state.copyWith(
        messages:            messages,
        currentConversation: conv,
        status:              ChatStatus.idle,
      );
    } catch (_) {
      state = state.copyWith(status: ChatStatus.idle);
    }
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    final conv       = state.currentConversation ??
        Conversation.create(firstMessage: text.trim());
    final userMsg    = ChatMessage.userText(text.trim());
    final loadingMsg = ChatMessage.assistantLoading();

    state = state.copyWith(
      messages:            [...state.messages, userMsg, loadingMsg],
      currentConversation: conv,
      status:              ChatStatus.loading,
    );

    await LocalDatabase.saveConversation(conv);
    await LocalDatabase.saveMessage(conv.id, userMsg);
    _refreshConversations();

    try {
      final reply  = await _gemini.sendMessage(_buildGeminiHistory());
      final botMsg = ChatMessage.assistantText(reply);

      final updatedMessages = [
        ...state.messages.where((m) => !m.isLoading),
        botMsg,
      ];
      final updatedConv = conv.copyWith(
        lastMessage:  reply.length > 50
            ? '${reply.substring(0, 50)}...'
            : reply,
        updatedAt:    DateTime.now(),
        messageCount: updatedMessages.length,
      );

      state = state.copyWith(
        messages:            updatedMessages,
        currentConversation: updatedConv,
        status:              ChatStatus.idle,
      );

      await LocalDatabase.saveMessage(conv.id, botMsg);
      await LocalDatabase.updateConversation(updatedConv);
      _refreshConversations();

      _syncToBackend(updatedConv, updatedMessages);
    } catch (_) {
      final errorMsg = ChatMessage.assistantText(
          '❌ Không thể kết nối AI. Vui lòng kiểm tra mạng và thử lại.');
      final updatedMessages = [
        ...state.messages.where((m) => !m.isLoading),
        errorMsg,
      ];
      state = state.copyWith(messages: updatedMessages, status: ChatStatus.idle);
      await LocalDatabase.saveMessage(conv.id, errorMsg);
    }
  }

  // ── Phân tích ảnh ─────────────────────────────────────────

  Future<void> analyzeImage(String imagePath) async {
    state = state.copyWith(isAnalyzingImage: true);

    final conv = state.currentConversation ??
        Conversation.create(firstMessage: 'Chẩn đoán bệnh cây qua ảnh');

    final imageMsg = ChatMessage.userImage(
      imagePath:     imagePath,
      diseaseResult: 'Đang phân tích...',
      confidence:    0,
    );

    state = state.copyWith(
      messages:            [...state.messages, imageMsg],
      currentConversation: conv,
      isAnalyzingImage:    true,
    );

    await LocalDatabase.saveConversation(conv);
    _refreshConversations();

    // Upload ảnh lên backend (Cloudinary) song song với việc phân tích
    final uploadFuture = ImageUploadService.uploadChatImage(imagePath);

    final hasInternet = await _checkInternet();

    if (hasInternet) {
      await _analyzeWithGeminiVision(imagePath, uploadFuture, conv, imageMsg);
    } else {
      await _analyzeWithTFLite(imagePath, uploadFuture, conv, imageMsg);
    }
  }

  Future<void> _analyzeWithGeminiVision(
      String imagePath,
      Future<String?> uploadFuture,
      Conversation conv,
      ChatMessage imageMsg,
      ) async {
    final loadingMsg = ChatMessage.assistantLoading();
    state = state.copyWith(
      messages: [...state.messages, loadingMsg],
      status:   ChatStatus.loading,
    );

    try {
      final reply = await _gemini.analyzeImageWithAI(imagePath);

      final uploadedUrl = await uploadFuture;
      final storedImagePath = uploadedUrl ?? imagePath;

      final updatedImageMsg = ChatMessage.userImage(
        imagePath:     storedImagePath,
        diseaseResult: '🤖 Phân tích bởi Gemini AI',
        confidence:    1.0,
      );

      final botMsg = ChatMessage.assistantText(reply);
      final updatedMessages = [
        ...state.messages.where((m) => !m.isLoading && m.id != imageMsg.id),
        updatedImageMsg,
        botMsg,
      ];

      final updatedConv = conv.copyWith(
        lastMessage:  '📸 Gemini AI đã phân tích ảnh',
        updatedAt:    DateTime.now(),
        messageCount: updatedMessages.length,
      );

      state = state.copyWith(
        messages:            updatedMessages,
        currentConversation: updatedConv,
        status:              ChatStatus.idle,
        isAnalyzingImage:    false,
      );

      await LocalDatabase.saveMessage(conv.id, updatedImageMsg);
      await LocalDatabase.saveMessage(conv.id, botMsg);
      await LocalDatabase.updateConversation(updatedConv);
      _refreshConversations();

      _syncToBackend(updatedConv, updatedMessages);
    } catch (e) {
      await _analyzeWithTFLite(imagePath, uploadFuture, conv, imageMsg);
    }
  }

  Future<void> _analyzeWithTFLite(
      String imagePath,
      Future<String?> uploadFuture,
      Conversation conv,
      ChatMessage imageMsg,
      ) async {
    try {
      final result = await plantClassifier.classify(imagePath);

      final uploadedUrl = await uploadFuture;
      final storedImagePath = uploadedUrl ?? imagePath;

      final updatedImageMsg = ChatMessage.userImage(
        imagePath:     storedImagePath,
        diseaseResult: result.displayName,
        confidence:    result.confidence,
      );

      final botMsg = ChatMessage.assistantText(
        _buildOfflineDiagnosisResponse(result),
      );

      final updatedMessages = [
        ...state.messages.where((m) => !m.isLoading && m.id != imageMsg.id),
        updatedImageMsg,
        botMsg,
      ];

      final updatedConv = conv.copyWith(
        lastMessage:  '📸 [Offline] ${result.displayName}',
        updatedAt:    DateTime.now(),
        messageCount: updatedMessages.length,
      );

      state = state.copyWith(
        messages:            updatedMessages,
        currentConversation: updatedConv,
        status:              ChatStatus.idle,
        isAnalyzingImage:    false,
      );

      await LocalDatabase.saveMessage(conv.id, updatedImageMsg);
      await LocalDatabase.saveMessage(conv.id, botMsg);
      await LocalDatabase.updateConversation(updatedConv);
      _refreshConversations();
    } catch (e) {
      state = state.copyWith(
        isAnalyzingImage: false,
        messages: [
          ...state.messages.where((m) => !m.isLoading),
          ChatMessage.assistantText(
              '❌ Không thể phân tích ảnh. Vui lòng chụp lại ảnh rõ hơn.'),
        ],
        status: ChatStatus.idle,
      );
    }
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _buildOfflineDiagnosisResponse(DiseaseResult result) {
    final percent = (result.confidence * 100).toStringAsFixed(1);

    if (result.label.toLowerCase().contains('healthy')) {
      return '✅ **[Chế độ offline] Kết quả: ${result.displayName}**\n\n'
          'Độ chính xác: $percent%\n\n'
          'Lá cây trông khỏe mạnh! 🌿\n\n'
          '_Kết nối mạng để được tư vấn chi tiết hơn từ AI._';
    }

    return '🔍 **[Chế độ offline] Kết quả: ${result.displayName}**\n\n'
        'Độ chính xác: $percent%\n\n'
        '⚠️ Đây là kết quả từ AI ngoại tuyến (TFLite).\n\n'
        '_Kết nối mạng để được Gemini AI phân tích chi tiết hơn về '
        'nguyên nhân, cách điều trị và phòng ngừa._';
  }

  Future<void> clearChat() async {
    if (state.currentConversation != null) {
      await LocalDatabase.deleteConversation(state.currentConversation!.id);
      _deleteFromBackend(state.currentConversation!.id);
    }
    state = const ChatState();
    _refreshConversations();
  }

  // ── Sync lên PostgreSQL (có debug log) ───────────────────

  Future<void> _syncToBackend(
      Conversation conv, List<ChatMessage> messages) async {
    try {
      final token = await TokenStorage.getToken();

      print('>>> [SYNC] token = $token');

      if (token == null) {
        print('>>> [SYNC] Bỏ qua: token null — chưa đăng nhập');
        return;
      }

      final body = {
        'id':            conv.id,
        'title':         conv.title,
        'last_message':  conv.lastMessage,
        'message_count': conv.messageCount,
        'created_at':    conv.createdAt.toIso8601String(),
        'updated_at':    conv.updatedAt.toIso8601String(),
        'messages': messages
            .where((m) => !m.isLoading)
            .map((m) => {
          'id':             m.id,
          'role':           m.role.name,
          'type':           m.type.name,
          'content':        m.content,
          'image_path':     m.imagePath,
          'disease_result': m.diseaseResult,
          'confidence':     m.confidence,
          'created_at':     m.createdAt.toIso8601String(),
        })
            .toList(),
      };

      print('>>> [SYNC] Đang gửi lên: ${ApiEndpoints.baseUrl}${ApiEndpoints.syncConversation}');
      print('>>> [SYNC] conversation_id = ${conv.id}');
      print('>>> [SYNC] số messages = ${body['messages'].toString().length}');

      final result = await ApiClient().post(
        endpoint: ApiEndpoints.syncConversation,
        token: token,
        body: body,
      );

      print('>>> [SYNC] ✅ Thành công: $result');

    } catch (e, stack) {
      // In ra lỗi chi tiết thay vì nuốt thầm lặng
      print('>>> [SYNC] ❌ LỖI: $e');
      print('>>> [SYNC] Stack: $stack');
    }
  }

  Future<void> _deleteFromBackend(String id) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) return;

      print('>>> [DELETE] Đang xoá conversation: $id');

      await ApiClient().delete(
        endpoint: ApiEndpoints.deleteConversation(id),
        token: token,
      );

      print('>>> [DELETE] ✅ Thành công');
    } catch (e) {
      print('>>> [DELETE] ❌ LỖI: $e');
    }
  }

  List<Map<String, dynamic>> _buildGeminiHistory() {
    final history = <Map<String, dynamic>>[];
    for (final msg in state.messages.where((m) => !m.isLoading)) {
      final role = msg.role == MessageRole.user ? 'user' : 'model';
      String text;
      if (msg.type == MessageType.image && msg.diseaseResult != null) {
        final percent = ((msg.confidence ?? 0) * 100).toStringAsFixed(1);
        text = '[Người dùng gửi ảnh lá cây. '
            'Kết quả phân tích: ${msg.diseaseResult} '
            '(độ chính xác $percent%)]';
      } else {
        text = msg.content;
      }
      if (text.trim().isEmpty) continue;
      history.add({'role': role, 'parts': [{'text': text}]});
    }
    return history;
  }
}

// ── Providers ─────────────────────────────────────────────────

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  ref.watch(conversationRefreshProvider);
  return LocalDatabase.getConversations();
});
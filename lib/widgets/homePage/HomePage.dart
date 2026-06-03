// lib/widgets/homePage/HomePage.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../logic/screen/chatScreen/chat_model.dart';    // ← THÊM
import '../../logic/screen/chatScreen/chat_notifier.dart';
import '../../logic/screen/chatScreen/chat_state.dart';
import '../chatScreen/ChatScreen.dart';
import '../taskBar/TaskBar.dart';

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  final Color primaryGreen = const Color(0xFF1E6E38);
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(chatProvider.notifier).sendTextMessage(text);
    _scrollToBottom();
  }

  void _openImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chụp ảnh lá cây để chẩn đoán bệnh',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryGreen),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryGreen.withOpacity(0.1),
                child: Icon(Icons.camera_alt, color: primaryGreen),
              ),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryGreen.withOpacity(0.1),
                child: Icon(Icons.photo_library, color: primaryGreen),
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      ref.read(chatProvider.notifier).analyzeImage(picked.path);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatProvider, (_, __) => _scrollToBottom());

    final chatState = ref.watch(chatProvider);
    final messages  = chatState.messages;                    // List<ChatMessage>
    final isLoading = chatState.isLoading || chatState.isAnalyzingImage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: messages.isEmpty ? 0 : 1,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          messages.isEmpty ? '' : 'Trợ lý Nông nghiệp',
          style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black54),
              onPressed: () => _confirmClearChat(),
            ),
        ],
      ),
      drawer: const Taskbar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? _buildWelcomeScreen()
                  : _buildChatList(messages, isLoading),
            ),
            _buildInputBar(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Center(
              child: Image.asset(
                'assets/Icon_preview_rev_1.png',
                width: screenWidth * 0.50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.eco, size: 120, color: primaryGreen),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Xin chào! Tôi có thể giúp gì cho cây trồng của bạn hôm nay?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _QuickSuggest(
                  text: '🥔 Bệnh khoai tây',
                  color: primaryGreen,
                  onTap: () => ref
                      .read(chatProvider.notifier)
                      .sendTextMessage(
                      'Các bệnh thường gặp trên cây khoai tây là gì?'),
                ),
                _QuickSuggest(
                  text: '📸 Chẩn đoán qua ảnh',
                  color: primaryGreen,
                  onTap: _openImagePicker,
                ),
                _QuickSuggest(
                  text: '🌿 Cách phòng bệnh',
                  color: primaryGreen,
                  onTap: () => ref
                      .read(chatProvider.notifier)
                      .sendTextMessage(
                      'Làm thế nào để phòng ngừa bệnh cây trồng hiệu quả?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ← ĐỔI: List<ChatMessage> thay vì List (có type rõ ràng)
  Widget _buildChatList(List<ChatMessage> messages, bool isLoading) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(
          message: messages[index],
          primaryColor: primaryGreen,
        );
      },
    );
  }

  Widget _buildInputBar(bool isLoading) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                spreadRadius: 2,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: isLoading ? null : _openImagePicker,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey.shade300 : primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading && ref.watch(chatProvider).isAnalyzingImage
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.camera_alt,
                      color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _textController,
                  enabled: !isLoading,
                  onFieldSubmitted: isLoading ? null : _handleSubmitted,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: isLoading
                        ? 'Đang xử lý...'
                        : 'Gửi ảnh lá bệnh hoặc đặt câu hỏi...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () => _handleSubmitted(_textController.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey.shade300 : primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá cuộc trò chuyện'),
        content: const Text('Bạn có chắc muốn xoá toàn bộ lịch sử chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatProvider.notifier).clearChat();
            },
            child: Text('Xoá',
                style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _QuickSuggest extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _QuickSuggest({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
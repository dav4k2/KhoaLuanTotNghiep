// lib/widgets/chatScreen/ChatScreen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';   // ← THÊM

import '../../logic/screen/chatScreen/chat_model.dart';

// ── Widget hiển thị từng bong bóng tin nhắn ───────────────────

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color primaryColor;

  const MessageBubble({
    super.key,
    required this.message,
    required this.primaryColor,
  });

  bool get _isBot => message.role == MessageRole.assistant;

  @override
  Widget build(BuildContext context) {
    // Tin nhắn ảnh của user
    if (message.type == MessageType.image &&
        message.role == MessageRole.user) {
      return _buildImageBubble();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
        _isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          // Avatar Bot
          if (_isBot) ...[
            ClipOval(
              child: Image.asset(
                'assets/Icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CircleAvatar(
                  radius: 16,
                  backgroundColor: primaryColor.withOpacity(0.15),
                  child: Icon(Icons.eco, color: primaryColor, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Nội dung tin nhắn
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isBot ? Colors.white : primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isBot ? 0 : 16),
                  bottomRight: Radius.circular(_isBot ? 16 : 0),
                ),
                boxShadow: [
                  if (_isBot)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: message.isLoading
                  ? _TypingIndicator(color: primaryColor)
                  : _isBot
                  ? _buildBotContent()    // ← Bot: dùng Markdown
                  : _buildUserContent(),  // ← User: dùng Text thường
            ),
          ),
        ],
      ),
    );
  }

  // ── Bot: render Markdown đẹp ──────────────────────────────

  Widget _buildBotContent() {
    return MarkdownBody(
      data: message.content,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        // Văn bản thường
        p: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          height: 1.6,
        ),
        // **In đậm** → màu xanh nổi bật
        strong: const TextStyle(
          color: Color(0xFF1E6E38),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        // *In nghiêng*
        em: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        // Bullet list
        listBullet: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
        ),
        // Khoảng cách
        blockSpacing: 6,
        listIndent: 16,
        // Số thứ tự (1. 2. 3.)
        orderedListAlign: WrapAlignment.start,
      ),
    );
  }

  // ── User: text trắng trên nền xanh ───────────────────────

  Widget _buildUserContent() {
    return Text(
      message.content,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  // ── Bubble ảnh ────────────────────────────────────────────

  Widget _buildImageBubble() {
    final percent = ((message.confidence ?? 0) * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Ảnh
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: message.isNetworkImage
                        ? Image.network(
                      message.imagePath!,
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : SizedBox(
                        width: 180,
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorBuilder: (context, error, stack) =>
                          Container(
                            width: 180,
                            height: 180,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image,
                                size: 40, color: Colors.grey),
                          ),
                    )
                        : Image.file(
                      File(message.imagePath!),
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Kết quả TFLite
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔍 Kết quả chẩn đoán (Offline)',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.diseaseResult ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Độ chính xác: $percent%',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator (3 chấm nhảy) ───────────────────────────

class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(
        reverse: true,
        period: Duration(milliseconds: 500 + i * 150),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
          child: FadeTransition(
            opacity: _controllers[i],
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
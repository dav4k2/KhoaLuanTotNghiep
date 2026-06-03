// lib/widgets/taskBar/TaskBar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/screen/chatScreen/chat_notifier.dart';
import '../../logic/screen/chatScreen/conversation_model.dart';
import '../../core/database/local_database.dart';
import '../community/Community.dart';
import '../setting/Setting.dart';
import 'AccountBottomSheet.dart';

class Taskbar extends ConsumerWidget {
  const Taskbar({super.key});

  static const Color primaryGreen = Color(0xFF1E6E38);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nút cuộc trò chuyện mới
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(chatProvider.notifier).startNewConversation();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Cuộc trò chuyện mới',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            // Danh sách lịch sử
            Expanded(
              child: conversationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                ),
                error: (_, __) => const Center(
                  child: Text('Không thể tải lịch sử',
                      style: TextStyle(color: Colors.grey)),
                ),
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Chưa có cuộc trò chuyện nào.\nBắt đầu hỏi tôi ngay!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    );
                  }
                  return _ConversationList(
                    conversations: conversations,
                    ref: ref,
                    onTap: (conv) {
                      ref.read(chatProvider.notifier).loadConversation(conv.id);
                      Navigator.pop(context);
                    },
                    onDelete: (conv) async {
                      await LocalDatabase.deleteConversation(conv.id);
                      ref.invalidate(conversationsProvider);
                    },
                  );
                },
              ),
            ),

            // Menu dưới cùng
            const Divider(height: 1, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  // Thêm nút Cộng đồng vào đây
                  ListTile(
                    leading: const Icon(Icons.people_outline, color: Colors.black87),
                    title: const Text('Cộng đồng',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context); // Đóng Taskbar
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CommunityScreen()));
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.settings_outlined,
                        color: Colors.black87),
                    title: const Text('Cài đặt',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const Setting()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined,
                        color: Colors.black87),
                    title: const Text('Tài khoản',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const AccountBottomSheet(),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Danh sách nhóm theo ngày ──────────────────────────────────

class _ConversationList extends StatelessWidget {
  final List<Conversation> conversations;
  final WidgetRef ref;
  final void Function(Conversation) onTap;
  final void Function(Conversation) onDelete;

  const _ConversationList({
    required this.conversations,
    required this.ref,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Conversation>>{};
    final now    = DateTime.now();

    for (final conv in conversations) {
      final diff = now.difference(conv.updatedAt).inDays;
      String label;
      if (diff == 0)       label = 'Hôm nay';
      else if (diff == 1)  label = 'Hôm qua';
      else if (diff <= 7)  label = '7 ngày qua';
      else if (diff <= 30) label = '30 ngày qua';
      else                 label = 'Cũ hơn';
      groups.putIfAbsent(label, () => []).add(conv);
    }

    final currentConvId = ref.watch(chatProvider).currentConversation?.id;

    return ListView(
      padding: EdgeInsets.zero,
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            ...entry.value.map((conv) {
              final isActive = conv.id == currentConvId;
              return _ConversationItem(
                conv:     conv,
                isActive: isActive,
                onTap:    () => onTap(conv),
                onDelete: () => onDelete(conv),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}

// ── Item conversation ─────────────────────────────────────────

class _ConversationItem extends StatelessWidget {
  final Conversation conv;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationItem({
    required this.conv,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  static const Color primaryGreen = Color(0xFF1E6E38);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? const Color(0xFFE6F4EA) : Colors.transparent,
        leading: Icon(Icons.chat_bubble_outline,
            color: isActive ? primaryGreen : Colors.black54, size: 20),
        title: Text(
          conv.title,
          style: TextStyle(
            color: isActive ? primaryGreen : Colors.black87,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: conv.lastMessage != null
            ? Text(conv.lastMessage!,
            style: const TextStyle(color: Colors.black38, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis)
            : null,
        onTap: onTap,
        onLongPress: () => _confirmDelete(context),
        trailing: isActive
            ? IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.black38, size: 18),
          onPressed: () => _confirmDelete(context),
        )
            : null,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá cuộc trò chuyện'),
        content: Text('Xoá "${conv.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ',
                style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
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
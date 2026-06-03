// lib/widgets/community/Community.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/token_storage.dart';
import '../../logic/screen/community/community_notifier.dart';
import '../../logic/screen/community/community_post.dart';

const _kGreen      = Color(0xFF1E6E38);
const _kGreenLight = Color(0xFFE6F4EA);

// ══════════════════════════════════════════════════
//  Provider: lấy userId hiện tại để kiểm tra quyền xoá
// ══════════════════════════════════════════════════

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  return TokenStorage.getUserId();
});

// ══════════════════════════════════════════════════
//  COMMUNITY SCREEN
// ══════════════════════════════════════════════════

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(communityProvider.notifier).loadMore();
    }
  }

  // ✅ Lấy tên user thật trước khi mở bottom sheet
  void _openCreatePost() async {
    final fullName = await TokenStorage.getFullName() ?? '';
    final email    = await TokenStorage.getEmail()    ?? '';
    final displayName = fullName.isNotEmpty
        ? fullName
        : email.split('@').first;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(
        currentUserName: displayName,
        onSubmit: (content, files) {
          ref.read(communityProvider.notifier)
              .createPost(content: content, imageFiles: files);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: const Text('CỘNG ĐỒNG',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        backgroundColor: _kGreen,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Đăng bài',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody(CommunityState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }
    if (state.error != null && state.posts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.black38),
          const SizedBox(height: 12),
          Text(state.error!, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.read(communityProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
            child: const Text('Thử lại',
                style: TextStyle(color: Colors.white)),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      color: _kGreen,
      onRefresh: () => ref.read(communityProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.only(top: 12, bottom: 110),
        itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == state.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: _kGreen)),
            );
          }
          return _PostCard(post: state.posts[i]);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  POST CARD
// ══════════════════════════════════════════════════

class _PostCard extends ConsumerStatefulWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  bool   _showComments    = false;
  String _currentUserName = '';

  final _commentCtrl  = TextEditingController();
  final _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // ✅ Lấy tên user thật để hiển thị trong comment box
  Future<void> _loadCurrentUser() async {
    final fullName = await TokenStorage.getFullName() ?? '';
    final email    = await TokenStorage.getEmail()    ?? '';
    final name     = fullName.isNotEmpty
        ? fullName
        : email.split('@').first;
    if (mounted) setState(() => _currentUserName = name);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _commentCtrl.text.trim();
    if (t.isEmpty) return;
    ref.read(communityProvider.notifier)
        .addComment(postId: widget.post.id, content: t);
    _commentCtrl.clear();
    _commentFocus.unfocus();
  }

  // ✅ Dialog xác nhận trước khi xoá
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá bài viết'),
        content: const Text('Bạn có chắc muốn xoá bài viết này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ',
                style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(communityProvider.notifier)
                  .deletePost(widget.post.id);
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

  @override
  Widget build(BuildContext context) {
    final p = widget.post;

    // ✅ Kiểm tra quyền xoá — chỉ chủ bài mới thấy nút xoá
    final currentUserId = ref.watch(currentUserIdProvider).asData?.value;
    final isOwner = currentUserId != null && currentUserId == p.authorId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
          child: Row(children: [
            _Avatar(name: p.authorName, imageUrl: p.authorAvatar),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.authorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
                Text(p.timeAgo,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45)),
              ],
            )),

            // ✅ Menu "..." — xoá CHỈ hiện với chủ bài
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz,
                  color: Colors.black38, size: 20),
              onSelected: (v) {
                if (v == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => [
                // Báo cáo — ai cũng thấy
                const PopupMenuItem(
                  value: 'report',
                  child: Row(children: [
                    Icon(Icons.flag_outlined,
                        size: 18, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Báo cáo bài viết'),
                  ]),
                ),
                // Xoá — CHỈ chủ bài mới thấy ✅
                if (isOwner)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text('Xoá bài viết',
                          style: TextStyle(color: Colors.red.shade600)),
                    ]),
                  ),
              ],
            ),
          ]),
        ),

        // ── Nội dung ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(p.content,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.5)),
        ),

        // ── Ảnh ─────────────────────────────────────
        if (p.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ImageGrid(imageUrls: p.imageUrls),
        ],

        const SizedBox(height: 10),

        // ── Like / Bình luận ────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            _ActionBtn(
              icon:  p.isLikedByMe ? Icons.favorite : Icons.favorite_border,
              color: p.isLikedByMe ? Colors.red : Colors.black54,
              label: '${p.likeCount}',
              onTap: () =>
                  ref.read(communityProvider.notifier).toggleLike(p.id),
            ),
            const SizedBox(width: 20),
            _ActionBtn(
              icon:  Icons.chat_bubble_outline,
              color: Colors.black54,
              label: '${p.comments.length}',
              onTap: () => setState(() => _showComments = !_showComments),
            ),
          ]),
        ),

        // ── Bình luận (hiện khi nhấn) ────────────────
        if (_showComments) ...[
          const Divider(height: 20, indent: 14, endIndent: 14),
          ...p.comments.map((c) => _CommentTile(comment: c)),

          // ✅ Ô nhập bình luận với tên + avatar thật
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(name: _currentUserName, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    focusNode:  _commentFocus,
                    decoration: InputDecoration(
                      hintText:  'Bình luận của $_currentUserName...',
                      hintStyle: const TextStyle(
                          color: Colors.black38, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      filled:    true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:   BorderSide.none),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: _kGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.send,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 4),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
//  COMMENT TILE
// ══════════════════════════════════════════════════

class _CommentTile extends StatelessWidget {
  final PostComment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(name: comment.authorName, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:        const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.authorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(comment.content,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(comment.timeAgo,
            style: const TextStyle(fontSize: 11, color: Colors.black38)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
//  CREATE POST BOTTOM SHEET
// ══════════════════════════════════════════════════

class _CreatePostSheet extends StatefulWidget {
  final String currentUserName;
  final void Function(String content, List<File> files) onSubmit;
  const _CreatePostSheet({
    required this.currentUserName,
    required this.onSubmit,
  });

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _ctrl   = TextEditingController();
  final _picker = ImagePicker();
  List<File> _picked = [];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImages() async {
    final xs = await _picker.pickMultiImage(imageQuality: 85);
    if (xs.isEmpty) return;
    setState(() {
      _picked =
          [..._picked, ...xs.map((x) => File(x.path))].take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin:  const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Đăng bài mới',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 16, color: Colors.black87)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ]),
          const Divider(),
          const SizedBox(height: 8),

          // ✅ Hiển thị avatar + tên thật khi đăng bài
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Avatar(name: widget.currentUserName),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.currentUserName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
                const SizedBox(height: 6),
                TextField(
                  controller: _ctrl,
                  autofocus:  true,
                  maxLines:   5,
                  minLines:   3,
                  decoration: const InputDecoration(
                    hintText:  'Chia sẻ câu hỏi, kinh nghiệm canh tác...',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                    border:    InputBorder.none,
                  ),
                ),
              ],
            )),
          ]),

          // Preview ảnh đã chọn
          if (_picked.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _picked.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_picked[i],
                        width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(top: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _picked.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _pickImages,
            icon:  const Icon(Icons.image_outlined, color: _kGreen),
            label: Text(
              _picked.isEmpty
                  ? 'Thêm hình ảnh'
                  : 'Thêm thêm (${_picked.length}/5)',
              style: const TextStyle(color: _kGreen),
            ),
            style: OutlinedButton.styleFrom(
              side:  const BorderSide(color: _kGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final t = _ctrl.text.trim();
                if (t.isEmpty) return;
                widget.onSubmit(t, _picked);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Đăng',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  final String  name;
  final String? imageUrl;
  final double  size;
  const _Avatar({required this.name, this.imageUrl, this.size = 40});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius:          size / 2,
    backgroundColor: _kGreenLight,
    backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
    child: imageUrl == null
        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
            color:      _kGreen,
            fontWeight: FontWeight.bold,
            fontSize:   size * 0.4))
        : null,
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       label;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 13)),
    ]),
  );
}

class _ImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  const _ImageGrid({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final show  = imageUrls.take(3).toList();
    final extra = imageUrls.length - show.length;
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: show.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final isLast = i == show.length - 1 && extra > 0;
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              Image.network(show[i],
                  width: 140, height: 160, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 140, height: 160,
                      color: const Color(0xFFE0E0E0),
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.black38))),
              if (isLast)
                Positioned.fill(child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Center(child: Text('+$extra',
                      style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize:   22))),
                )),
            ]),
          );
        },
      ),
    );
  }
}
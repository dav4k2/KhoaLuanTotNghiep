// lib/logic/screen/community/community_notifier.dart
// Riverpod 3.x  —  Notifier + NotifierProvider

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import 'community_post.dart';
import 'community_repository.dart';

// ══════════════════════════════════════════════════
//  STATE
// ══════════════════════════════════════════════════

class CommunityState {
  final List<CommunityPost> posts;
  final bool    isLoading;
  final bool    isLoadingMore;
  final bool    isSubmitting;
  final String? error;
  final int     currentPage;
  final int     totalPosts;

  const CommunityState({
    this.posts         = const [],
    this.isLoading     = false,
    this.isLoadingMore = false,
    this.isSubmitting  = false,
    this.error,
    this.currentPage   = 1,
    this.totalPosts    = 0,
  });

  bool get hasMore => posts.length < totalPosts;

  CommunityState copyWith({
    List<CommunityPost>? posts,
    bool?    isLoading,
    bool?    isLoadingMore,
    bool?    isSubmitting,
    String?  error,
    int?     currentPage,
    int?     totalPosts,
    bool     clearError = false,
  }) =>
      CommunityState(
        posts:         posts         ?? this.posts,
        isLoading:     isLoading     ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isSubmitting:  isSubmitting  ?? this.isSubmitting,
        error:         clearError ? null : (error ?? this.error),
        currentPage:   currentPage   ?? this.currentPage,
        totalPosts:    totalPosts    ?? this.totalPosts,
      );
}

// ══════════════════════════════════════════════════
//  NOTIFIER
// ══════════════════════════════════════════════════

class CommunityNotifier extends Notifier<CommunityState> {
  final _repo = const CommunityRepository();

  @override
  CommunityState build() {
    Future.microtask(loadPosts);
    return const CommunityState();
  }

  // ── Helper: lấy tên hiển thị từ TokenStorage ────────────
  // Ưu tiên fullName, fallback về phần trước @ của email
  Future<String> _getDisplayName() async {
    final fullName = await TokenStorage.getFullName() ?? '';
    if (fullName.isNotEmpty) return fullName;
    final email = await TokenStorage.getEmail() ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Người dùng';
  }

  // ── Tải trang đầu / refresh ─────────────────────
  Future<void> loadPosts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final r = await _repo.fetchPosts(page: 1);
      state = state.copyWith(
        posts:       r.posts,
        totalPosts:  r.total,
        currentPage: 1,
        isLoading:   false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadPosts();

  // ── Tải thêm trang (infinite scroll) ────────────
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final r = await _repo.fetchPosts(page: state.currentPage + 1);
      state = state.copyWith(
        posts:         [...state.posts, ...r.posts],
        totalPosts:    r.total,
        currentPage:   state.currentPage + 1,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // ── Đăng bài mới ────────────────────────────────
  Future<void> createPost({
    required String    content,
    List<File> imageFiles = const [],
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final urls = imageFiles.isNotEmpty
          ? await _repo.uploadImages(imageFiles)
          : <String>[];
      final post = await _repo.createPost(
          content: content, imageUrls: urls);

      // ✅ Cập nhật authorName từ TokenStorage sau khi tạo post thành công
      // Backend đã lưu full_name, nhưng response có thể trả về authorName đúng rồi
      // Nếu backend trả về email thay vì tên → ghi đè bằng tên từ local storage
      final displayName = await _getDisplayName();
      final userId      = await TokenStorage.getUserId() ?? '';

      final fixedPost = post.authorName.contains('@')
          ? post.copyWith(authorName: displayName)   // ← fix nếu backend trả email
          : post;                                     // ← giữ nguyên nếu đã đúng

      state = state.copyWith(
        posts:        [fixedPost, ...state.posts],
        totalPosts:   state.totalPosts + 1,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  // ── Toggle like (optimistic update + rollback) ──
  Future<void> toggleLike(String postId) async {
    final idx = state.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final old     = state.posts[idx];
    final updated = [...state.posts];

    // Cập nhật UI ngay (optimistic)
    updated[idx] = old.copyWith(
      isLikedByMe: !old.isLikedByMe,
      likeCount:   old.isLikedByMe
          ? old.likeCount - 1
          : old.likeCount + 1,
    );
    state = state.copyWith(posts: updated);

    try {
      final r = await _repo.toggleLike(postId);
      updated[idx] = old.copyWith(
        isLikedByMe: r.isLiked,
        likeCount:   r.likeCount,
      );
      state = state.copyWith(posts: [...updated]);
    } catch (_) {
      // Rollback nếu API lỗi
      updated[idx] = old;
      state = state.copyWith(posts: [...updated]);
    }
  }

  // ── Thêm bình luận ──────────────────────────────
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final comment = await _repo.addComment(
          postId: postId, content: content);

      // ✅ Fix tên bình luận nếu backend trả về email
      final displayName  = await _getDisplayName();
      final fixedComment = comment.authorName.contains('@')
          ? PostComment(
        id:           comment.id,
        authorId:     comment.authorId,
        authorName:   displayName,  // ← dùng tên thật
        authorAvatar: comment.authorAvatar,
        content:      comment.content,
        createdAt:    comment.createdAt,
      )
          : comment;

      final updated = state.posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(
          comments:     [...p.comments, fixedComment],
          commentCount: p.commentCount + 1,
        );
      }).toList();
      state = state.copyWith(posts: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Xoá bài viết ────────────────────────────────
  Future<void> deletePost(String postId) async {
    try {
      await _repo.deletePost(postId);
      state = state.copyWith(
        posts:      state.posts.where((p) => p.id != postId).toList(),
        totalPosts: state.totalPosts - 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ══════════════════════════════════════════════════
//  PROVIDER
// ══════════════════════════════════════════════════

final communityProvider =
NotifierProvider<CommunityNotifier, CommunityState>(
  CommunityNotifier.new,
);
// lib/logic/screen/community/community_notifier.dart
// Riverpod 3.x  —  Notifier + NotifierProvider

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  /// true khi đang hiển thị dữ liệu từ cache (offline)
  final bool    isOffline;

  const CommunityState({
    this.posts         = const [],
    this.isLoading     = false,
    this.isLoadingMore = false,
    this.isSubmitting  = false,
    this.error,
    this.currentPage   = 1,
    this.totalPosts    = 0,
    this.isOffline     = false,
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
    bool?    isOffline,
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
        isOffline:     isOffline     ?? this.isOffline,
      );
}

// ══════════════════════════════════════════════════
//  CACHE HELPER
// ══════════════════════════════════════════════════

class _PostsCache {
  static const String _keyPosts      = 'community_cached_posts';
  static const String _keyTotal      = 'community_cached_total';

  /// Lưu trang 1 vào cache (chỉ lưu trang đầu để tránh dữ liệu stale)
  static Future<void> save(List<CommunityPost> posts, int total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = posts.map((p) => p.toJson()).toList();
      await prefs.setString(_keyPosts, jsonEncode(json));
      await prefs.setInt(_keyTotal, total);
    } catch (_) {
      // Cache lỗi không critical — bỏ qua
    }
  }

  /// Đọc cache, trả về null nếu không có
  static Future<({List<CommunityPost> posts, int total})?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_keyPosts);
      final total = prefs.getInt(_keyTotal) ?? 0;
      if (raw == null) return null;
      final list  = (jsonDecode(raw) as List)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
      return (posts: list, total: total);
    } catch (_) {
      return null;
    }
  }
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
  Future<String> _getDisplayName() async {
    final fullName = await TokenStorage.getFullName() ?? '';
    if (fullName.isNotEmpty) return fullName;
    final email = await TokenStorage.getEmail() ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Người dùng';
  }

  // ── Tải trang đầu / refresh ─────────────────────────────
  Future<void> loadPosts() async {
    // Hiển thị loading nhưng GIỮ posts cũ để UI không bị trắng
    state = state.copyWith(isLoading: true, clearError: true, isOffline: false);

    // Load cache trước để hiển thị ngay nếu có
    if (state.posts.isEmpty) {
      final cached = await _PostsCache.load();
      if (cached != null && cached.posts.isNotEmpty) {
        state = state.copyWith(
          posts:      cached.posts,
          totalPosts: cached.total,
          isOffline:  true, // đánh dấu đang dùng cache
        );
      }
    }

    try {
      final r = await _repo.fetchPosts(page: 1);
      // Lưu cache khi fetch thành công
      await _PostsCache.save(r.posts, r.total);
      state = state.copyWith(
        posts:       r.posts,
        totalPosts:  r.total,
        currentPage: 1,
        isLoading:   false,
        isOffline:   false,
      );
    } on Exception catch (e) {
      final errMsg = e.toString();
      final isNetworkError = errMsg.contains('kết nối') ||
          errMsg.contains('SocketException') ||
          errMsg.contains('statusCode: 0');

      if (isNetworkError && state.posts.isNotEmpty) {
        // Mất mạng nhưng có cache → giữ cache, không hiện lỗi đỏ
        state = state.copyWith(
          isLoading: false,
          isOffline: true,
          // Không set error để UI không hiển thị màn hình lỗi
        );
      } else if (_isAuthError(errMsg)) {
        // Token thực sự hết hạn → thông báo nhưng VẪN giữ cache
        state = state.copyWith(
          isLoading: false,
          isOffline: state.posts.isNotEmpty,
          error:     'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        );
      } else {
        // Lỗi khác → hiện lỗi nhưng vẫn giữ posts cũ
        state = state.copyWith(
          isLoading: false,
          error:     errMsg,
        );
      }
    }
  }

  Future<void> refresh() => loadPosts();

  // ── Tải thêm trang (infinite scroll) ────────────────────
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isOffline) return;
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

  // ── Đăng bài mới ────────────────────────────────────────
  Future<void> createPost({
    required String    content,
    List<File> imageFiles = const [],
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final urls = imageFiles.isNotEmpty
          ? await _repo.uploadImages(imageFiles)
          : <String>[];
      final post = await _repo.createPost(content: content, imageUrls: urls);

      final displayName = await _getDisplayName();
      final fixedPost   = post.authorName.contains('@')
          ? post.copyWith(authorName: displayName)
          : post;

      final newPosts = [fixedPost, ...state.posts];
      final newTotal = state.totalPosts + 1;

      state = state.copyWith(
        posts:        newPosts,
        totalPosts:   newTotal,
        isSubmitting: false,
        isOffline:    false,
      );
      // Cập nhật cache
      await _PostsCache.save(newPosts, newTotal);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  // ── Toggle like (optimistic update + rollback) ──────────
  Future<void> toggleLike(String postId) async {
    final idx = state.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final old     = state.posts[idx];
    final updated = [...state.posts];

    updated[idx] = old.copyWith(
      isLikedByMe: !old.isLikedByMe,
      likeCount:   old.isLikedByMe ? old.likeCount - 1 : old.likeCount + 1,
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
      updated[idx] = old;
      state = state.copyWith(posts: [...updated]);
    }
  }

  // ── Thêm bình luận ──────────────────────────────────────
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final comment = await _repo.addComment(postId: postId, content: content);

      final displayName  = await _getDisplayName();
      final fixedComment = comment.authorName.contains('@')
          ? PostComment(
        id:           comment.id,
        authorId:     comment.authorId,
        authorName:   displayName,
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

  // ── Xoá bài viết ────────────────────────────────────────
  Future<void> deletePost(String postId) async {
    try {
      await _repo.deletePost(postId);
      final newPosts = state.posts.where((p) => p.id != postId).toList();
      final newTotal = state.totalPosts - 1;
      state = state.copyWith(posts: newPosts, totalPosts: newTotal);
      await _PostsCache.save(newPosts, newTotal);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Private helpers ──────────────────────────────────────

  bool _isAuthError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('401') ||
        lower.contains('hết hạn') ||
        lower.contains('expired') ||
        lower.contains('unauthorized');
  }
}

// ══════════════════════════════════════════════════
//  PROVIDER
// ══════════════════════════════════════════════════

final communityProvider =
NotifierProvider<CommunityNotifier, CommunityState>(
  CommunityNotifier.new,
);
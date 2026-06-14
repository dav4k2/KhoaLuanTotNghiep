// lib/core/network/api_endpoints.dart

class ApiEndpoints {
  ApiEndpoints._();

  // ── Base URL ──────────────────────────────────────────────────
  static const String baseUrl = 'https://yang-nonrustic-forth.ngrok-free.dev';

  // ── Timeout ───────────────────────────────────────────────────
  static const Duration timeout = Duration(seconds: 15);

  // ── Auth ──────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login    = '/auth/login';
  static const String me       = '/auth/me';

  // ── Community — khớp đúng với backend: /community/...
  static const String _base = '/community';

  static const String posts                     = '$_base/posts';
  static String postDetail(String id)           => '$_base/posts/$id';
  static String likePost(String id)             => '$_base/posts/$id/like';
  static String comments(String postId)         => '$_base/posts/$postId/comments';
  static String deleteComment(String commentId) => '$_base/comments/$commentId';
  static const String uploadImages              = '$_base/upload-images';

  // ── Conversations ─────────────────────────────────────────────
  static const String _convBase = '/conversations';

  static const String uploadChatImage = '/conversations/upload-image';

  /// POST /conversations/sync — upsert conversation + messages
  static const String syncConversation = '$_convBase/sync';

  /// GET /conversations/ — lấy danh sách conversations của user
  static const String getConversations = '$_convBase/';

  /// GET /conversations/{id}/messages — lấy messages của 1 conversation
  static String getMessages(String id) => '$_convBase/$id/messages';

  /// DELETE /conversations/{id} — xoá conversation
  static String deleteConversation(String id) => '$_convBase/$id';
}
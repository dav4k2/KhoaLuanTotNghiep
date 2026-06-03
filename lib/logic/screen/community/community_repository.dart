// lib/data/community/community_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'community_post.dart';

class CommunityRepository {
  const CommunityRepository();

  Future<Map<String, String>> get _headers async {
    final token = await TokenStorage.getToken() ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    if (query == null) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<({List<CommunityPost> posts, int total})> fetchPosts({
    int page = 1,
    int size = 10,
  }) async {
    final res = await http
        .get(
      _uri(ApiEndpoints.posts, {'page': page, 'size': size}),
      headers: await _headers,
    )
        .timeout(ApiEndpoints.timeout);
    _check(res);
    print('📦 fetchPosts body: ${res.body}'); // ← log tạm để debug
    final decoded = jsonDecode(res.body);

    // Shape A: {"items": [...], "total": N}
    if (decoded is Map<String, dynamic>) {
      final items = (decoded['items'] ?? decoded['data'] ?? decoded['posts'] ?? []) as List;
      final total = decoded['total'] ?? decoded['count'] ?? items.length;
      return (
      posts: items.map((e) => _postFromJson(e as Map<String, dynamic>)).toList(),
      total: total as int,
      );
    }

    // Shape B: [...] danh sách thẳng
    if (decoded is List) {
      final posts = decoded.map((e) => _postFromJson(e as Map<String, dynamic>)).toList();
      return (posts: posts, total: posts.length);
    }

    return (posts: <CommunityPost>[], total: 0);
  }

  Future<CommunityPost> createPost({
    required String       content,
    List<String> imageUrls = const [],
  }) async {
    final res = await http
        .post(
      _uri(ApiEndpoints.posts),
      headers: await _headers,
      body: jsonEncode({'content': content, 'image_urls': imageUrls}),
    )
        .timeout(ApiEndpoints.timeout);
    _check(res);
    return _postFromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    final res = await http
        .delete(
      _uri(ApiEndpoints.postDetail(postId)),
      headers: await _headers,
    )
        .timeout(ApiEndpoints.timeout);
    _check(res);
  }

  Future<({bool isLiked, int likeCount})> toggleLike(String postId) async {
    final res = await http
        .post(
      _uri(ApiEndpoints.likePost(postId)),
      headers: await _headers,
    )
        .timeout(ApiEndpoints.timeout);
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (
    isLiked:   body['action'] == 'liked',
    likeCount: body['like_count'] as int,
    );
  }

  Future<PostComment> addComment({
    required String postId,
    required String content,
  }) async {
    final res = await http
        .post(
      _uri(ApiEndpoints.comments(postId)),
      headers: await _headers,
      body: jsonEncode({'content': content}),
    )
        .timeout(ApiEndpoints.timeout);
    _check(res);
    return _commentFromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<String>> uploadImages(List<File> files) async {
    final token = await TokenStorage.getToken() ?? '';
    final req =
    http.MultipartRequest('POST', _uri(ApiEndpoints.uploadImages))
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['ngrok-skip-browser-warning'] = 'true';

    for (final f in files) {
      final ext = f.path.split('.').last.toLowerCase();
      req.files.add(await http.MultipartFile.fromPath(
        'files', f.path,
        contentType: MediaType('image', ext),
      ));
    }

    final streamed = await req.send();
    final res      = await http.Response.fromStream(streamed);
    _check(res);

    final decoded = jsonDecode(res.body);

    // Shape A: ["https://url1", "https://url2"]  ← danh sách string thẳng
    if (decoded is List) {
      if (decoded.isEmpty) return [];
      if (decoded.first is String) {
        return decoded.cast<String>();
      }
      // Shape B: [{"url": "https://url1"}, ...]  ← danh sách object
      return decoded
          .map((e) => (e as Map<String, dynamic>)['url'] as String)
          .toList();
    }

    // Shape C: {"urls": [...]} hoặc {"data": [...]}
    if (decoded is Map) {
      final list = (decoded['urls'] ?? decoded['data'] ?? []) as List;
      return list.map((e) {
        return e is String ? e : (e as Map<String, dynamic>)['url'] as String;
      }).toList();
    }

    return [];
  }

  void _check(http.Response res) {
    if (res.statusCode == 401) {
      // Token hết hạn → xoá token → app sẽ redirect về login
      TokenStorage.clearAll();
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }
    if (res.statusCode >= 400) {
      String? msg;
      try {
        msg = (jsonDecode(res.body) as Map)['detail']?.toString();
      } catch (_) {}
      throw Exception(msg ?? 'Lỗi ${res.statusCode}');
    }
  }

  // ✅ Ưu tiên author_name (full_name từ backend), fallback email
  CommunityPost _postFromJson(Map<String, dynamic> j) {
    final rawName = j['author_name'] as String? ?? '';

    // Nếu backend trả về email → dùng phần trước @
    final displayName = rawName.contains('@')
        ? rawName.split('@').first
        : rawName.isNotEmpty
        ? rawName
        : 'Người dùng';

    return CommunityPost(
      id:           j['id'].toString(),
      authorId:     j['author_id'].toString(),
      authorName:   displayName,   // ← họ tên hoặc username sạch
      authorAvatar: j['author_avatar'] as String?,
      content:      j['content']   as String,
      imageUrls:    List<String>.from(j['image_urls'] ?? []),
      likeCount:    j['like_count']    as int?  ?? 0,
      isLikedByMe:  j['is_liked_by_me'] as bool? ?? false,
      commentCount: j['comment_count'] as int?  ?? 0,
      createdAt:    DateTime.parse(j['created_at'] as String),
      comments:     (j['comments'] as List? ?? [])
          .map((c) => _commentFromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  // ✅ Ưu tiên author_name, fallback email
  PostComment _commentFromJson(Map<String, dynamic> j) {
    final rawName = j['author_name'] as String? ?? '';
    final displayName = rawName.contains('@')
        ? rawName.split('@').first
        : rawName.isNotEmpty
        ? rawName
        : 'Người dùng';

    return PostComment(
      id:           j['id'].toString(),
      authorId:     j['author_id'].toString(),
      authorName:   displayName,   // ← họ tên sạch
      authorAvatar: j['author_avatar'] as String?,
      content:      j['content']   as String,
      createdAt:    DateTime.parse(j['created_at'] as String),
    );
  }
}
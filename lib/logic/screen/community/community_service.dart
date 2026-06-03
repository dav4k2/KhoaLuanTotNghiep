// lib/services/community_service.dart

import 'package:khoa_luan_tot_nghiep/logic/screen/community/post_model.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';


class CommunityService {
  final ApiClient _apiClient;

  CommunityService(this._apiClient);

  // Lấy danh sách bài viết
  Future<List<Post>> getPosts() async {
    final response = await _apiClient.get(endpoint: ApiEndpoints.posts);

    // Giả sử API trả về json có dạng: {"data": [ ... ]}
    final List data = response['data'] ?? [];
    return data.map((json) => Post.fromJson(json)).toList();
  }

  // Gửi bình luận
  Future<Comment> createComment(String postId, String content) async {
    final response = await _apiClient.post(
      endpoint: ApiEndpoints.comments(postId),
      body: {'content': content},
      // Thêm token nếu endpoint này yêu cầu xác thực
      // token: currentToken,
    );

    return Comment.fromJson(response['data']);
  }

  // Thích bài viết
  Future<void> toggleLike(String postId) async {
    await _apiClient.post(
      endpoint: ApiEndpoints.likePost(postId),
      body: {}, // Body có thể rỗng tùy vào thiết kế backend của bạn
    );
  }
}
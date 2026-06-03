// lib/models/post_model.dart
class Post {
  final String id;
  final String userName;
  final String userAvatar;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;

  Post({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id']?.toString() ?? '',
      userName: json['user_name'] ?? 'Ẩn danh',
      userAvatar: json['user_avatar'] ?? '',
      content: json['content'] ?? '',
      // Xử lý mảng hình ảnh an toàn
      imageUrls: json['image_urls'] != null ? List<String>.from(json['image_urls']) : [],
      // Chuyển đổi chuỗi thành DateTime
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByMe: json['is_liked_by_me'] ?? false,
    );
  }

  Post copyWith({int? likesCount, bool? isLikedByMe, int? commentsCount}) {
    return Post(
      id: id,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      imageUrls: imageUrls,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

// lib/models/comment_model.dart
class Comment {
  final String id;
  final String postId;
  final String userName;
  final String userAvatar;
  final String content;

  Comment({
    required this.id,
    required this.postId,
    required this.userName,
    required this.userAvatar,
    required this.content,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      userName: json['user_name'] ?? 'Ẩn danh',
      userAvatar: json['user_avatar'] ?? '',
      content: json['content'] ?? '',
    );
  }
}
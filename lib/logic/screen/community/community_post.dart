// lib/logic/screen/community/community_post.dart

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final List<String> imageUrls;
  final int likeCount;
  final bool isLikedByMe;
  final int commentCount;
  final DateTime createdAt;
  final List<PostComment> comments;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.imageUrls    = const [],
    this.likeCount    = 0,
    this.isLikedByMe  = false,
    this.commentCount = 0,
    required this.createdAt,
    this.comments = const [],
  });

  // ← Thêm authorName vào copyWith để có thể ghi đè tên
  CommunityPost copyWith({
    String?            authorName,
    int?               likeCount,
    bool?              isLikedByMe,
    int?               commentCount,
    List<PostComment>? comments,
  }) =>
      CommunityPost(
        id:           id,
        authorId:     authorId,
        authorName:   authorName   ?? this.authorName,  // ← THÊM
        authorAvatar: authorAvatar,
        content:      content,
        imageUrls:    imageUrls,
        likeCount:    likeCount    ?? this.likeCount,
        isLikedByMe:  isLikedByMe  ?? this.isLikedByMe,
        commentCount: commentCount ?? this.commentCount,
        createdAt:    createdAt,
        comments:     comments     ?? this.comments,
      );

  String get timeAgo {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 1)  return 'Vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
    if (d.inHours   < 24) return '${d.inHours} giờ trước';
    if (d.inDays    < 7)  return '${d.inDays} ngày trước';
    return '${(d.inDays / 7).floor()} tuần trước';
  }
}

class PostComment {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  String get timeAgo {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 1)  return 'Vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
    if (d.inHours   < 24) return '${d.inHours} giờ trước';
    return '${d.inDays} ngày trước';
  }
}
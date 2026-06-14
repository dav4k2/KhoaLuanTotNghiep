// lib/logic/screen/community/community_post.dart

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
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
    this.authorRole = "user",
    required this.content,
    this.imageUrls    = const [],
    this.likeCount    = 0,
    this.isLikedByMe  = false,
    this.commentCount = 0,
    required this.createdAt,
    this.comments = const [],
  });

  bool get isExpert => authorRole == "expert";

  // ── fromJson (parse từ API và từ cache) ─────────────────────
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id:           json['id']?.toString()         ?? '',
      authorId:     json['authorId']?.toString()   ?? json['author_id']?.toString() ?? '',
      authorName:   json['authorName']?.toString() ?? json['author_name']?.toString() ?? '',
      authorAvatar: json['authorAvatar']?.toString() ?? json['author_avatar']?.toString(),
      authorRole:   json['authorRole']?.toString() ?? json['author_role']?.toString() ?? 'user',
      content:      json['content']?.toString()    ?? '',
      imageUrls:    (json['imageUrls'] ?? json['image_urls'] ?? const [])
          .cast<String>(),
      likeCount:    (json['likeCount'] ?? json['like_count'] ?? 0) as int,
      isLikedByMe:  (json['isLikedByMe'] ?? json['is_liked_by_me'] ?? false) as bool,
      commentCount: (json['commentCount'] ?? json['comment_count'] ?? 0) as int,
      createdAt:    DateTime.parse(
        json['createdAt']?.toString() ?? json['created_at']?.toString()
            ?? DateTime.now().toIso8601String(),
      ),
      comments:     ((json['comments'] ?? const []) as List)
          .map((c) => PostComment.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── toJson (dùng cho cache SharedPreferences) ───────────────
  Map<String, dynamic> toJson() => {
    'id':           id,
    'authorId':     authorId,
    'authorName':   authorName,
    'authorAvatar': authorAvatar,
    'authorRole':   authorRole,
    'content':      content,
    'imageUrls':    imageUrls,
    'likeCount':    likeCount,
    'isLikedByMe':  isLikedByMe,
    'commentCount': commentCount,
    'createdAt':    createdAt.toIso8601String(),
    'comments':     comments.map((c) => c.toJson()).toList(),
  };

  CommunityPost copyWith({
    String?            authorName,
    String?            authorRole,
    int?               likeCount,
    bool?              isLikedByMe,
    int?               commentCount,
    List<PostComment>? comments,
  }) =>
      CommunityPost(
        id:           id,
        authorId:     authorId,
        authorName:   authorName   ?? this.authorName,
        authorAvatar: authorAvatar,
        authorRole:   authorRole   ?? this.authorRole,
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

// ════════════════════════════════════════════════════

class PostComment {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole = 'user',
    required this.content,
    required this.createdAt,
  });

  // ── fromJson ────────────────────────────────────────────────
  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id:           json['id']?.toString()           ?? '',
      authorId:     json['authorId']?.toString()     ?? json['author_id']?.toString() ?? '',
      authorName:   json['authorName']?.toString()   ?? json['author_name']?.toString() ?? '',
      authorAvatar: json['authorAvatar']?.toString() ?? json['author_avatar']?.toString(),
      authorRole:   json['authorRole']?.toString()   ?? json['author_role']?.toString() ?? 'user',
      content:      json['content']?.toString()      ?? '',
      createdAt:    DateTime.parse(
        json['createdAt']?.toString() ?? json['created_at']?.toString()
            ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // ── toJson ──────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':           id,
    'authorId':     authorId,
    'authorName':   authorName,
    'authorAvatar': authorAvatar,
    'authorRole':   authorRole,
    'content':      content,
    'createdAt':    createdAt.toIso8601String(),
  };

  String get timeAgo {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 1)  return 'Vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
    if (d.inHours   < 24) return '${d.inHours} giờ trước';
    return '${d.inDays} ngày trước';
  }
}
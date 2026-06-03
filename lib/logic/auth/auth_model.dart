// lib/models/auth/auth_model.dart
// Thêm expiresIn vào AuthResponse để lưu đúng thời hạn token

class SignUpRequest {
  final String email;
  final String password;
  final String fullName;

  SignUpRequest({
    required this.email,
    required this.password,
    required this.fullName,
  });

  Map<String, dynamic> toJson() => {
    'email':     email,
    'password':  password,
    'full_name': fullName,
  };
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email':    email,
    'password': password,
  };
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final int?   expiresIn;   // ← THÊM: seconds, VD: 3600 hoặc 604800 (7 ngày)
  final UserInfo user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType:   json['token_type']   as String? ?? 'bearer',
      expiresIn:   json['expires_in']   as int?,    // ← THÊM
      user:        UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserInfo {
  final String  id;
  final String  email;
  final String? fullName;
  final bool    isActive;
  final bool    isVerified;
  final DateTime createdAt;

  UserInfo({
    required this.id,
    required this.email,
    this.fullName,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id:         json['id'].toString(),
      email:      json['email']       as String,
      fullName:   json['full_name']   as String?,
      isActive:   json['is_active']   as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt:  DateTime.parse(json['created_at'] as String),
    );
  }
}
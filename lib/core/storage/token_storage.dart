// lib/core/storage/token_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();

  static const String _keyToken     = 'access_token';
  static const String _keyEmail     = 'user_email';
  static const String _keyUserId    = 'user_id';
  static const String _keyFullName  = 'user_full_name';
  static const String _keyExpiresAt = 'token_expires_at';

  // ── Lưu ──────────────────────────────────────────────────

  /// [expiresInSeconds] nên truyền đúng giá trị từ backend (vd: 86400 = 1 ngày).
  /// Mặc định 7 ngày để tránh logout sớm khi backend không trả expires_in.
  static Future<void> saveToken(String token, {int expiresInSeconds = 604800}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresInSeconds))
        .millisecondsSinceEpoch;
    await prefs.setInt(_keyExpiresAt, expiresAt);
  }

  static Future<void> saveUserInfo({
    required String userId,
    required String email,
    String? fullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyEmail, email);
    if (fullName != null && fullName.isNotEmpty) {
      await prefs.setString(_keyFullName, fullName);
    }
  }

  // ── Đọc ──────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFullName);
  }

  // ── Kiểm tra token còn hạn không ─────────────────────────
  // Chỉ coi là hết hạn khi LOCAL expiry đã qua — KHÔNG gọi API ở đây.
  // Việc verify thật sự (gọi /auth/me) do ApiClient xử lý khi gặp 401/403.
  static Future<bool> isTokenValid() async {
    final prefs     = await SharedPreferences.getInstance();
    final token     = prefs.getString(_keyToken);
    final expiresAt = prefs.getInt(_keyExpiresAt);

    if (token == null || token.isEmpty) return false;

    // Nếu chưa có expires (token cũ được lưu trước khi có field này) → coi là hợp lệ
    if (expiresAt == null) return true;

    final expireTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
    // Buffer 5 phút thay vì 60 giây — tránh false-positive logout
    return DateTime.now().isBefore(expireTime.subtract(const Duration(minutes: 5)));
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Xoá ──────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyExpiresAt);
  }
}
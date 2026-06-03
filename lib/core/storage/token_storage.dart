// lib/core/storage/token_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();

  static const String _keyToken     = 'access_token';
  static const String _keyEmail     = 'user_email';
  static const String _keyUserId    = 'user_id';
  static const String _keyFullName  = 'user_full_name';
  static const String _keyExpiresAt = 'token_expires_at'; // ← THÊM

  // ── Lưu ──────────────────────────────────────────────────

  static Future<void> saveToken(String token, {int expiresInSeconds = 3600}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    // Lưu thời điểm hết hạn (milliseconds since epoch)
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
  // buffer: coi như hết hạn sớm 60 giây để tránh race condition
  static Future<bool> isTokenValid({int bufferSeconds = 60}) async {
    final prefs     = await SharedPreferences.getInstance();
    final token     = prefs.getString(_keyToken);
    final expiresAt = prefs.getInt(_keyExpiresAt);

    if (token == null || token.isEmpty) return false;
    if (expiresAt == null) return true; // token cũ chưa có expires → coi là hợp lệ

    final expireTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
    return DateTime.now().isBefore(
      expireTime.subtract(Duration(seconds: bufferSeconds)),
    );
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
// lib/logic/startup/app_startup_notifier.dart
//
// Chạy khi app khởi động — kiểm tra token còn hợp lệ không.
// Dùng ở màn hình splash / router để quyết định vào Home hay Login.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum StartupStatus { checking, authenticated, unauthenticated }

class AppStartupNotifier extends AsyncNotifier<StartupStatus> {
  @override
  Future<StartupStatus> build() async {
    return _checkSession();
  }

  Future<StartupStatus> _checkSession() async {
    // 1. Không có token → chưa đăng nhập
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return StartupStatus.unauthenticated;
    }

    // 2. Token còn hạn (theo local) → dùng luôn
    final isValid = await TokenStorage.isTokenValid();
    if (isValid) {
      return StartupStatus.authenticated;
    }

    // 3. Token local đã hết hạn → verify với server
    // Nếu server vẫn chấp nhận (vd: server chưa expire) → authenticated
    // Nếu 401 → xoá token, về login
    try {
      final res = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.me}'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        // Server vẫn ok → cập nhật lại expiry local thêm 1 giờ
        await TokenStorage.saveToken(token, expiresInSeconds: 3600);

        // Cập nhật lại user info từ response
        try {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          await TokenStorage.saveUserInfo(
            userId:   json['id']?.toString() ?? '',
            email:    json['email'] as String? ?? '',
            fullName: json['full_name'] as String?,
          );
        } catch (_) {}

        return StartupStatus.authenticated;
      } else {
        // 401 hoặc lỗi khác → xoá token
        await TokenStorage.clearAll();
        return StartupStatus.unauthenticated;
      }
    } catch (_) {
      // Không có mạng → vẫn cho vào app nhưng community sẽ lỗi khi dùng
      // Không xoá token để khi có mạng lại vẫn dùng được
      return StartupStatus.authenticated;
    }
  }

  /// Gọi lại khi cần re-check (vd: sau khi đăng nhập/đăng xuất)
  Future<void> recheck() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_checkSession);
  }
}

final appStartupProvider =
AsyncNotifierProvider<AppStartupNotifier, StartupStatus>(
  AppStartupNotifier.new,
);
// lib/core/services/image_upload_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../network/api_endpoints.dart';
import '../storage/token_storage.dart';

class ImageUploadService {
  /// Upload ảnh chat lên backend → Cloudinary.
  /// Trả về URL Cloudinary nếu thành công, null nếu lỗi
  /// (chat_notifier sẽ fallback dùng path local).
  static Future<String?> uploadChatImage(String filePath) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('>>> [Upload] Bỏ qua: chưa đăng nhập');
        return null;
      }

      final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.uploadChatImage}');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed =
      await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      print('>>> [Upload] Status: ${streamed.statusCode}');

      if (streamed.statusCode == 200) {
        final data = jsonDecode(body);
        final url = data['url'] as String?;
        print('>>> [Upload] ✅ URL: $url');
        return url;
      }

      print('>>> [Upload] ❌ Lỗi: $body');
      return null;
    } catch (e) {
      print('>>> [Upload] ❌ Exception: $e');
      return null;
    }
  }
}
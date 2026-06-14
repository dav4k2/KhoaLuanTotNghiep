// lib/core/network/api_client.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'api_endpoints.dart';
import 'api_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // ── Headers mặc định ────────────────────────────────────────

  Map<String, String> _baseHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── POST ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final response = await _client
          .post(
        uri,
        headers: _baseHeaders(token: token),
        body: jsonEncode(body),
      )
          .timeout(ApiEndpoints.timeout);
      return _handleResponse(response, token: token);
    } on SocketException {
      throw const ApiException(
        message: 'Không thể kết nối tới máy chủ. Kiểm tra kết nối mạng.',
        statusCode: 0,
      );
    } on HttpException {
      throw const ApiException(message: 'Lỗi HTTP không xác định.', statusCode: 0);
    } on FormatException {
      throw const ApiException(message: 'Dữ liệu trả về không hợp lệ.', statusCode: 0);
    }
  }

  // ── GET → Map ───────────────────────────────────────────────

  Future<Map<String, dynamic>> get({
    required String endpoint,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    try {
      final response = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(ApiEndpoints.timeout);
      return _handleResponse(response, token: token);
    } on SocketException {
      throw const ApiException(
        message: 'Không thể kết nối tới máy chủ. Kiểm tra kết nối mạng.',
        statusCode: 0,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  // ── GET → List ──────────────────────────────────────────────
  // Dùng khi backend trả về JSON array thay vì JSON object.

  Future<List<dynamic>> getList({
    required String endpoint,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    try {
      final response = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(ApiEndpoints.timeout);
      return _handleListResponse(response, token: token);
    } on SocketException {
      throw const ApiException(
        message: 'Không thể kết nối tới máy chủ. Kiểm tra kết nối mạng.',
        statusCode: 0,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> delete({
    required String endpoint,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final response = await _client
          .delete(uri, headers: _baseHeaders(token: token))
          .timeout(ApiEndpoints.timeout);
      return _handleResponse(response, token: token);
    } on SocketException {
      throw const ApiException(message: 'Không thể kết nối tới máy chủ.', statusCode: 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  // ── Xử lý Response (Map) ─────────────────────────────────────

  Future<Map<String, dynamic>> _handleResponse(
      http.Response response, {
        String? token,
      }) async {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return {};
      throw ApiException(
        message: 'Không có phản hồi từ máy chủ.',
        statusCode: response.statusCode,
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    }

    // ── Xử lý 401 / 403 thông minh ──────────────────────────
    // Trước khi throw, kiểm tra token còn thực sự hợp lệ không.
    // Nếu /auth/me pass → lỗi này là do quyền (403) chứ không phải
    // token hết hạn → throw với statusCode gốc để UI xử lý đúng.
    // Nếu /auth/me cũng fail → token thực sự invalid → throw 401.
    if (response.statusCode == 401 || response.statusCode == 403) {
      final isReallyExpired = await _verifyTokenExpired(token);
      if (isReallyExpired) {
        throw const ApiException(
          message: 'Phiên đăng nhập đã hết hạn.',
          statusCode: 401,
        );
      }
      // Token vẫn hợp lệ → lỗi 403 thực sự (không có quyền)
    }

    final message = _extractMessage(body);
    throw ApiException(message: message, statusCode: response.statusCode);
  }

  // ── Xử lý Response (List) ────────────────────────────────────

  Future<List<dynamic>> _handleListResponse(
      http.Response response, {
        String? token,
      }) async {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return [];
      throw ApiException(
        message: 'Không có phản hồi từ máy chủ.',
        statusCode: response.statusCode,
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is List) return body;
      if (body is Map && body.containsKey('data')) return body['data'] as List;
      return [];
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      final isReallyExpired = await _verifyTokenExpired(token);
      if (isReallyExpired) {
        throw const ApiException(
          message: 'Phiên đăng nhập đã hết hạn.',
          statusCode: 401,
        );
      }
    }

    final message = _extractMessage(body);
    throw ApiException(message: message, statusCode: response.statusCode);
  }

  // ── Verify token bằng cách gọi /auth/me ──────────────────────
  // Trả về true nếu token THỰC SỰ hết hạn / không hợp lệ.
  // Trả về false nếu token vẫn OK (lỗi 403 là do thiếu quyền).

  Future<bool> _verifyTokenExpired(String? token) async {
    if (token == null || token.isEmpty) return true;
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.me}');
      final response = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(const Duration(seconds: 5)); // timeout ngắn hơn
      // Nếu /auth/me trả 2xx → token còn hợp lệ
      return response.statusCode < 200 || response.statusCode >= 300;
    } catch (_) {
      // Không kết nối được → không thể xác định → coi là token vẫn OK
      // để tránh logout oan khi mất mạng
      return false;
    }
  }

  // ── Parse error message từ FastAPI ───────────────────────────

  String _extractMessage(dynamic body) {
    if (body is! Map) return 'Có lỗi xảy ra.';

    final detail = body['detail'];
    if (detail == null) {
      return body['message']?.toString() ?? 'Có lỗi xảy ra.';
    }

    if (detail is String) return detail;

    if (detail is List && detail.isNotEmpty) {
      final messages = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final field = (item['loc'] as List?)?.lastOrNull?.toString() ?? '';
          final msg   = item['msg']?.toString() ?? '';
          if (msg.isNotEmpty) {
            messages.add(field.isNotEmpty ? '$field: $msg' : msg);
          }
        }
      }
      return messages.isNotEmpty ? messages.join(' | ') : 'Dữ liệu không hợp lệ.';
    }

    return detail.toString();
  }
}
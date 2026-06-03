// lib/core/network/api_client.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // ── Headers mặc định ────────────────────────────────────────

  Map<String, String> _baseHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',   // ← tránh ngrok warning page
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
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message:    'Không thể kết nối tới máy chủ. Kiểm tra kết nối mạng.',
        statusCode: 0,
      );
    } on HttpException {
      throw const ApiException(
          message: 'Lỗi HTTP không xác định.', statusCode: 0);
    } on FormatException {
      throw const ApiException(
          message: 'Dữ liệu trả về không hợp lệ.', statusCode: 0);
    }
  }

  // ── GET ─────────────────────────────────────────────────────

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
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message:    'Không thể kết nối tới máy chủ. Kiểm tra kết nối mạng.',
        statusCode: 0,
      );
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
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
          message: 'Không thể kết nối tới máy chủ.', statusCode: 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  // ── Xử lý Response ──────────────────────────────────────────

  Map<String, dynamic> _handleResponse(http.Response response) {
    // Body rỗng (204 No Content)
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return {};
      throw ApiException(
          message: 'Không có phản hồi từ máy chủ.',
          statusCode: response.statusCode);
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    // 2xx → thành công
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    }

    // Lỗi — parse message từ FastAPI
    final message = _extractMessage(body);
    throw ApiException(message: message, statusCode: response.statusCode);
  }

  // ── Parse error message từ FastAPI ───────────────────────────
  // FastAPI trả về:
  //   { "detail": "string" }                        ← lỗi thông thường
  //   { "detail": [{"loc": [...], "msg": "..."}] }  ← validation error 422

  String _extractMessage(dynamic body) {
    if (body is! Map) return 'Có lỗi xảy ra.';

    final detail = body['detail'];
    if (detail == null) {
      return body['message']?.toString() ?? 'Có lỗi xảy ra.';
    }

    // detail là string → trả về thẳng
    if (detail is String) return detail;

    // detail là list → FastAPI validation errors
    if (detail is List && detail.isNotEmpty) {
      final messages = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final field = (item['loc'] as List?)?.lastOrNull?.toString() ?? '';
          final msg   = item['msg']?.toString() ?? '';
          if (msg.isNotEmpty) {
            // VD: "email: value is not a valid email address"
            messages.add(field.isNotEmpty ? '$field: $msg' : msg);
          }
        }
      }
      return messages.isNotEmpty ? messages.join(' | ') : 'Dữ liệu không hợp lệ.';
    }

    return detail.toString();
  }
}
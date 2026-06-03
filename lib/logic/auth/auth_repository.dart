// lib/logic/auth/auth_repository.dart
// Chỉ thay đổi: saveToken truyền thêm expiresInSeconds

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import 'auth_model.dart';

abstract class AuthRepositoryBase {
  Future<AuthResponse> signUp(SignUpRequest request);
  Future<AuthResponse> login(LoginRequest request);
  Future<UserInfo> getMe();
}

class AuthRepository implements AuthRepositoryBase {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<AuthResponse> signUp(SignUpRequest request) async {
    try {
      final json     = await _apiClient.post(
        endpoint: ApiEndpoints.register,
        body: request.toJson(),
      );
      final response = AuthResponse.fromJson(json);
      await _saveSession(response);
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final json     = await _apiClient.post(
        endpoint: ApiEndpoints.login,
        body: request.toJson(),
      );
      final response = AuthResponse.fromJson(json);
      await _saveSession(response);
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  @override
  Future<UserInfo> getMe() async {
    final token = await TokenStorage.getToken();
    try {
      final json = await _apiClient.get(
        endpoint: ApiEndpoints.me,
        token: token,
      );
      return UserInfo.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  Future<void> _saveSession(AuthResponse response) async {
    // Lấy expires_in từ response nếu backend trả về, mặc định 7 ngày
    final expiresIn = response.expiresIn ?? (7 * 24 * 3600);
    await TokenStorage.saveToken(
      response.accessToken,
      expiresInSeconds: expiresIn,
    );
    await TokenStorage.saveUserInfo(
      userId:   response.user.id,
      email:    response.user.email,
      fullName: response.user.fullName,
    );
  }
}
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'models/user_model.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  // Masuk menggunakan email dan kata sandi
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;

    await _storage.saveSession(token: token, user: userJson);
    return UserModel.fromJson(userJson);
  }

  // Keluar dan bersihkan kredensial sesi
  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // Abaikan kegagalan jaringan saat logout agar sesi lokal tetap terhapus
    } finally {
      await _storage.clearSession();
    }
  }

  // Cek apakah pengguna sudah memiliki sesi aktif
  Future<UserModel?> getCachedUser() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    final userJson = await _storage.getUser();
    if (userJson == null) return null;

    return UserModel.fromJson(userJson);
  }

  // Validasi sesi aktif ke server
  Future<UserModel?> verifySession() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    try {
      final response = await _api.get(ApiEndpoints.me);
      final data = response['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      await _storage.saveSession(token: token, user: userJson);
      return UserModel.fromJson(userJson);
    } catch (_) {
      await _storage.clearSession();
      return null;
    }
  }
}

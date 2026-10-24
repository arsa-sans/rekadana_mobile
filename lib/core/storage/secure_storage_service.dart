import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyBaseUrl = 'custom_base_url';
  static const String _keyLastOrgId = 'last_org_id';
  static const String _keyLastEventId = 'last_event_id';

  // Simpan token sesi dan data pengguna
  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUser, value: jsonEncode(user));
  }

  // Ambil token sesi aktif
  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Ambil data profil pengguna
  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Hapus sesi saat logout
  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keyLastOrgId);
    await _storage.delete(key: _keyLastEventId);
  }

  // Pengaturan Base URL
  Future<void> setBaseUrl(String url) async {
    await _storage.write(key: _keyBaseUrl, value: url);
  }

  Future<String> getBaseUrl() async {
    final custom = await _storage.read(key: _keyBaseUrl);
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    return ApiEndpoints.defaultBaseUrl;
  }

  // Memori pilihan konteks organisasi & kegiatan
  Future<void> saveContextIds({String? orgId, String? eventId}) async {
    if (orgId != null) await _storage.write(key: _keyLastOrgId, value: orgId);
    if (eventId != null) await _storage.write(key: _keyLastEventId, value: eventId);
  }

  Future<String?> getLastOrgId() async => await _storage.read(key: _keyLastOrgId);
  Future<String?> getLastEventId() async => await _storage.read(key: _keyLastEventId);
}

import 'dart:io';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? fieldErrors;

  ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors,
  });

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  final SecureStorageService _storage = SecureStorageService();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Sinkronisasi Base URL jika ada perubahan konfigurasi
          final currentBaseUrl = await _storage.getBaseUrl();
          options.baseUrl = currentBaseUrl;

          // Suntikkan token Bearer jika tersedia
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          final mappedError = _mapDioError(e);
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: mappedError,
            ),
          );
        },
      ),
    );
  }

  Dio get client => _dio;

  ApiException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Koneksi ke server terputus karena batas waktu habis. Silakan coba lagi.',
        code: 'TIMEOUT',
      );
    }

    if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
      return ApiException(
        message: 'Tidak dapat terhubung ke server. Pastikan jaringan internet aktif dan alamat server benar.',
        code: 'CONNECTION_FAILED',
      );
    }

    final response = e.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final errorObj = data['error'];
      if (errorObj is Map<String, dynamic>) {
        final code = errorObj['code'] as String?;
        final message = errorObj['message'] as String? ?? 'Terjadi kesalahan pada permintaan.';
        final errors = errorObj['errors'] as Map<String, dynamic>?;

        return ApiException(
          message: message,
          code: code,
          statusCode: response.statusCode,
          fieldErrors: errors,
        );
      }
    }

    switch (response?.statusCode) {
      case 400:
        return ApiException(message: 'Format data permintaan tidak valid.', statusCode: 400);
      case 401:
        return ApiException(
          message: 'Sesi Anda telah kedaluwarsa. Silakan masuk kembali.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      case 403:
        return ApiException(
          message: 'Akses ditolak. Anda tidak memiliki izin untuk tindakan ini.',
          code: 'FORBIDDEN',
          statusCode: 403,
        );
      case 404:
        return ApiException(message: 'Data yang dicari tidak ditemukan.', statusCode: 404);
      case 422:
        return ApiException(
          message: 'Data yang dimasukkan tidak lolos validasi server.',
          code: 'VALIDATION_ERROR',
          statusCode: 422,
        );
      case 500:
        return ApiException(
          message: 'Terjadi gangguan internal pada server. Silakan hubungi administrator.',
          code: 'SERVER_ERROR',
          statusCode: 500,
        );
      default:
        return ApiException(
          message: 'Terjadi kesalahan tidak terduga pada jaringan (${e.message ?? 'Unknown'}).',
          statusCode: response?.statusCode,
        );
    }
  }

  // Helper metode GET
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal mengambil data.');
    }
  }

  // Helper metode POST
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memproses data.');
    }
  }

  // Helper metode upload multipart
  Future<dynamic> postMultipart(String path, FormData formData, {void Function(int, int)? onSendProgress}) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal mengunggah file.');
    }
  }
}

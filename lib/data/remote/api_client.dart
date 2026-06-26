// ====================================
// API Client — Dio Instance + Interceptors
// ====================================

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/env.dart';

const _storage = FlutterSecureStorage();

final Dio apiClient = _createApiClient();

Dio _createApiClient() {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiUrl,
    connectTimeout: const Duration(seconds: AppConfig.httpTimeoutSeconds),
    receiveTimeout: const Duration(seconds: AppConfig.httpTimeoutSeconds),
    headers: {'Content-Type': 'application/json'},
  ));

  // ── Request Interceptor ───────────────────────────────────────
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        // 1. API Key device
        final apiKey = await _storage.read(key: 'device_api_key');
        if (apiKey != null) {
          options.headers['x-api-key'] = apiKey;
        }

        // 2. Bearer token fallback
        final token = await _storage.read(key: 'better_auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (err) {
        // ignore — log only
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Auto logout — lazy import to avoid circular dependency
        try {
          await _storage.delete(key: 'better_auth_token');
          await _storage.delete(key: 'device_api_key');
          await _storage.delete(key: 'device_api_key_id');
          await _storage.delete(key: 'pegawai_data');
          await _storage.delete(key: 'device_private_key');
          await _storage.delete(key: 'device_public_key');
        } catch (_) {}
      }
      handler.next(error);
    },
  ));

  return dio;
}

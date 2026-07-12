// ====================================
// API Client — Dio Instance + Interceptors
// ====================================

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/env.dart';

const _storage = FlutterSecureStorage();

String? _cachedApiKey;
String? _cachedToken;

/// Menghapus cache otentikasi di memori (panggil saat logout)
void invalidateAuthCache() {
  _cachedApiKey = null;
  _cachedToken = null;
}

void Function()? onUnauthenticated;

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
        _cachedApiKey ??= await _storage.read(key: 'device_api_key');
        if (_cachedApiKey != null) {
          options.headers['x-api-key'] = _cachedApiKey;
        }
        
        // 2. Bearer token untuk otentikasi sesi BetterAuth
        _cachedToken ??= await _storage.read(key: 'better_auth_token');
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
      } catch (err) {
        // ignore — log only
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Auto logout — lazy import to avoid circular dependency
        invalidateAuthCache();
        try {
          await _storage.delete(key: 'better_auth_token');
          await _storage.delete(key: 'device_api_key');
          await _storage.delete(key: 'device_api_key_id');
          await _storage.delete(key: 'pegawai_data');
          await _storage.delete(key: 'device_private_key');
          await _storage.delete(key: 'device_public_key');
        } catch (_) {}
        if (onUnauthenticated != null) {
          onUnauthenticated!();
        }
      }
      handler.next(error);
    },
  ));

  return dio;
}

// ====================================
// Auth Service — Login, Device Key, Logout
// ====================================

import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/config/env.dart';
import '../core/utils/crypto_utils.dart';
import '../data/models/pegawai.dart';
import '../data/remote/api_client.dart';

const _storage = FlutterSecureStorage();

const _tokenKey = 'better_auth_token';
const _pegawaiKey = 'pegawai_data';
const _apiKeyKey = 'device_api_key';
const _apiKeyIdKey = 'device_api_key_id';

class AuthService {
  AuthService._();

  // ── Step 1: Login NIP/username → fetch pegawai → register device ──────
  static Future<Pegawai> login(String identifier, String password) async {
    final isEmail = identifier.contains('@');
    final endpoint = isEmail ? '/auth/sign-in/email' : '/auth/sign-in/username';
    final payload = isEmail
        ? {'email': identifier, 'password': password}
        : {'username': identifier, 'password': password};

    // POST ke Better Auth sign-in endpoint
    final response = await apiClient.post(endpoint, data: payload);

    final data = response.data;
    final token = data['token'] ?? data['session']?['token'];
    if (token != null) {
      await _storage.write(key: _tokenKey, value: token as String);
    }

    // Ambil data pegawai dari server
    final pegawai = await fetchMyPegawai();
    if (pegawai == null) {
      throw Exception('Data pegawai tidak ditemukan untuk akun ini');
    }

    // Simpan data pegawai ke SecureStore
    await _storage.write(key: _pegawaiKey, value: jsonEncode(pegawai.toJson()));

    // Register device API key
    try {
      await registerDeviceKey();
    } catch (e) {
      // Jika registerDeviceKey gagal (misal karena gagal generate keypair)
      // maka batalkan proses login dengan menghapus session yang baru saja dibuat
      await logout();
      rethrow;
    }

    return pegawai;
  }

  // ── Step 2: Register device API key ─────────────────────────────────────
  static Future<void> registerDeviceKey() async {
    final deviceId = await _getDeviceId();
    final deviceModel = await _getDeviceModel();
    final appVersion = AppConfig.appVersion;

    // Cek apakah keypair sudah ada, jika belum generate baru
    var privateKey = await _storage.read(key: 'device_private_key');
    var publicKey = await _storage.read(key: 'device_public_key');

    if (privateKey == null || publicKey == null) {
      try {
        final keys = generateKeyPair(bits: 1024);
        privateKey = keys.privateKeyPem;
        publicKey = keys.publicKeyPem;
        await _storage.write(key: 'device_private_key', value: privateKey);
        await _storage.write(key: 'device_public_key', value: publicKey);
      } catch (err) {
        debugPrint('Error generating RSA keypair: $err');
        throw Exception('Gagal membuat kunci keamanan perangkat.');
      }
    }

    // Buat API key baru untuk device ini
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final response = await apiClient.post(
        '/auth/api-key/create',
        data: {
          'configId': 'presensi',
          'name': '${platform}_$deviceId',
          'expiresIn': 60 * 60 * 24 * 30, // 30 hari
          'metadata': {
            'deviceId': deviceId,
            'deviceModel': deviceModel,
            'appVersion': appVersion,
            'platform': platform,
            'registeredAt': DateTime.now().toIso8601String(),
            'publicKey': publicKey,
          },
        },
      );

      final data = response.data;
      if (data['key'] != null) {
        await _storage.write(key: _apiKeyKey, value: data['key'] as String);
      } else {
        throw Exception('Gagal mendapatkan API Key dari server.');
      }

      if (data['id'] != null) {
        await _storage.write(key: _apiKeyIdKey, value: data['id'] as String);
      }
    } catch (err) {
      throw Exception('Gagal mendaftarkan perangkat. Silakan hubungi admin atau coba lagi.');
    }
  }

  // ── Ambil API key untuk dikirim di header request ───────────────────────
  static Future<String?> getDeviceApiKey() async {
    return _storage.read(key: _apiKeyKey);
  }

  // ── Session token ────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  // ── Data pegawai dari SecureStore ───────────────────────────────────────
  static Future<Pegawai?> getPegawai() async {
    final raw = await _storage.read(key: _pegawaiKey);
    if (raw == null) return null;
    try {
      return Pegawai.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Cek apakah session valid ───────────────────────────────────────────
  static Future<bool> hasValidSession() async {
    final pegawai = await _storage.read(key: _pegawaiKey);
    final apiKey = await _storage.read(key: _apiKeyKey);
    final apiKeyId = await _storage.read(key: _apiKeyIdKey);
    final privateKey = await _storage.read(key: 'device_private_key');

    return pegawai != null &&
        apiKey != null &&
        apiKeyId != null &&
        privateKey != null;
  }

  // ── Logout ─────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      final keyId = await _storage.read(key: _apiKeyIdKey);
      if (keyId != null) {
        await apiClient.post('/auth/api-key/delete', data: {'keyId': keyId});
      }
      await apiClient.post('/auth/sign-out');
    } catch (_) {}

    // Bersihkan semua data lokal
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _pegawaiKey),
      _storage.delete(key: _apiKeyKey),
      _storage.delete(key: _apiKeyIdKey),
      _storage.delete(key: 'device_private_key'),
      _storage.delete(key: 'device_public_key'),
    ]);
  }

  // ── Fetch profil pegawai dari server ───────────────────────────────────
  static Future<Pegawai?> fetchMyPegawai() async {
    try {
      final response = await apiClient.get('/auth/me/pegawai');
      return Pegawai.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Sync data pegawai dengan menyimpannya ke SecureStore ──────────────────
  static Future<Pegawai?> syncPegawai() async {
    final pegawai = await fetchMyPegawai();
    if (pegawai != null) {
      await _storage.write(key: _pegawaiKey, value: jsonEncode(pegawai.toJson()));
    }
    return pegawai;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown-ios';
      }
    } catch (_) {}
    return 'unknown-device';
  }

  static Future<String> _getDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.utsname.machine;
      }
    } catch (_) {}
    return 'unknown';
  }
}

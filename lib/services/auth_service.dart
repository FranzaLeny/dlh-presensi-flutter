// ====================================
// Auth Service — Login, Device Key, Logout
// ====================================

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../core/config/env.dart';
import '../core/utils/crypto_utils.dart';
import '../core/utils/device_utils.dart';
import '../data/models/pegawai.dart';
import '../data/remote/api_client.dart';
import 'storage_service.dart';

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

    _cachedHasSession = null; // Invalidate session cache upon new login

    // Ambil data pegawai dari server dan sinkronisasi (download foto)
    final pegawai = await syncPegawai();
    if (pegawai == null) {
      throw Exception('Data pegawai tidak ditemukan untuk akun ini');
    }

    // Register device API key
    try {
      await registerDeviceKey();
    } catch (e) {
      // Jika registerDeviceKey gagal (misal karena gagal generate keypair)
      // maka batalkan proses login dengan menghapus session yang baru saja dibuat
      invalidateAuthCache();
      await logout();
      rethrow;
    }

    return pegawai;
  }

  // ── Step 2: Register device API key ─────────────────────────────────────
  static Future<void> registerDeviceKey() async {
    final deviceId = await DeviceUtils.getDeviceId();
    final deviceModel = await DeviceUtils.getDeviceModel();
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
      throw Exception(
        'Gagal mendaftarkan perangkat. Silakan hubungi admin atau coba lagi.',
      );
    }
  }

  // ── Auth: Ubah Password ───────────────────────────────────────────────
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    bool revokeOtherSessions = true,
  }) async {
    await apiClient.post(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'revokeOtherSessions': revokeOtherSessions,
      },
    );
  }

  // ── Auth: Ubah Email (Kirim OTP) ──────────────────────────────────────
  static Future<void> sendChangeEmailOtp(String newEmail) async {
    await apiClient.post(
      '/auth/email-otp/send-verification-otp',
      data: {'email': newEmail, 'type': 'change-email'},
    );
  }

  // ── Auth: Ubah Email (Verifikasi OTP) ─────────────────────────────────
  static Future<void> verifyChangeEmailOtp({
    required String newEmail,
    required String otp,
  }) async {
    await apiClient.post(
      '/auth/email-otp/verify-email',
      data: {'email': newEmail, 'otp': otp},
    );
  }

  // ── Auth: Lupa Password (Kirim OTP) ───────────────────────────────────
  static Future<void> sendForgetPasswordOtp(String email) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    await dio.post('/auth/forget-password', data: {'email': email});
  }

  // ── Auth: Reset Password ──────────────────────────────────────────────
  static Future<void> resetPassword({
    required String newPassword,
    required String otp,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    await dio.post(
      '/auth/reset-password',
      data: {'newPassword': newPassword, 'otp': otp},
    );
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

  static bool? _cachedHasSession;

  // ── Cek apakah session valid ───────────────────────────────────────────
  static Future<bool> hasValidSession() async {
    if (_cachedHasSession != null) return _cachedHasSession!;
    final pegawai = await _storage.read(key: _pegawaiKey);
    final apiKey = await _storage.read(key: _apiKeyKey);
    final apiKeyId = await _storage.read(key: _apiKeyIdKey);
    final privateKey = await _storage.read(key: 'device_private_key');

    _cachedHasSession =
        pegawai != null &&
        apiKey != null &&
        apiKeyId != null &&
        privateKey != null;
    return _cachedHasSession!;
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
    _cachedHasSession = false;
    invalidateAuthCache();
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
      final Map<String, dynamic> body = response.data;
      final payload = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body;
      return Pegawai.fromJson(payload);
    } catch (e) {
      debugPrint('Error fetchMyPegawai: $e');
      return null;
    }
  }

  // ── Sync data pegawai dengan menyimpannya ke SecureStore ──────────────────
  static Future<Pegawai?> syncPegawai() async {
    final oldPegawai = await getPegawai();
    Pegawai? newPegawai = await fetchMyPegawai();

    if (newPegawai != null) {
      String? localFotoPath = oldPegawai?.localFotoPath;

      // Cek apakah foto profil berbeda (key berbeda)
      bool isImageChanged = newPegawai.image != oldPegawai?.image;
      bool isLocalFileMissing = true;

      if (oldPegawai?.localFotoPath != null) {
        isLocalFileMissing = !(await File(oldPegawai!.localFotoPath!).exists());
      }

      if (newPegawai.image != null && (isImageChanged || isLocalFileMissing)) {
        try {
          final String key = newPegawai.image!;
          final publicUrl = await StorageService.getPreviewUrl(
            entity: 'profile',
            key: key,
          );

          String downloadUrl = publicUrl;
          if (!publicUrl.startsWith('http')) {
            downloadUrl = AppConfig.apiUrl + publicUrl;
          }

          final dir = await getApplicationDocumentsDirectory();
          final fileName =
              'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedPath = '${dir.path}/$fileName';

          await Dio().download(downloadUrl, savedPath);
          localFotoPath = savedPath;

          // Hapus foto lama jika ada
          if (oldPegawai?.localFotoPath != null) {
            final oldFile = File(oldPegawai!.localFotoPath!);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          }
        } catch (e) {
          debugPrint('Error syncing profile image: $e');
        }
      }

      // Pertahankan localFotoPath (jika didownload atau tidak berubah)
      newPegawai = newPegawai.copyWith(localFotoPath: localFotoPath);

      await _storage.write(
        key: _pegawaiKey,
        value: jsonEncode(newPegawai.toJson()),
      );
    }
    return newPegawai;
  }

  // ── Auth: Ubah Foto Profil (Update Session) ─────────────────────────
  static Future<void> updateProfilePhoto(String key) async {
    await apiClient.post('/auth/update-user', data: {'image': key});
  }

  // ── Manual Update Local Foto Path (untuk bypass download) ─────────────
  static Future<void> setLocalProfilePhoto(String filePath) async {
    final oldPegawai = await getPegawai();
    if (oldPegawai == null) return;

    // Kita pindahkan/salin foto yang baru dipilih ke path lokal yang unik
    // agar Image.file/FileImage merefresh cache-nya karena nama filenya baru.
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = '${dir.path}/$fileName';

    await File(filePath).copy(savedPath);

    // Hapus foto lama jika ada
    if (oldPegawai.localFotoPath != null) {
      final oldFile = File(oldPegawai.localFotoPath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    final newPegawai = oldPegawai.copyWith(localFotoPath: savedPath);

    await _storage.write(
      key: _pegawaiKey,
      value: jsonEncode(newPegawai.toJson()),
    );
  }
}

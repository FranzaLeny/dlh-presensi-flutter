// ====================================
// Sync Engine — Sinkronisasi Data Presensi
// ====================================

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/utils/crypto_utils.dart';
import '../core/utils/error_utils.dart';
import '../data/local/presensi_dao.dart';
import '../data/local/settings_dao.dart';
import '../data/models/pengaturan_presensi.dart';
import '../data/models/presensi_log.dart';
import '../data/models/sync_response.dart';
import '../data/remote/api_client.dart';
import 'auth_service.dart';
import 'time_service.dart';

const _storage = FlutterSecureStorage();

bool _isSyncing = false;

/// Mendapatkan unique device ID
Future<String> _getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown-ios';
    }
  } catch (_) {}
  return 'unknown-device';
}

/// Sinkronisasi pengaturan presensi dari server ke SQLite lokal
Future<void> syncSettings({String? skpdId}) async {
  try {
    var resolvedSkpdId = skpdId;

    // Jika skpdId tidak ditentukan, coba ambil dari data pegawai
    if (resolvedSkpdId == null) {
      final pegawai = await AuthService.fetchMyPegawai();
      resolvedSkpdId = pegawai?.skpdId;
    }

    if (resolvedSkpdId == null) return;

    final response = await apiClient.get(
      '/umum/presensi/pengaturan/skpd',
      queryParameters: {'skpdId': resolvedSkpdId},
    );

    final data = response.data;
    if (data != null) {
      final pengaturan = PengaturanPresensi(
        id: (data['id'] ?? data['skpdId'] ?? 'default') as String,
        skpdId: data['skpdId'] as String,
        namaKantor: data['namaKantor'] as String?,
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        radius: (data['radius'] as num?)?.toInt() ?? 100,
        jamMasukMulai: (data['jamMasukMulai'] as String?) ?? '07:30:00',
        jamMasukSelesai: (data['jamMasukSelesai'] as String?) ?? '08:30:00',
        jamIstirahatMulai: (data['jamIstirahatMulai'] as String?) ?? '12:00:00',
        jamIstirahatSelesai:
            (data['jamIstirahatSelesai'] as String?) ?? '13:00:00',
        jamPulangMulai: (data['jamPulangMulai'] as String?) ?? '16:00:00',
        jamPulangSelesai: (data['jamPulangSelesai'] as String?) ?? '17:00:00',
        updatedAt: data['updatedAt'] as String?,
      );
      await SettingsDao.save(pengaturan);
      await TimeService.syncTime();
    }
  } catch (err) {
    // Log warning only
  }
}

/// Main sync engine — sinkronisasi log presensi ke backend
Future<({int synced, int errors})> runSyncEngine({String? skpdId}) async {
  // Prevent concurrent sync
  if (_isSyncing) return (synced: 0, errors: 0);

  _isSyncing = true;
  var syncedCount = 0;
  var errorCount = 0;

  try {
    // 1. Cek koneksi
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return (synced: 0, errors: 0);
    }

    // Ambil data pengaturan presensi terbaru
    await syncSettings(skpdId: skpdId);

    // 2. Ambil log belum sync
    final unsyncedLogs = await PresensiDao.getUnsynced();
    if (unsyncedLogs.isEmpty) return (synced: 0, errors: 0);

    // 3. Upload foto untuk setiap log yang perlu
    for (final log in unsyncedLogs) {
      try {
        await _uploadPendingPhotos(log);
      } catch (_) {
        errorCount++;
      }
    }

    // 4. Kirim batch ke backend
    final refreshedLogs = await PresensiDao.getUnsynced();
    if (refreshedLogs.isEmpty) return (synced: 0, errors: errorCount);

    final deviceId = await _getDeviceId();
    final payloadItems = _logsToSyncItems(refreshedLogs, deviceId);
    if (payloadItems.isEmpty) return (synced: 0, errors: errorCount);

    final apiKeyId = await _storage.read(key: 'device_api_key_id');
    final privateKey = await _storage.read(key: 'device_private_key');

    if (apiKeyId == null || privateKey == null) {
      return (synced: 0, errors: errorCount + refreshedLogs.length);
    }

    String signature;
    try {
      signature = signPayload(
        payloadItems.map((item) => item.toJson()).toList(),
        privateKey,
      );
    } catch (_) {
      return (synced: 0, errors: errorCount + refreshedLogs.length);
    }

    final response = await apiClient.post(
      '/umum/presensi/log',
      data: {
        'logs': payloadItems.map((item) => item.toJson()).toList(),
        'apiKeyId': apiKeyId,
        'signature': signature,
      },
    );

    final syncResponse = SyncResponse.fromJson(
      response.data as Map<String, dynamic>,
    );

    // 5. Tandai sebagai synced
    if (syncResponse.synced.isNotEmpty) {
      final syncedIds = syncResponse.synced.map((item) => item.id).toList();
      if (syncedIds.isNotEmpty) {
        await PresensiDao.markAsSynced(syncedIds);
        syncedCount = syncedIds.length;
      }
    }

    if (syncResponse.unSyncedIds.isNotEmpty) {
      errorCount += syncResponse.unSyncedIds.length;
    }
  } catch (error) {
    errorCount++;
  } finally {
    _isSyncing = false;
  }

  return (synced: syncedCount, errors: errorCount);
}

/// Upload foto yang pending untuk sebuah log
Future<void> _uploadPendingPhotos(PresensiLog log) async {
  if (log.isLuarRadius > 0 && log.fotoPath != null && log.fotoUrl == null) {
    final url = await _uploadFoto(log.fotoPath!, log.tipe.toDbString(), log.tanggal);
    await PresensiDao.updateFotoUrl(log.id, url);
  }
}

/// Upload foto ke Cloud Storage via presigned URL
Future<String> _uploadFoto(
    String localPath, String tipe, String tanggal) async {
  // 1. Minta presigned URL dari backend
  final response = await apiClient.post(
    '/umum/presensi/presigned-url',
    data: {
      'contentType': 'image/jpeg',
      'tipePresensi': tipe,
      'tanggal': tanggal,
    },
  );

  final presigned = PresignedUrlResponse.fromJson(
    response.data as Map<String, dynamic>,
  );

  // 2. Upload langsung ke Cloud Storage
  final file = File(localPath);
  final bytes = await file.readAsBytes();

  await Dio().put(
    presigned.uploadUrl,
    data: Stream.fromIterable(bytes.map((e) => [e])),
    options: Options(
      headers: {
        'Content-Type': 'image/jpeg',
        'Content-Length': bytes.length,
      },
    ),
  );

  // 3. Return public URL
  return presigned.publicUrl;
}

/// Konversi daftar PresensiLog ke array SyncLogItem
List<SyncLogItem> _logsToSyncItems(
    List<PresensiLog> logs, String deviceId) {
  return logs
      .map((log) => SyncLogItem(
            id: log.id,
            pegawaiId: log.pegawaiId,
            pengaturanId: log.pengaturanId,
            tanggal: log.tanggal,
            tipe: log.tipe.toDbString(),
            waktu: log.waktu,
            latitude: log.latitude != 0 ? log.latitude.toString() : '0',
            longitude: log.longitude != 0 ? log.longitude.toString() : '0',
            fotoUrl: log.fotoUrl,
            deviceId: deviceId,
          ))
      .toList();
}

/// Sinkronisasi satu log presensi tertentu ke backend
Future<bool> syncSingleLog(String logId) async {
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.none)) {
    throw Exception('Tidak ada koneksi internet');
  }

  final pendingLogs = await PresensiDao.getUnsynced();
  final log = pendingLogs.where((l) => l.id == logId).firstOrNull;
  if (log == null) {
    throw Exception('Data presensi tidak ditemukan di lokal');
  }

  await _uploadPendingPhotos(log);

  final deviceId = await _getDeviceId();
  final payloadItems = _logsToSyncItems([log], deviceId);

  final apiKeyId = await _storage.read(key: 'device_api_key_id');
  final privateKey = await _storage.read(key: 'device_private_key');

  if (apiKeyId == null || privateKey == null) {
    throw Exception('Kredensial enkripsi perangkat tidak ditemukan');
  }

  final signature = signPayload(
    payloadItems.map((item) => item.toJson()).toList(),
    privateKey,
  );

  final response = await apiClient.post(
    '/umum/presensi/log',
    data: {
      'logs': payloadItems.map((item) => item.toJson()).toList(),
      'apiKeyId': apiKeyId,
      'signature': signature,
    },
  );

  final syncResponse = SyncResponse.fromJson(
    response.data as Map<String, dynamic>,
  );

  if (syncResponse.synced.any((item) => item.id == logId)) {
    await PresensiDao.markAsSynced([logId]);
    return true;
  }

  return false;
}

/// Cek apakah sync sedang berjalan
bool isSyncRunning() => _isSyncing;

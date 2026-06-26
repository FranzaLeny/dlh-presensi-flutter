// ====================================
// Sync Engine — Sinkronisasi Data Presensi
// ====================================

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/utils/crypto_utils.dart';
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
      final latitudeVal = data['latitude'];
      final longitudeVal = data['longitude'];
      final radiusVal = data['radius'];

      final pengaturan = PengaturanPresensi(
        id: (data['id'] ?? data['skpdId'] ?? 'default').toString(),
        skpdId: data['skpdId'].toString(),
        namaKantor: data['skpd']?['nama']?.toString(),
        latitude: latitudeVal is num
            ? latitudeVal.toDouble()
            : double.tryParse(latitudeVal?.toString() ?? '0') ?? 0.0,
        longitude: longitudeVal is num
            ? longitudeVal.toDouble()
            : double.tryParse(longitudeVal?.toString() ?? '0') ?? 0.0,
        radius: radiusVal is num
            ? radiusVal.toInt()
            : int.tryParse(radiusVal?.toString() ?? '100') ?? 100,
        jamMasukMulai: data['jamMasukMulai']?.toString() ?? '07:30:00',
        jamMasukSelesai: data['jamMasukSelesai']?.toString() ?? '08:30:00',
        jamIstirahatMulai: data['jamIstirahatMulai']?.toString() ?? '12:00:00',
        jamIstirahatSelesai:
            data['jamIstirahatSelesai']?.toString() ?? '13:00:00',
        jamPulangMulai: data['jamPulangMulai']?.toString() ?? '16:00:00',
        jamPulangSelesai: data['jamPulangSelesai']?.toString() ?? '17:00:00',
        updatedAt: data['updatedAt']?.toString(),
      );
      await SettingsDao.save(pengaturan);
      await TimeService.syncTime();
    }
  } catch (err, stack) {
    debugPrint('Error in syncSettings: $err');
    debugPrint(stack.toString());
    // Log warning only
  }
}

/// Menjalankan sinkronisasi penuh (Pengaturan + Unsynced Logs)
Future<({int synced, int errors})> runFullSync({String? skpdId}) async {
  if (_isSyncing) return (synced: 0, errors: 0);
  _isSyncing = true;
  try {
    await syncSettings(skpdId: skpdId);
    return await syncUnsyncedLogs();
  } finally {
    _isSyncing = false;
  }
}

/// Alias ke syncSettings agar konsisten namanya
Future<void> syncPengaturan({String? skpdId}) => syncSettings(skpdId: skpdId);

/// Hanya melakukan push/sinkronisasi semua log presensi yang belum tersinkronisasi di lokal
Future<({int synced, int errors})> syncUnsyncedLogs() async {
  final logs = await PresensiDao.getUnsynced();
  return _syncLogBatch(logs);
}

/// Hanya melakukan push/sinkronisasi sisa data presensi yang belum tersinkronisasi pada bulan tertentu,
/// lalu menarik (Pull) data riwayat yang valid dari server untuk bulan tersebut.
Future<({int synced, int errors})> syncLogsBulanan(int year, int month) async {
  final pegawai = await AuthService.getPegawai();
  if (pegawai == null) return (synced: 0, errors: 0);

  // 1. PUSH: Pastikan data lokal yang pending di-push ke server dulu
  final logs = await PresensiDao.getByMonth(pegawai.id, year, month);
  final unsyncedLogs = logs.where((l) => !l.isSynced).toList();
  final pushResult = await _syncLogBatch(unsyncedLogs);

  // 2. PULL: Tarik riwayat presensi bulan ini dari server
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      // Hitung tanggal 1 dan tanggal terakhir bulan
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0);
      
      // Ambil data dari server (berdasarkan instruksi user: akan di-handle dari sisi user di backend /log yg sama)
      final response = await apiClient.get(
        '/umum/presensi/log',
        queryParameters: {
          'tanggalMulai': startOfMonth.toIso8601String().split('T')[0],
          'tanggalSelesai': endOfMonth.toIso8601String().split('T')[0],
        },
      );
      
      final data = response.data;
      if (data != null && data['items'] is List) {
        final List<dynamic> items = data['items'];
        final serverLogs = items.map((item) => PresensiLog.fromJson(item)).toList();
        
        // 3. Simpan ke lokal dan timpa history lama
        await PresensiDao.replaceHistoryByMonth(pegawai.id, year, month, serverLogs);
      }
    }
  } catch (err) {
    debugPrint('Gagal pull sync: $err');
    // Jika gagal pull, kita tetap mengembalikan hasil push
  }

  return pushResult;
}

/// Helper internal untuk mengirim sejumlah log presensi
Future<({int synced, int errors})> _syncLogBatch(List<PresensiLog> logsToSync) async {
  if (logsToSync.isEmpty) return (synced: 0, errors: 0);

  var syncedCount = 0;
  var errorCount = 0;

  try {
    // 1. Cek koneksi
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return (synced: 0, errors: 0);
    }

    // 2. Upload foto untuk setiap log yang perlu
    for (final log in logsToSync) {
      try {
        await _uploadPendingPhotos(log);
      } catch (_) {
        errorCount++;
      }
    }

    // 3. Ambil log terbaru dari lokal (karena foto URL mungkin telah di-update)
    final allUnsynced = await PresensiDao.getUnsynced();
    final idsToSync = logsToSync.map((l) => l.id).toSet();
    final refreshedLogs = allUnsynced.where((l) => idsToSync.contains(l.id)).toList();

    if (refreshedLogs.isEmpty) return (synced: 0, errors: errorCount);

    final deviceId = await _getDeviceId();
    final payloadItems = _logsToSyncItems(refreshedLogs, deviceId);

    if (payloadItems.isEmpty) return (synced: 0, errors: errorCount);

    var apiKeyId = await _storage.read(key: 'device_api_key_id');
    var privateKey = await _storage.read(key: 'device_private_key');

    // Auto-repair if privateKey is missing but we have an apiKeyId (which means it failed to generate earlier)
    if (apiKeyId != null && privateKey == null) {
      await _storage.delete(key: 'device_api_key_id');
      await AuthService.registerDeviceKey();
      
      apiKeyId = await _storage.read(key: 'device_api_key_id');
      privateKey = await _storage.read(key: 'device_private_key');
    }

    if (apiKeyId == null || privateKey == null) {
      return (synced: 0, errors: errorCount + refreshedLogs.length);
    }

    String signature;
    try {
      signature = signPayload(
        payloadItems.map((item) => item.toJson()).toList(),
        privateKey,
      );
    } catch (e) {
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

    // 4. Tandai sebagai synced
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
    errorCount += logsToSync.length; // asumsikan sisa log gagal jika ada koneksi terputus
  }

  return (synced: syncedCount, errors: errorCount);
}

/// Upload foto yang pending untuk sebuah log
Future<void> _uploadPendingPhotos(PresensiLog log) async {
  if (log.isLuarRadius > 0 && log.fotoPath != null && log.fotoUrl == null) {
    final url = await _uploadFoto(
      log.fotoPath!,
      log.tipe.toDbString(),
      log.tanggal,
    );
    await PresensiDao.updateFotoUrl(log.id, url);
  }
}

/// Upload foto ke Cloud Storage via presigned URL
Future<String> _uploadFoto(
  String localPath,
  String tipe,
  String tanggal,
) async {
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
      headers: {'Content-Type': 'image/jpeg', 'Content-Length': bytes.length},
    ),
  );

  // 3. Return public URL
  return presigned.publicUrl;
}

/// Konversi daftar PresensiLog ke array SyncLogItem
List<SyncLogItem> _logsToSyncItems(List<PresensiLog> logs, String deviceId) {
  return logs
      .map(
        (log) => SyncLogItem(
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
        ),
      )
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

  final result = await _syncLogBatch([log]);
  if (result.errors > 0) {
    throw Exception('Gagal mengirim data ke server');
  }

  return result.synced > 0;
}

/// Cek apakah sync sedang berjalan
bool isSyncRunning() => _isSyncing;

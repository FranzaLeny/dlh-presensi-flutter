import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/utils/crypto_utils.dart';
import '../../core/utils/device_utils.dart';
import '../../data/local/presensi_dao.dart';
import '../../data/models/presensi_log.dart';
import '../../data/models/sync_response.dart';
import '../../data/remote/api_client.dart';
import '../auth_service.dart';
import 'sync_upload.dart';

const _storage = FlutterSecureStorage();

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
        final serverLogs = items
            .map((item) => PresensiLog.fromJson(item))
            .toList();

        // 3. Simpan ke lokal dan timpa history lama
        await PresensiDao.replaceHistoryByMonth(
          pegawai.id,
          year,
          month,
          serverLogs,
        );
      }
    }
  } catch (err) {
    debugPrint('Gagal pull sync: $err');
  }

  return pushResult;
}

/// Helper internal untuk mengirim sejumlah log presensi
Future<({int synced, int errors})> _syncLogBatch(
  List<PresensiLog> logsToSync,
) async {
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
    final idsToSync = <String>{};
    for (final log in logsToSync) {
      try {
        await uploadPendingPhotos(log);
        idsToSync.add(log.id);
      } catch (e) {
        debugPrint('Gagal upload foto untuk log ${log.id}: $e');
        errorCount++;
      }
    }

    // 3. Ambil log terbaru dari lokal (karena foto URL mungkin telah di-update)
    final refreshedLogs = await PresensiDao.getByIds(idsToSync.toList());

    if (refreshedLogs.isEmpty) return (synced: 0, errors: errorCount);

    final deviceId = await DeviceUtils.getDeviceId();
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

    final serializedPayload = payloadItems
        .map((item) => item.toJson())
        .toList();

    String signature;
    try {
      signature = signPayload(serializedPayload, privateKey);
    } catch (e) {
      return (synced: 0, errors: errorCount + refreshedLogs.length);
    }

    final response = await apiClient.post(
      '/umum/presensi/log',
      data: {
        'logs': serializedPayload,
        'apiKeyId': apiKeyId,
        'signature': signature,
      },
    );

    final syncResponse = SyncResponse.fromJson(
      response.data as Map<String, dynamic>,
    );

    // 4. Tandai sebagai synced dan simpan detailnya
    if (syncResponse.synced.isNotEmpty) {
      for (final item in syncResponse.synced) {
        await PresensiDao.updateSyncStatus(
          item.id,
          item.status,
          item.isLuarRadius,
          item.keterangan,
        );
      }
      syncedCount = syncResponse.synced.length;
    }

    if (syncResponse.unSyncedIds.isNotEmpty) {
      errorCount += syncResponse.unSyncedIds.length;
    }
  } catch (error) {
    errorCount += logsToSync.length;
  }

  return (synced: syncedCount, errors: errorCount);
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

  final log = await PresensiDao.getById(logId);
  if (log == null) {
    throw Exception('Data presensi tidak ditemukan di lokal');
  }

  final result = await _syncLogBatch([log]);
  if (result.errors > 0) {
    throw Exception('Gagal mengirim data ke server');
  }

  return result.synced > 0;
}

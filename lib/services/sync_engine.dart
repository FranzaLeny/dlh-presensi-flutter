// ====================================
// Sync Engine — Sinkronisasi Data Presensi (Barrel File)
// ====================================

import 'sync/sync_settings.dart';
import 'sync/sync_hari_libur.dart';
import 'sync/sync_absen.dart';
import 'sync/sync_presensi.dart';

export 'sync/sync_settings.dart';
export 'sync/sync_hari_libur.dart';
export 'sync/sync_absen.dart';
export 'sync/sync_presensi.dart';
export 'sync/sync_upload.dart';

bool _isSyncing = false;

/// Menjalankan sinkronisasi penuh (Pengaturan + Hari Libur + Absen + Unsynced Logs)
Future<({int synced, int errors})> runFullSync({String? skpdId}) async {
  if (_isSyncing) return (synced: 0, errors: 0);
  _isSyncing = true;
  try {
    await syncSettings(skpdId: skpdId);
    await syncHariLibur();
    await syncAbsenPegawai();
    return await syncUnsyncedLogs();
  } finally {
    _isSyncing = false;
  }
}


/// Cek apakah sync sedang berjalan
bool isSyncRunning() => _isSyncing;

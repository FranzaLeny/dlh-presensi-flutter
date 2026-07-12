import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../data/local/settings_dao.dart';
import '../../data/models/pengaturan_presensi.dart';
import '../../data/remote/api_client.dart';
import '../auth_service.dart';
import '../time_service.dart';

/// Sinkronisasi pengaturan presensi dari server ke SQLite lokal
Future<void> syncSettings({String? skpdId}) async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    var resolvedSkpdId = skpdId;

    // Jika skpdId tidak ditentukan, coba ambil dari data pegawai
    if (resolvedSkpdId == null) {
      final pegawai = await AuthService.getPegawai();
      resolvedSkpdId = pegawai?.skpdId;
    }

    if (resolvedSkpdId == null) return;

    final response = await apiClient.get(
      '/umum/presensi/pengaturan/skpd',
      queryParameters: {'skpdId': resolvedSkpdId},
    );

    final data = response.data;
    if (data != null) {
      final pengaturan = PengaturanPresensi.fromJson(data);
      await SettingsDao.save(pengaturan);
      await TimeService.syncTime();
    }
  } catch (err, stack) {
    debugPrint('Error in syncSettings: $err');
    debugPrint(stack.toString());
  }
}

/// Alias ke syncSettings agar konsisten namanya
Future<void> syncPengaturan({String? skpdId}) => syncSettings(skpdId: skpdId);

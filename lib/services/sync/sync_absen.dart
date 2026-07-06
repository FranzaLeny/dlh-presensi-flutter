import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../data/local/absen_dao.dart';
import '../../data/models/presensi_absen.dart';
import '../../data/remote/api_client.dart';

/// Sinkronisasi data absen pegawai dari server ke SQLite lokal
Future<void> syncAbsenPegawai() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    final response = await apiClient.get('/umum/presensi/absen/pegawai');
    final data = response.data;
    if (data != null && data['items'] is List) {
      final List<dynamic> items = data['items'];
      final list = items.map((item) => PresensiAbsen.fromJson(item)).toList();
      
      await AbsenDao.clear();
      await AbsenDao.upsertAll(list);
    }
  } catch (err) {
    debugPrint('Gagal sync absen pegawai: $err');
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../data/local/hari_libur_dao.dart';
import '../../data/models/hari_libur.dart';
import '../../data/remote/api_client.dart';

/// Sinkronisasi data hari libur dari server ke SQLite lokal
Future<void> syncHariLibur() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    final response = await apiClient.get('/umum/presensi/hari-libur');
    final data = response.data;
    if (data != null && data['items'] is List) {
      final List<dynamic> items = data['items'];
      final list = items.map((item) => HariLibur.fromJson(item)).toList();
      await HariLiburDao.replaceBulk(list);
    }
  } catch (err) {
    debugPrint('Gagal sync hari libur: $err');
  }
}

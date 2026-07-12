// ====================================
// Absen Service — API Operations for Absen
// ====================================

import 'dart:io';

import '../data/models/presensi_absen.dart';
import '../data/remote/api_client.dart';
import 'storage_service.dart';

class AbsenService {
  AbsenService._();

  /// Upload dokumen lampiran via presigned POST URL (cara baru).
  static Future<String> uploadDokumen(
    String localPath,
    String tipePresensi, // 'absen'
    String tanggal, // YYYY-MM-DD
    String contentType, // e.g. 'image/jpeg', 'application/pdf'
  ) async {
    final file = File(localPath);

    // Validasi: cek file size sebelum upload
    final fileSize = await file.length();
    if (fileSize > 2 * 1024 * 1024) {
      throw Exception('Ukuran file melebihi batas maksimum 2 MB.');
    }

    final key = await StorageService.uploadToStorage(
      entity: 'presensi',
      file: file,
      contentType: contentType,
      tanggal: tanggal,
      tipePresensi: tipePresensi,
    );

    return key; // Return key (bukan publicUrl)
  }

  /// Mengajukan absen baru (POST /umum/presensi/absen)
  static Future<void> createAbsen({
    required String pegawaiId,
    required List<String> tanggal,
    required String tipe,
    String? keterangan,
    String? dokumenUrl,
  }) async {
    await apiClient.post(
      '/umum/presensi/absen',
      data: {
        'pegawaiId': pegawaiId,
        'tanggal': tanggal,
        'tipe': tipe,
        'keterangan': keterangan,
        'dokumenUrl': dokumenUrl,
      },
    );
  }

  /// Update absen — jika status PENDING/REJECTED (PATCH /umum/presensi/absen/:id)
  static Future<void> updateAbsen(
    String id, {
    List<String>? tanggal,
    String? tipe,
    String? keterangan,
    String? dokumenUrl,
  }) async {
    await apiClient.patch(
      '/umum/presensi/absen/$id',
      data: {
        'tanggal': ?tanggal,
        'tipe': ?tipe,
        'keterangan': ?keterangan,
        'dokumenUrl': ?dokumenUrl,
      },
    );
  }

  /// Ambil daftar absen milik sendiri (GET /umum/presensi/absen)
  /// Tapi API backend yang didefinisikan user:
  /// GET /umum/presensi/absen/pegawai?bulan=X&tahun=Y
  static Future<List<PresensiAbsen>> getMyAbsenList({
    int? bulan,
    int? tahun,
  }) async {
    final response = await apiClient.get(
      '/umum/presensi/absen/pegawai',
      queryParameters: {'bulan': ?bulan, 'tahun': ?tahun},
    );

    final data = response.data;
    if (data != null && data['items'] is List) {
      final List<dynamic> items = data['items'];
      return items.map((item) => PresensiAbsen.fromJson(item)).toList();
    }
    return [];
  }
}

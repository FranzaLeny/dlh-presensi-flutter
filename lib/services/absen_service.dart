// ====================================
// Absen Service — API Operations for Absen
// ====================================

import 'dart:io';

import 'package:dio/dio.dart';

import '../data/models/presensi_absen.dart';
import '../data/remote/api_client.dart';

class AbsenService {
  AbsenService._();

  /// Upload dokumen lampiran via presigned URL
  static Future<String> uploadDokumen(
    String localPath,
    String tipePresensi, // 'absen'
    String tanggal, // YYYY-MM-DD
    String contentType, // e.g. 'image/jpeg', 'application/pdf'
  ) async {
    // 1. Minta presigned URL dari backend
    final response = await apiClient.post(
      '/umum/presensi/presigned-url',
      data: {
        'contentType': contentType,
        'tipePresensi': tipePresensi,
        'tanggal': tanggal,
      },
    );

    final data = response.data;
    final uploadUrl = data['uploadUrl'] as String;
    final publicUrl = data['publicUrl'] as String;

    // 2. Upload langsung ke Cloud Storage
    final file = File(localPath);
    final bytes = await file.readAsBytes();

    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable(bytes.map((e) => [e])),
      options: Options(
        headers: {'Content-Type': contentType, 'Content-Length': bytes.length},
      ),
    );

    return publicUrl;
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

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/local/presensi_dao.dart';
import '../../data/models/presensi_log.dart';
import '../storage_service.dart';

/// Upload foto yang pending untuk sebuah log
Future<void> uploadPendingPhotos(PresensiLog log) async {
  if (log.fotoPath != null && log.fotoUrl == null) {
    try {
      final url = await uploadFoto(
        log.fotoPath!,
        log.tipe.toDbString(),
        log.tanggal,
      );
      await PresensiDao.updateFotoUrl(log.id, url);
    } catch (e) {
      debugPrint('Error uploading photo for log ${log.id}: $e');
      rethrow;
    }
  }
}

/// Upload foto ke Cloud Storage via presigned URL
Future<String> uploadFoto(
  String localPath,
  String tipe,
  String tanggal,
) async {
  final file = File(localPath);
  final fileSize = await file.length();
  if (fileSize > 2 * 1024 * 1024) {
    throw Exception('Ukuran file melebihi batas maksimum 2 MB.');
  }

  final key = await StorageService.uploadToStorage(
    entity: 'presensi',
    file: file,
    contentType: 'image/jpeg',
    tanggal: tanggal,
    tipePresensi: tipe,
  );

  // Hapus file lokal karena sudah tidak dibutuhkan setelah upload (sesuai req: di lokal tidak perlu menyimpan file image yang sudah tersingron)
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}

  return key; // Return key, bukan publicUrl
}

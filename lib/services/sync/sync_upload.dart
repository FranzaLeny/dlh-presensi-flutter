import 'dart:io';
import 'package:dio/dio.dart';
import '../../data/local/presensi_dao.dart';
import '../../data/models/presensi_log.dart';
import '../../data/models/sync_response.dart';
import '../../data/remote/api_client.dart';

/// Upload foto yang pending untuk sebuah log
Future<void> uploadPendingPhotos(PresensiLog log) async {
  if (log.isLuarRadius > 0 && log.fotoPath != null && log.fotoUrl == null) {
    final url = await uploadFoto(
      log.fotoPath!,
      log.tipe.toDbString(),
      log.tanggal,
    );
    await PresensiDao.updateFotoUrl(log.id, url);
  }
}

/// Upload foto ke Cloud Storage via presigned URL
Future<String> uploadFoto(
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

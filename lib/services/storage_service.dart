import 'dart:io';

import 'package:dio/dio.dart';

import '../data/models/presigned_post_response.dart';
import '../data/remote/api_client.dart';

class StorageService {
  StorageService._();

  /// Minta presigned POST URL dari backend.
  /// [entity] bisa "presensi" atau "profile".
  static Future<PresignedPostResponse> getPresignedUrl({
    required String entity,
    required String contentType,
    required int fileSize,
    String? tanggal,
    String? tipePresensi,
  }) async {
    final response = await apiClient.post(
      '/storage/$entity/presigned',
      data: () {
        final map = <String, dynamic>{
          'contentType': contentType,
          'fileSize': fileSize,
        };
        if (tanggal != null) map['tanggal'] = tanggal;
        if (tipePresensi != null) map['tipePresensi'] = tipePresensi;
        return map;
      }(),
    );
    final Map<String, dynamic> body = response.data;
    final payload = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return PresignedPostResponse.fromJson(payload);
  }

  /// Upload file ke S3/R2 menggunakan presigned PUT.
  /// WAJIB menggunakan Dio instance terpisah tanpa auth interceptor.
  static Future<void> uploadFile({
    required PresignedPostResponse presigned,
    required File file,
    required String contentType,
  }) async {
    final uploadDio = Dio();
    
    final fileSize = await file.length();

    final response = await uploadDio.put(
      presigned.uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          Headers.contentLengthHeader: fileSize,
          Headers.contentTypeHeader: contentType,
        },
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Upload gagal: ${response.statusCode}');
    }
  }

  /// Upload file lengkap: request presigned + upload ke S3.
  /// Return: key dari file yang diupload.
  static Future<String> uploadToStorage({
    required String entity,
    required File file,
    required String contentType,
    String? tanggal,
    String? tipePresensi,
  }) async {
    final fileSize = await file.length();

    final presigned = await getPresignedUrl(
      entity: entity,
      contentType: contentType,
      fileSize: fileSize,
      tanggal: tanggal,
      tipePresensi: tipePresensi,
    );

    await uploadFile(
      presigned: presigned,
      file: file,
      contentType: contentType,
    );

    // Return key, bukan publicUrl
    return presigned.key;
  }

  /// Upload foto profil dan return key-nya (karena yang disimpan di database / session adalah key).
  static Future<String> uploadProfilePhoto(File file) async {
    final fileSize = await file.length();
    
    if (fileSize > 2 * 1024 * 1024) {
      throw Exception('Ukuran foto maksimal 2 MB');
    }

    final presigned = await getPresignedUrl(
      entity: 'profile',
      contentType: 'image/jpeg',
      fileSize: fileSize,
    );

    await uploadFile(
      presigned: presigned,
      file: file,
      contentType: 'image/jpeg',
    );

    return presigned.key;
  }

  /// Hapus file dari storage.
  /// Pegawai hanya bisa hapus file miliknya sendiri.
  static Future<void> deleteFile({
    required String entity,
    required String key,
  }) async {
    await apiClient.delete('/storage/$entity', data: {'key': key});
  }

  /// Preview: dapatkan public URL untuk file.
  static Future<String> getPreviewUrl({
    required String entity,
    required String key,
  }) async {
    final response = await apiClient.get(
      '/storage/$entity/preview',
      queryParameters: {'key': key},
    );
    final Map<String, dynamic> body = response.data;
    final payload = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return (payload['publicUrl'] ?? payload['url']) as String;
  }

  /// Cek apakah file ada di storage.
  static Future<bool> fileExists({
    required String entity,
    required String key,
  }) async {
    final response = await apiClient.get(
      '/storage/$entity/exists',
      queryParameters: {'key': key},
    );
    final Map<String, dynamic> body = response.data;
    final payload = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return payload['exists'] as bool;
  }
}

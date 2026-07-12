// ====================================
// Camera Service — Selfie Capture
// ====================================

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const _selfieDirName = 'selfies';

class CameraService {
  CameraService._();

  /// Mendapatkan atau membuat direktori selfie
  static Future<Directory> _getSelfieDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final selfieDir = Directory(p.join(appDir.path, _selfieDirName));
    if (!selfieDir.existsSync()) {
      await selfieDir.create(recursive: true);
    }
    return selfieDir;
  }

  /// Simpan foto selfie ke filesystem lokal
  /// [sourcePath] — path sementara dari kamera
  /// [jenis] — 'masuk', 'pulang', 'mulai-istirahat', 'selesai-istirahat'
  /// Returns path file lokal yang tersimpan
  static Future<String> saveSelfie(String sourcePath, String jenis) async {
    final dir = await _getSelfieDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'selfie_${jenis}_$timestamp.jpg';
    final destPath = p.join(dir.path, filename);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    
    // Hapus file sementara (temp file) dari image_picker
    if (await sourceFile.exists()) {
      await sourceFile.delete();
    }

    return destPath;
  }

  /// Hapus foto dari filesystem lokal (setelah berhasil sync)
  static Future<void> deleteFoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore delete errors
    }
  }

  /// Bersihkan semua selfie lama (opsional cleanup)
  static Future<void> cleanupOldSelfies({
    Duration maxAge = const Duration(days: 7),
  }) async {
    try {
      final dir = await _getSelfieDirectory();
      if (!dir.existsSync()) return;

      final now = DateTime.now();
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > maxAge) {
            await entity.delete();
          }
        }
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }
}

// ====================================
// Camera Service — Selfie Capture & Watermark
// ====================================

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

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

  /// Menambahkan watermark ke file gambar (berjalan di background isolate agar UI tidak lag)
  static Future<void> addWatermarkToSelfie(
    String photoPath, 
    double lat, 
    double lon, 
    DateTime timestamp
  ) async {
    // Jalankan komputasi gambar berat di Isolate menggunakan compute()
    await compute(_processWatermark, {
      'path': photoPath,
      'lat': lat,
      'lon': lon,
      'timestamp': timestamp,
    });
  }

  // Fungsi statis murni untuk dijalankan di Isolate
  static void _processWatermark(Map<String, dynamic> data) {
    final String photoPath = data['path'];
    final double lat = data['lat'];
    final double lon = data['lon'];
    final DateTime timestamp = data['timestamp'];

    final file = File(photoPath);
    if (!file.existsSync()) return;

    final bytes = file.readAsBytesSync();
    final img.Image? image = img.decodeImage(bytes);
    if (image == null) return;

    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm:ss');
    final dateStr = dateFormatter.format(timestamp);
    final locationStr = 'Lat: $lat, Lon: $lon';

    // Draw background rectangle at the bottom
    final padding = 20;
    final textHeight = 60; // Approximate height for two lines of text
    final bgY1 = image.height - textHeight - (padding * 2);
    final bgY2 = image.height;
    
    // Draw semi-transparent black background
    img.fillRect(
      image,
      x1: 0,
      y1: bgY1,
      x2: image.width,
      y2: bgY2,
      color: img.ColorRgba8(0, 0, 0, 150), // Semi-transparent black
    );

    // Draw text
    final textX = 20;
    final textY1 = bgY1 + padding;
    final textY2 = textY1 + 30; // 30px spacing

    img.drawString(
      image,
      dateStr,
      font: img.arial24,
      x: textX,
      y: textY1,
      color: img.ColorRgb8(255, 255, 255), // White
    );
    
    img.drawString(
      image,
      locationStr,
      font: img.arial24,
      x: textX,
      y: textY2,
      color: img.ColorRgb8(255, 255, 255), // White
    );

    // Encode and overwrite the file
    final encoded = img.encodeJpg(image, quality: 85);
    file.writeAsBytesSync(encoded);
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

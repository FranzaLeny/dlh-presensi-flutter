// ====================================
// Presensi DAO — CRUD presensi_log
// ====================================

import 'package:sqflite/sqflite.dart';

import '../models/presensi_log.dart';
import 'database.dart';

class PresensiDao {
  /// Insert log presensi baru (default is_synced = 0 dari database / model jika tidak di-override)
  static Future<void> create(PresensiLog log) async {
    final db = await getDatabase();
    await db.insert(
      'presensi_log', 
      log.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update log presensi yang sudah ada
  static Future<void> update(PresensiLog log) async {
    final db = await getDatabase();
    final row = log.toRow();
    row.remove('id');

    await db.update(
      'presensi_log',
      row,
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Ambil semua log presensi berdasarkan pegawai dan tanggal
  static Future<List<PresensiLog>> getByDate(
    String pegawaiId,
    String tanggal,
  ) async {
    final db = await getDatabase();
    
    final rows = await db.query(
      'presensi_log',
      where: 'pegawai_id = ? AND tanggal = ?',
      whereArgs: [pegawaiId, tanggal],
      orderBy: 'waktu DESC',
    );
    
    return rows.map(PresensiLog.fromRow).toList();
  }

  /// Ambil semua log yang belum di-sync
  static Future<List<PresensiLog>> getUnsynced() async {
    final db = await getDatabase();
    final rows = await db.query(
      'presensi_log',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'tanggal DESC, waktu DESC',
    );
    return rows.map(PresensiLog.fromRow).toList();
  }

  /// Tandai log sebagai sudah di-sync
  static Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await getDatabase();
    final placeholders = ids.map((_) => '?').join(', ');

    await db.update(
      'presensi_log',
      {'is_synced': 1},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Update URL foto setelah upload ke cloud
  static Future<void> updateFotoUrl(String id, String url) async {
    final db = await getDatabase();
    await db.update(
      'presensi_log',
      {'foto_url': url},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update status hasil sinkronisasi dari server
  static Future<void> updateSyncStatus(
    String id,
    int status,
    int isLuarRadius,
    String? keterangan,
  ) async {
    final db = await getDatabase();
    await db.update(
      'presensi_log',
      {
        'status': status,
        'is_luar_radius': isLuarRadius,
        'keterangan': keterangan,
        'is_synced': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ambil semua riwayat presensi dari history
  static Future<List<PresensiLog>> getAll({int limit = 50}) async {
    final db = await getDatabase();
    final rows = await db.query(
      'presensi_log',
      orderBy: 'tanggal DESC, waktu DESC',
      limit: limit,
    );
    return rows.map(PresensiLog.fromRow).toList();
  }

  /// Ambil riwayat presensi berdasarkan bulan
  static Future<List<PresensiLog>> getByMonth(
    String pegawaiId,
    int year,
    int month,
  ) async {
    final db = await getDatabase();
    final monthStr = month.toString().padLeft(2, '0');
    final pattern = '$year-$monthStr%';

    final rows = await db.query(
      'presensi_log',
      where: 'pegawai_id = ? AND tanggal LIKE ?',
      whereArgs: [pegawaiId, pattern],
      orderBy: 'tanggal DESC, waktu DESC',
    );

    return rows.map(PresensiLog.fromRow).toList();
  }

  /// Menyimpan data history yang diambil dari backend (upsert)
  static Future<void> upsertHistory(List<PresensiLog> logs) async {
    if (logs.isEmpty) return;
    final db = await getDatabase();
    for (final log in logs) {
      final row = log.toRow();
      row['is_synced'] = 1;
      await db.insert(
        'presensi_log',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Menghapus riwayat lokal dan memasukkan data rekap baru (Pull Sync)
  static Future<void> replaceHistoryByMonth(
    String pegawaiId,
    int year,
    int month,
    List<PresensiLog> logs,
  ) async {
    final db = await getDatabase();
    final monthStr = month.toString().padLeft(2, '0');
    final pattern = '$year-$monthStr%';

    // Hapus SEMUA log yang SUDAH SYNC di bulan ini
    // Log yang belum di-sync (is_synced = 0) biarkan saja agar tidak hilang
    await db.delete(
      'presensi_log',
      where: 'pegawai_id = ? AND tanggal LIKE ? AND is_synced = ?',
      whereArgs: [pegawaiId, pattern, 1],
    );

    if (logs.isEmpty) return;
    for (final log in logs) {
      final row = log.toRow();
      row['is_synced'] = 1; // Data dari server pasti valid (is_synced = 1)
      await db.insert(
        'presensi_log',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace, // Overwrite pending log jika ID sama
      );
    }
  }

  /// Hitung jumlah log yang belum di-sync
  static Future<int> countUnsynced() async {
    final db = await getDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM presensi_log WHERE is_synced = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Hapus log presensi berdasarkan ID
  static Future<void> delete(String id) async {
    final db = await getDatabase();
    await db.delete('presensi_log', where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus seluruh log presensi
  static Future<void> clear() async {
    final db = await getDatabase();
    await db.delete('presensi_log');
  }
}

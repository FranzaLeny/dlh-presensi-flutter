// ====================================
// Presensi DAO — CRUD presensi_log & presensi_log_pending
// ====================================

import 'package:sqflite/sqflite.dart';

import '../models/presensi_log.dart';
import 'database.dart';

class PresensiDao {
  /// Insert log presensi baru ke tabel pending
  static Future<void> create(PresensiLog log) async {
    final db = await getDatabase();
    await db.insert('presensi_log_pending', log.toRow());
  }

  /// Update log presensi yang sudah ada di kedua tabel
  static Future<void> update(PresensiLog log) async {
    final db = await getDatabase();
    final row = log.toRow();
    row.remove('id');

    await db.update(
      'presensi_log_pending',
      row,
      where: 'id = ?',
      whereArgs: [log.id],
    );
    await db.update(
      'presensi_log',
      row,
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Ambil semua log presensi berdasarkan pegawai dan tanggal dari kedua tabel
  static Future<List<PresensiLog>> getByDate(
    String pegawaiId,
    String tanggal,
  ) async {
    final db = await getDatabase();
    final map = <String, PresensiLog>{};

    // Ambil dari pending
    final rowsPending = await db.query(
      'presensi_log_pending',
      where: 'pegawai_id = ? AND tanggal = ?',
      whereArgs: [pegawaiId, tanggal],
    );
    for (final row in rowsPending) {
      final log = PresensiLog.fromRow(row);
      map[log.tipe.toDbString()] = log;
    }

    // Ambil dari history (overrides pending if overlap)
    final rowsHistory = await db.query(
      'presensi_log',
      where: 'pegawai_id = ? AND tanggal = ?',
      whereArgs: [pegawaiId, tanggal],
    );
    for (final row in rowsHistory) {
      final log = PresensiLog.fromRow(row);
      map[log.tipe.toDbString()] = log;
    }

    return map.values.toList();
  }

  /// Ambil semua log yang belum di-sync
  static Future<List<PresensiLog>> getUnsynced() async {
    final db = await getDatabase();
    final rows = await db.query(
      'presensi_log_pending',
      orderBy: 'tanggal DESC, waktu DESC',
    );
    return rows.map(PresensiLog.fromRow).toList();
  }

  /// Tandai log sebagai sudah di-sync: pindahkan dari pending ke history
  static Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await getDatabase();
    final placeholders = ids.map((_) => '?').join(', ');

    final rows = await db.query(
      'presensi_log_pending',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    for (final row in rows) {
      final updatedRow = Map<String, dynamic>.from(row);
      updatedRow['is_synced'] = 1;

      await db.insert(
        'presensi_log',
        updatedRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await db.delete(
      'presensi_log_pending',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Update URL foto setelah upload ke cloud
  static Future<void> updateFotoUrl(String id, String url) async {
    final db = await getDatabase();
    await db.update(
      'presensi_log_pending',
      {'foto_url': url},
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.update(
      'presensi_log',
      {'foto_url': url},
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

  /// Ambil riwayat presensi berdasarkan bulan dari kedua tabel
  static Future<List<PresensiLog>> getByMonth(
    String pegawaiId,
    int year,
    int month,
  ) async {
    final db = await getDatabase();
    final monthStr = month.toString().padLeft(2, '0');
    final pattern = '$year-$monthStr%';

    final rowsPending = await db.query(
      'presensi_log_pending',
      where: 'pegawai_id = ? AND tanggal LIKE ?',
      whereArgs: [pegawaiId, pattern],
      orderBy: 'tanggal DESC, waktu DESC',
    );

    final rowsHistory = await db.query(
      'presensi_log',
      where: 'pegawai_id = ? AND tanggal LIKE ?',
      whereArgs: [pegawaiId, pattern],
      orderBy: 'tanggal DESC, waktu DESC',
    );

    final map = <String, PresensiLog>{};
    for (final row in rowsHistory) {
      final log = PresensiLog.fromRow(row);
      map['${log.tanggal}_${log.tipe.toDbString()}'] = log;
    }
    for (final row in rowsPending) {
      final log = PresensiLog.fromRow(row);
      map['${log.tanggal}_${log.tipe.toDbString()}'] = log;
    }

    return map.values.toList();
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

  /// Menghapus riwayat lokal dan memasukkan data rekap baru
  static Future<void> replaceHistoryByMonth(
    String pegawaiId,
    int year,
    int month,
    List<PresensiLog> logs,
  ) async {
    final db = await getDatabase();
    final monthStr = month.toString().padLeft(2, '0');
    final pattern = '$year-$monthStr%';

    await db.delete(
      'presensi_log',
      where: 'pegawai_id = ? AND tanggal LIKE ?',
      whereArgs: [pegawaiId, pattern],
    );

    if (logs.isEmpty) return;
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

  /// Hitung jumlah log yang belum di-sync
  static Future<int> countUnsynced() async {
    final db = await getDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM presensi_log_pending',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Hapus log presensi berdasarkan ID dari kedua tabel
  static Future<void> delete(String id) async {
    final db = await getDatabase();
    await db.delete('presensi_log_pending', where: 'id = ?', whereArgs: [id]);
    await db.delete('presensi_log', where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus seluruh log presensi
  static Future<void> clear() async {
    final db = await getDatabase();
    await db.delete('presensi_log_pending');
    await db.delete('presensi_log');
  }
}

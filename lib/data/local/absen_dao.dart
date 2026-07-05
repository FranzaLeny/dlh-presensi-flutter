// ====================================
// Absen DAO — CRUD presensi_absen
// ====================================

import 'package:sqflite/sqflite.dart';
import '../models/presensi_absen.dart';
import 'database.dart';

class AbsenDao {
  /// Menyimpan/update data absen (upsert)
  static Future<void> upsertAll(List<PresensiAbsen> items) async {
    if (items.isEmpty) return;
    final db = await getDatabase();
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'presensi_absen',
        item.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Ambil absen berdasarkan bulan dan tahun
  static Future<List<PresensiAbsen>> getByMonth(int year, int month) async {
    final db = await getDatabase();
    final monthStr = month.toString().padLeft(2, '0');
    final pattern = '$year-$monthStr%';

    final rows = await db.query(
      'presensi_absen',
      where: 'tanggal LIKE ?',
      whereArgs: [pattern],
      orderBy: 'tanggal DESC',
    );

    return rows.map(PresensiAbsen.fromRow).toList();
  }

  /// Ambil semua pengajuan absen
  static Future<List<PresensiAbsen>> getAll() async {
    final db = await getDatabase();
    final rows = await db.query(
      'presensi_absen',
      orderBy: 'tanggal DESC',
    );
    return rows.map(PresensiAbsen.fromRow).toList();
  }

  /// Ambil absen berdasarkan tanggal tertentu
  static Future<List<PresensiAbsen>> getByDate(String tanggal) async {
    final db = await getDatabase();
    final rows = await db.query(
      'presensi_absen',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
    );
    return rows.map(PresensiAbsen.fromRow).toList();
  }

  /// Sinkronisasi dengan menimpa data bulanan
  static Future<void> replaceByMonth(int year, int month, List<PresensiAbsen> items) async {
    final db = await getDatabase();
    final monthStr = month.toString().padLeft(2, '0');
    final pattern = '$year-$monthStr%';

    await db.delete(
      'presensi_absen',
      where: 'tanggal LIKE ?',
      whereArgs: [pattern],
    );

    await upsertAll(items);
  }

  /// Hapus semua data absen
  static Future<void> clear() async {
    final db = await getDatabase();
    await db.delete('presensi_absen');
  }
}

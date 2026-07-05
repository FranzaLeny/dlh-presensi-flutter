// ====================================
// HariLibur DAO — CRUD hari_libur
// ====================================

import 'package:sqflite/sqflite.dart';
import '../models/hari_libur.dart';
import 'database.dart';

class HariLiburDao {
  /// Menyimpan/update data hari libur (upsert)
  static Future<void> upsertAll(List<HariLibur> items) async {
    if (items.isEmpty) return;
    final db = await getDatabase();
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'hari_libur',
        item.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Ambil hari libur berdasarkan bulan dan tahun
  static Future<List<HariLibur>> getByMonth(int year, int month) async {
    final db = await getDatabase();
    final monthStr = month.toString().padLeft(2, '0');
    final pattern = '$year-$monthStr%';

    final rows = await db.query(
      'hari_libur',
      where: 'tanggal LIKE ?',
      whereArgs: [pattern],
      orderBy: 'tanggal ASC',
    );

    return rows.map(HariLibur.fromRow).toList();
  }

  /// Ambil hari libur berdasarkan tanggal tertentu
  static Future<HariLibur?> getByDate(String tanggal) async {
    final db = await getDatabase();
    final rows = await db.query(
      'hari_libur',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HariLibur.fromRow(rows.first);
  }

  /// Hapus semua hari libur
  static Future<void> clear() async {
    final db = await getDatabase();
    await db.delete('hari_libur');
  }
}

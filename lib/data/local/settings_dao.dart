// ====================================
// Settings DAO — CRUD pengaturan_presensi
// ====================================

import 'package:sqflite/sqflite.dart';

import '../models/pengaturan_presensi.dart';
import 'database.dart';

class SettingsDao {
  /// Simpan atau update pengaturan presensi (upsert)
  static Future<void> save(PengaturanPresensi pengaturan) async {
    final db = await getDatabase();
    await db.insert(
      'pengaturan_presensi',
      pengaturan.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil pengaturan berdasarkan SKPD ID
  static Future<PengaturanPresensi?> getBySkpdId(String skpdId) async {
    final db = await getDatabase();
    final rows = await db.query(
      'pengaturan_presensi',
      where: 'skpd_id = ?',
      whereArgs: [skpdId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PengaturanPresensi.fromRow(rows.first);
  }

  /// Ambil pengaturan pertama yang tersedia (fallback)
  static Future<PengaturanPresensi?> getFirst() async {
    final db = await getDatabase();
    final rows = await db.query(
      'pengaturan_presensi',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PengaturanPresensi.fromRow(rows.first);
  }

  /// Hapus semua pengaturan
  static Future<void> clear() async {
    final db = await getDatabase();
    await db.delete('pengaturan_presensi');
  }
}

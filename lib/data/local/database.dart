// ====================================
// SQLite Database Service
// ====================================

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String _dbName = 'presensi.db';
const int _dbVersion = 1;

Database? _db;

/// Mendapatkan instance database (singleton)
Future<Database> getDatabase() async {
  if (_db != null) return _db!;
  _db = await _initDatabase();
  return _db!;
}

Future<Database> _initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, _dbName);

  return openDatabase(
    path,
    version: _dbVersion,
    onCreate: _onCreate,
    onConfigure: (db) async {
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA foreign_keys = ON');
    },
  );
}

/// Membuat semua tabel dan index yang diperlukan
Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS pengaturan_presensi (
      id TEXT PRIMARY KEY,
      skpd_id TEXT NOT NULL UNIQUE,
      nama_kantor TEXT,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      radius INTEGER NOT NULL DEFAULT 100,
      jam_masuk_mulai TEXT NOT NULL DEFAULT '07:30:00',
      jam_masuk_selesai TEXT NOT NULL DEFAULT '08:30:00',
      jam_istirahat_mulai TEXT NOT NULL DEFAULT '12:00:00',
      jam_istirahat_selesai TEXT NOT NULL DEFAULT '13:00:00',
      jam_pulang_mulai TEXT NOT NULL DEFAULT '16:00:00',
      jam_pulang_selesai TEXT NOT NULL DEFAULT '17:00:00',
      updated_at TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS presensi_log (
      id TEXT PRIMARY KEY,
      pegawai_id TEXT NOT NULL,
      pengaturan_id TEXT NOT NULL,
      tanggal TEXT NOT NULL,
      tipe TEXT NOT NULL,
      waktu TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      foto_path TEXT,
      foto_url TEXT,
      is_luar_radius INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'HADIR',
      keterangan TEXT,
      device_id TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      nama_verifikator TEXT
    )
  ''');

  await db.execute('''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_presensi_log_tgl_tipe
      ON presensi_log (pegawai_id, tanggal, tipe)
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS presensi_log_pending (
      id TEXT PRIMARY KEY,
      pegawai_id TEXT NOT NULL,
      pengaturan_id TEXT NOT NULL,
      tanggal TEXT NOT NULL,
      tipe TEXT NOT NULL,
      waktu TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      foto_path TEXT,
      foto_url TEXT,
      is_luar_radius INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'HADIR',
      keterangan TEXT,
      device_id TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      nama_verifikator TEXT
    )
  ''');

  await db.execute('''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_presensi_log_pending_tgl_tipe
      ON presensi_log_pending (pegawai_id, tanggal, tipe)
  ''');
}

/// Inisialisasi database — dipanggil sekali saat app mount
Future<void> initDatabase() async {
  await getDatabase();
}

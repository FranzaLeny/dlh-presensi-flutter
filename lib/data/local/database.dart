// ====================================
// SQLite Database Service
// ====================================

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String _dbName = 'presensi.db';
const int _dbVersion = 1;

Database? _db;
Completer<Database>? _dbCompleter;

/// Mendapatkan instance database (singleton)
Future<Database> getDatabase() async {
  if (_db != null) return _db!;
  if (_dbCompleter != null) return _dbCompleter!.future;
  
  _dbCompleter = Completer<Database>();
  try {
    _db = await _initDatabase();
    _dbCompleter!.complete(_db!);
  } catch (e) {
    _dbCompleter!.completeError(e);
    _dbCompleter = null;
    rethrow;
  }
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
      // PRAGMA journal_mode mengembalikan baris hasil sehingga harus memakai rawQuery
      await db.rawQuery('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA foreign_keys = ON');
    },
  );
}

/// Membuat semua tabel dan index yang diperlukan
Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS pengaturan_presensi (
      id TEXT PRIMARY KEY,
      skpd_id TEXT NOT NULL,
      nama_kantor TEXT,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      radius INTEGER NOT NULL DEFAULT 100,
      jam_masuk TEXT NOT NULL DEFAULT '08:00:00',
      jam_istirahat_mulai TEXT NOT NULL DEFAULT '12:00:00',
      jam_istirahat_selesai TEXT NOT NULL DEFAULT '13:00:00',
      jam_pulang TEXT NOT NULL DEFAULT '16:00:00',
      tanggal_mulai TEXT,
      tanggal_berakhir TEXT,
      status INTEGER NOT NULL DEFAULT 10,
      updated_at TEXT,
      jadwal_harian_json TEXT
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
      status INTEGER NOT NULL DEFAULT 2,
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
    CREATE TABLE IF NOT EXISTS hari_libur (
      id TEXT NOT NULL,
      tanggal TEXT NOT NULL,
      nama TEXT NOT NULL,
      tipe TEXT NOT NULL,
      keterangan TEXT,
      dokumen_url TEXT,
      created_at TEXT,
      updated_at TEXT,
      PRIMARY KEY (id, tanggal)
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS presensi_absen (
      id TEXT NOT NULL,
      skpd_id TEXT NOT NULL,
      pegawai_id TEXT NOT NULL,
      tanggal TEXT NOT NULL,
      tipe TEXT NOT NULL,
      keterangan TEXT,
      dokumen_url TEXT,
      status INTEGER NOT NULL DEFAULT 2,
      created_at TEXT,
      updated_at TEXT,
      created_by TEXT,
      updated_by TEXT,
      PRIMARY KEY (id, tanggal)
    )
  ''');
}

/// Inisialisasi database — dipanggil sekali saat app mount
Future<void> initDatabase() async {
  await getDatabase();
}
